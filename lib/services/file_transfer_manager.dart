import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transfer_packet.dart';

class FileTransferManager {
  static const int chunkSize = 16384; // 16KB

  final ImagePicker _picker = ImagePicker();
  final Map<String, List<String?>> _incomingChunks = {};
  final Map<String, TransferPacket> _incomingMeta = {};

  /// Pick and send an image. Returns the transferId.
  Future<String?> sendImage({
    ImageSource source = ImageSource.gallery,
    required Function(String packet) sendPacket,
    required Function(String transferId, double progress) onProgress,
  }) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return null;

    final String transferId = const Uuid().v4();
    final File originalFile = File(image.path);
    
    // 1. Compression
    final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
      originalFile.absolute.path,
      minWidth: 1280,
      minHeight: 1280,
      quality: 70,
    );

    if (compressedBytes == null) return null;

    // 2. Hash for integrity
    final String hash = sha256.convert(compressedBytes).toString();
    final int totalChunks = (compressedBytes.length / chunkSize).ceil();

    // 3. Send Metadata
    final metaPacket = TransferPacket(
      type: PacketType.image_meta,
      transferId: transferId,
      fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      fileSize: compressedBytes.length,
      totalChunks: totalChunks,
      hash: hash,
    );
    sendPacket(metaPacket.encode());

    // 4. Send Chunks
    await _sendChunks(transferId, compressedBytes, sendPacket, onProgress, PacketType.image_chunk);

    return transferId;
  }

  /// Send a generic file.
  Future<String?> sendFile({
    required File file,
    required Function(String packet) sendPacket,
    required Function(String transferId, double progress) onProgress,
  }) async {
    final String transferId = const Uuid().v4();
    final Uint8List fileBytes = await file.readAsBytes();

    // 1. Hash for integrity
    final String hash = sha256.convert(fileBytes).toString();
    final int totalChunks = (fileBytes.length / chunkSize).ceil();

    // 2. Send Metadata
    final metaPacket = TransferPacket(
      type: PacketType.file_meta,
      transferId: transferId,
      fileName: file.path.split(Platform.pathSeparator).last,
      fileSize: fileBytes.length,
      totalChunks: totalChunks,
      hash: hash,
    );
    sendPacket(metaPacket.encode());

    // 3. Send Chunks
    await _sendChunks(transferId, fileBytes, sendPacket, onProgress, PacketType.file_chunk);

    return transferId;
  }

  Future<void> _sendChunks(
    String transferId,
    Uint8List bytes,
    Function(String packet) sendPacket,
    Function(String transferId, double progress) onProgress,
    PacketType chunkType,
  ) async {
    final int totalChunks = (bytes.length / chunkSize).ceil();
    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSize;
      final int end = (start + chunkSize < bytes.length)
          ? start + chunkSize
          : bytes.length;

      final chunkData = base64Encode(bytes.sublist(start, end));
      final chunkPacket = TransferPacket(
        type: chunkType,
        transferId: transferId,
        index: i,
        data: chunkData,
      );

      sendPacket(chunkPacket.encode());
      onProgress(transferId, (i + 1) / totalChunks);
      
      // Small delay to avoid flooding the data channel buffer
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  /// Handles an incoming packet from the data channel.
  /// Returns a File if the transfer is complete and verified.
  Future<File?> handleIncomingPacket(
    String rawPacket, {
    required Function(String transferId, double progress) onProgress,
  }) async {
    final Map<String, dynamic> json = jsonDecode(rawPacket);
    final packet = TransferPacket.fromJson(json);

    if (packet.type == PacketType.image_meta || packet.type == PacketType.file_meta) {
      _incomingMeta[packet.transferId] = packet;
      _incomingChunks[packet.transferId] = List<String?>.filled(packet.totalChunks!, null);
      return null;
    }

    if (packet.type == PacketType.image_chunk || packet.type == PacketType.file_chunk) {
      final id = packet.transferId;
      final meta = _incomingMeta[id];
      if (meta == null) return null;

      _incomingChunks[id]![packet.index!] = packet.data;

      // Update progress
      int receivedCount = _incomingChunks[id]!.where((c) => c != null).length;
      onProgress(id, receivedCount / meta.totalChunks!);

      // Check if complete
      if (receivedCount == meta.totalChunks) {
        return await _assembleFile(id);
      }
    }

    return null;
  }

  Future<File?> _assembleFile(String transferId) async {
    final meta = _incomingMeta[transferId]!;
    final chunks = _incomingChunks[transferId]!;

    try {
      final List<int> allBytes = [];
      for (final chunkB64 in chunks) {
        allBytes.addAll(base64Decode(chunkB64!));
      }

      final Uint8List bytes = Uint8List.fromList(allBytes);

      // Verify Integrity
      final String currentHash = sha256.convert(bytes).toString();
      if (currentHash != meta.hash) {
        print("Integrity Check Failed for $transferId");
        _cleanup(transferId);
        return null;
      }

      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/${meta.fileName}');
      await file.writeAsBytes(bytes);

      _cleanup(transferId);
      return file;
    } catch (e) {
      print("Error assembling file: $e");
      _cleanup(transferId);
      return null;
    }
  }

  void _cleanup(String transferId) {
    _incomingMeta.remove(transferId);
    _incomingChunks.remove(transferId);
  }
}
