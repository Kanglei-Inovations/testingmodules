import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transfer_packet.dart';

// Top-level function for background isolate hashing
Future<String> _calculateFileHash(String path) async {
  final file = File(path);
  final stream = file.openRead();
  final hash = await sha256.bind(stream).first;
  return hash.toString();
}

String _calculateBytesHashSync(Uint8List bytes) {
  return sha256.convert(bytes).toString();
}

class AssembleArgs {
  final List<String?> chunks;
  final String expectedHash;
  final String outputPath;

  AssembleArgs(this.chunks, this.expectedHash, this.outputPath);
}

// Top-level function for background isolate file assembly
Future<bool> _assembleAndVerifySync(AssembleArgs args) async {
  try {
    final file = File(args.outputPath);
    final sink = file.openWrite();
    
    for (final chunkB64 in args.chunks) {
      if (chunkB64 == null) continue;
      final bytes = base64Decode(chunkB64);
      sink.add(bytes);
    }
    
    await sink.flush();
    await sink.close();
    
    final finalHash = await _calculateFileHash(args.outputPath);
    
    if (finalHash != args.expectedHash) {
      if (file.existsSync()) file.deleteSync();
      return false;
    }
    return true;
  } catch (e) {
    return false;
  }
}

class FileTransferManager {
  static const int chunkSize = 16384; // 16KB

  final ImagePicker _picker = ImagePicker();
  final Map<String, List<String?>> _incomingChunks = {};
  final Map<String, TransferPacket> _incomingMeta = {};
  
  // Dynamic tuning state
  int _currentThrottleMs = 15;

  void _tuneThrottle(int totalChunks) {
    // Adaptive tuning: Larger files need slightly more throttle to prevent
    // the WebRTC underlying SCTP buffer from overflowing and dropping connection.
    if (totalChunks < 50) {
      _currentThrottleMs = 5; // Images / small files: blast it
    } else if (totalChunks < 500) {
      _currentThrottleMs = 15; // Medium files (~8MB)
    } else {
      _currentThrottleMs = 25; // Large files (Videos/PDFs > 8MB)
    }
  }

  /// Pick and send an image. Returns the transferId.
  Future<String?> sendImage({
    required String messageId,
    ImageSource source = ImageSource.gallery,
    required Function(String packet) sendPacket,
    required Function(String transferId, double progress, String? messageId) onProgress,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      final String transferId = const Uuid().v4();
      final File originalFile = File(image.path);
      
      // 1. Compression (Already asynchronous and native)
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        originalFile.absolute.path,
        minWidth: 1280,
        minHeight: 1280,
        quality: 70,
      );

      if (compressedBytes == null) return null;

      // 2. Hash for integrity (Background Isolate)
      final String hash = await compute(_calculateBytesHashSync, compressedBytes);
      final int totalChunks = (compressedBytes.length / chunkSize).ceil();

      // 3. Send Metadata
      final metaPacket = TransferPacket(
        type: PacketType.image_meta,
        transferId: transferId,
        messageId: messageId,
        fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileSize: compressedBytes.length,
        totalChunks: totalChunks,
        hash: hash,
      );
      sendPacket(metaPacket.encode());

      _tuneThrottle(totalChunks);

      // 4. Send Chunks from Memory (Images are small enough for RAM)
      await _sendBytes(transferId, messageId, compressedBytes, sendPacket, onProgress, PacketType.image_chunk);

      return transferId;
    } catch (e) {
      print("Error sending image: $e");
      return null;
    }
  }

  /// Send a generic file by streaming from disk to save RAM.
  Future<String?> sendFile({
    required String messageId,
    required File file,
    required Function(String packet) sendPacket,
    required Function(String transferId, double progress, String? messageId) onProgress,
  }) async {
    try {
      final String transferId = const Uuid().v4();
      final int fileSize = await file.length();

      // 1. Hash for integrity (Background Isolate via streaming)
      final String hash = await _calculateFileHash(file.path);
      final int totalChunks = (fileSize / chunkSize).ceil();

      // 2. Send Metadata
      final metaPacket = TransferPacket(
        type: PacketType.file_meta,
        transferId: transferId,
        messageId: messageId,
        fileName: file.path.split(Platform.pathSeparator).last,
        fileSize: fileSize,
        totalChunks: totalChunks,
        hash: hash,
      );
      sendPacket(metaPacket.encode());

      _tuneThrottle(totalChunks);

      // 3. Send Chunks via Disk Streaming
      await _streamFileChunks(transferId, messageId, file, totalChunks, sendPacket, onProgress, PacketType.file_chunk);

      return transferId;
    } catch (e) {
      print("Error sending file: $e");
      return null;
    }
  }

  Future<void> _sendBytes(
    String transferId,
    String messageId,
    Uint8List bytes,
    Function(String packet) sendPacket,
    Function(String transferId, double progress, String? messageId) onProgress,
    PacketType chunkType,
  ) async {
    final int totalChunks = (bytes.length / chunkSize).ceil();
    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSize;
      final int end = (start + chunkSize < bytes.length) ? start + chunkSize : bytes.length;

      final chunkData = base64Encode(bytes.sublist(start, end));
      final chunkPacket = TransferPacket(
        type: chunkType,
        transferId: transferId,
        index: i,
        data: chunkData,
      );

      sendPacket(chunkPacket.encode());
      onProgress(transferId, (i + 1) / totalChunks, messageId);
      
      // Auto-tuning throttle
      await Future.delayed(Duration(milliseconds: _currentThrottleMs));
    }
  }

  Future<void> _streamFileChunks(
    String transferId,
    String messageId,
    File file,
    int totalChunks,
    Function(String packet) sendPacket,
    Function(String transferId, double progress, String? messageId) onProgress,
    PacketType chunkType,
  ) async {
    final raf = await file.open(mode: FileMode.read);
    
    for (int i = 0; i < totalChunks; i++) {
      final bytes = await raf.read(chunkSize);
      final chunkData = base64Encode(bytes);
      
      final chunkPacket = TransferPacket(
        type: chunkType,
        transferId: transferId,
        index: i,
        data: chunkData,
      );

      sendPacket(chunkPacket.encode());
      onProgress(transferId, (i + 1) / totalChunks, messageId);
      
      // Auto-tuning throttle
      await Future.delayed(Duration(milliseconds: _currentThrottleMs));
    }
    
    await raf.close();
  }

  /// Handles an incoming packet from the data channel.
  Future<File?> handleIncomingPacket(
    String rawPacket, {
    required Function(String transferId, double progress, String? messageId) onProgress,
  }) async {
    final Map<String, dynamic> json = jsonDecode(rawPacket);
    final packet = TransferPacket.fromJson(json);

    if (packet.type == PacketType.image_meta || packet.type == PacketType.file_meta) {
      _incomingMeta[packet.transferId] = packet;
      _incomingChunks[packet.transferId] = List<String?>.filled(packet.totalChunks!, null);
      // Trigger progress 0 to create the placeholder
      onProgress(packet.transferId, 0, packet.messageId);
      return null;
    }

    if (packet.type == PacketType.image_chunk || packet.type == PacketType.file_chunk) {
      final id = packet.transferId;
      final meta = _incomingMeta[id];
      if (meta == null) return null;

      _incomingChunks[id]![packet.index!] = packet.data;

      // Update progress
      int receivedCount = _incomingChunks[id]!.where((c) => c != null).length;
      onProgress(id, receivedCount / meta.totalChunks!, meta.messageId);

      // Check if complete
      if (receivedCount == meta.totalChunks) {
        return await _assembleFile(id);
      }
    }

    return null;
  }

  TransferPacket? getMeta(String transferId) => _incomingMeta[transferId];

  Future<File?> _assembleFile(String transferId) async {
    final meta = _incomingMeta[transferId]!;
    final chunks = _incomingChunks[transferId]!;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final String outputPath = '${directory.path}/${meta.fileName}';
      
      // Offload Base64 decoding, binary assembly, and hashing to background isolate
      final args = AssembleArgs(chunks, meta.hash!, outputPath);
      final isValid = await compute(_assembleAndVerifySync, args);
      
      _cleanup(transferId);
      
      if (isValid) {
        return File(outputPath);
      } else {
        print("Integrity Check Failed for $transferId");
        return null;
      }
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
