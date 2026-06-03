import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

class FileTransferManager {
  // Adaptive Chunk Sizes
  static const int chunkPoor = 32768;      // 32KB
  static const int chunkNormal = 65536;    // 64KB
  static const int chunkFast = 131072;     // 128KB
  static const int chunkExcellent = 262144; // 256KB

  int _currentChunkSize = chunkNormal;

  final ImagePicker _picker = ImagePicker();
  
  // Storage for metadata and open file handles
  final Map<String, TransferPacket> _incomingMeta = {};
  final Map<String, RandomAccessFile> _activeFiles = {};
  final Map<String, Set<int>> _receivedIndices = {};
  
  // Dynamic tuning state
  int _currentThrottleMs = 10;

  void updateNetworkQuality(int latencyMs) {
    if (latencyMs < 100) {
      _currentChunkSize = chunkExcellent;
      _currentThrottleMs = 2;
    } else if (latencyMs < 250) {
      _currentChunkSize = chunkFast;
      _currentThrottleMs = 5;
    } else if (latencyMs < 500) {
      _currentChunkSize = chunkNormal;
      _currentThrottleMs = 15;
    } else {
      _currentChunkSize = chunkPoor;
      _currentThrottleMs = 30;
    }
  }

  /// Pick and send an image. Returns the transferId.
  Future<String?> sendImage({
    required String messageId,
    ImageSource source = ImageSource.gallery,
    required Function(dynamic packet, bool isBinary) sendPacket,
    required Function(String transferId, double progress, String? messageId) onProgress,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      final String transferId = const Uuid().v4();
      final File originalFile = File(image.path);
      
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        originalFile.absolute.path,
        minWidth: 1280,
        minHeight: 1280,
        quality: 70,
      );

      if (compressedBytes == null) return null;

      final String hash = await compute(_calculateBytesHashSync, compressedBytes);
      final int totalChunks = (compressedBytes.length / _currentChunkSize).ceil();

      final metaPacket = TransferPacket(
        type: PacketType.image_meta,
        transferId: transferId,
        messageId: messageId,
        fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileSize: compressedBytes.length,
        totalChunks: totalChunks,
        chunkSize: _currentChunkSize,
        hash: hash,
      );
      sendPacket(metaPacket.encode(), false);

      await _sendBytes(transferId, messageId, compressedBytes, sendPacket, onProgress, PacketType.image_chunk);

      return transferId;
    } catch (e) {
      print("Error sending image: $e");
      return null;
    }
  }

  /// Send a generic file by streaming from disk.
  Future<String?> sendFile({
    required String messageId,
    required File file,
    required Function(dynamic packet, bool isBinary) sendPacket,
    required Function(String transferId, double progress, String? messageId) onProgress,
  }) async {
    try {
      final String transferId = const Uuid().v4();
      final int fileSize = await file.length();
      final String hash = await _calculateFileHash(file.path);
      final int totalChunks = (fileSize / _currentChunkSize).ceil();

      final metaPacket = TransferPacket(
        type: PacketType.file_meta,
        transferId: transferId,
        messageId: messageId,
        fileName: file.path.split(Platform.pathSeparator).last,
        fileSize: fileSize,
        totalChunks: totalChunks,
        chunkSize: _currentChunkSize,
        hash: hash,
      );
      sendPacket(metaPacket.encode(), false);

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
    Function(dynamic packet, bool isBinary) sendPacket,
    Function(String transferId, double progress, String? messageId) onProgress,
    PacketType chunkType,
  ) async {
    final int totalChunks = (bytes.length / _currentChunkSize).ceil();
    for (int i = 0; i < totalChunks; i++) {
      final int start = i * _currentChunkSize;
      final int end = (start + _currentChunkSize < bytes.length) ? start + _currentChunkSize : bytes.length;

      final chunkPacket = TransferPacket(
        type: chunkType,
        transferId: transferId,
        index: i,
        binaryData: bytes.sublist(start, end),
      );

      bool sent = sendPacket(chunkPacket.encodeBinary(), true);
      
      // If buffer full, wait and retry
      while (!sent) {
        await Future.delayed(const Duration(milliseconds: 100));
        sent = sendPacket(chunkPacket.encodeBinary(), true);
      }

      onProgress(transferId, (i + 1) / totalChunks, messageId);
      await Future.delayed(Duration(milliseconds: _currentThrottleMs));
    }
  }

  Future<void> _streamFileChunks(
    String transferId,
    String messageId,
    File file,
    int totalChunks,
    Function(dynamic packet, bool isBinary) sendPacket,
    Function(String transferId, double progress, String? messageId) onProgress,
    PacketType chunkType,
  ) async {
    final raf = await file.open(mode: FileMode.read);
    
    for (int i = 0; i < totalChunks; i++) {
      final bytes = await raf.read(_currentChunkSize);
      
      final chunkPacket = TransferPacket(
        type: chunkType,
        transferId: transferId,
        index: i,
        binaryData: bytes,
      );

      bool sent = sendPacket(chunkPacket.encodeBinary(), true);
      
      // Flow Control Retry
      while (!sent) {
        await Future.delayed(const Duration(milliseconds: 100));
        sent = sendPacket(chunkPacket.encodeBinary(), true);
      }

      onProgress(transferId, (i + 1) / totalChunks, messageId);
      await Future.delayed(Duration(milliseconds: _currentThrottleMs));
    }
    
    await raf.close();
  }

  /// Handles an incoming packet (either String or Uint8List).
  Future<File?> handleIncomingPacket(
    dynamic rawData, {
    required Function(String transferId, double progress, String? messageId) onProgress,
  }) async {
    TransferPacket packet;
    
    if (rawData is String) {
      final Map<String, dynamic> json = jsonDecode(rawData);
      packet = TransferPacket.fromJson(json);
    } else if (rawData is Uint8List) {
      packet = TransferPacket.decodeBinary(rawData);
    } else {
      return null;
    }

    if (packet.type == PacketType.image_meta || packet.type == PacketType.file_meta) {
      return await _initIncomingTransfer(packet, onProgress);
    }

    if (packet.type == PacketType.image_chunk || packet.type == PacketType.file_chunk) {
      return await _handleChunk(packet, onProgress);
    }

    return null;
  }

  Future<File?> _initIncomingTransfer(TransferPacket packet, Function onProgress) async {
    _incomingMeta[packet.transferId] = packet;
    _receivedIndices[packet.transferId] = {};
    
    final directory = await getApplicationDocumentsDirectory();
    final String tempPath = '${directory.path}/temp_${packet.transferId}_${packet.fileName}';
    final file = File(tempPath);
    if (await file.exists()) await file.delete();
    
    final raf = await file.open(mode: FileMode.write);
    _activeFiles[packet.transferId] = raf;
    
    onProgress(packet.transferId, 0.0, packet.messageId);
    return null;
  }

  Future<File?> _handleChunk(TransferPacket packet, Function onProgress) async {
    final id = packet.transferId;
    final meta = _incomingMeta[id];
    final raf = _activeFiles[id];
    
    if (meta == null || raf == null || packet.binaryData == null) return null;

    // Use current chunk size for offset calculation if index is provided
    // Note: This requires that BOTH peers agree on the chunk size or that the chunk size is passed in the packet.
    // In V2, we will assume a fixed offset based on the binary data length for simplicity, 
    // but the packet index * chunkSize is safer if chunks are lost.
    // However, since we now have adaptive sizes, we should store the offsets or use a simpler append if ordered.
    
    // Use the chunkSize stored in metadata to calculate the exact offset.
    // This allows support for out-of-order chunks even with adaptive sizing.
    final chunkSize = meta.chunkSize ?? chunkNormal;
    await raf.setPosition(packet.index! * chunkSize);
    await raf.writeFrom(packet.binaryData!);
    
    _receivedIndices[id]!.add(packet.index!);
    
    int receivedCount = _receivedIndices[id]!.length;
    onProgress(id, receivedCount / meta.totalChunks!, meta.messageId);

    if (receivedCount == meta.totalChunks) {
      return await _finalizeTransfer(id);
    }
    return null;
  }

  Future<File?> _finalizeTransfer(String id) async {
    final meta = _incomingMeta[id]!;
    final raf = _activeFiles[id]!;
    
    await raf.flush();
    await raf.close();
    _activeFiles.remove(id);

    final directory = await getApplicationDocumentsDirectory();
    final String tempPath = '${directory.path}/temp_${id}_${meta.fileName}';
    final String finalPath = '${directory.path}/${meta.fileName}';
    
    // Verify hash
    final actualHash = await _calculateFileHash(tempPath);
    if (actualHash == meta.hash) {
      final finalFile = await File(tempPath).rename(finalPath);
      _cleanup(id);
      return finalFile;
    } else {
      print("Integrity check failed for $id");
      await File(tempPath).delete();
      _cleanup(id);
      return null;
    }
  }

  void _cleanup(String transferId) {
    _incomingMeta.remove(transferId);
    _activeFiles[transferId]?.close();
    _activeFiles.remove(transferId);
    _receivedIndices.remove(transferId);
  }

  TransferPacket? getMeta(String transferId) => _incomingMeta[transferId];
}
