import 'dart:io' as io;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../features/connection/controller/connection_controller.dart';
import '../data/collections/message_collection.dart';
import '../data/collections/peer_session_collection.dart';
import '../services/thumbnail_service.dart';
import '../utils/theme_colors.dart';
import '../widgets/mesh_background.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ConnectionController controller = Get.find();
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    controller.messages.listen((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(100.ms, () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.darkBg,
      body: Stack(
        children: [
          const MeshBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSecurityBanner(),
                _buildMessageList(),
                _buildInputArea(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(String path) async {
    if (path.isEmpty || !io.File(path).existsSync()) {
      Get.snackbar("SYSTEM", "TRANSMISSION INCOMPLETE OR FILE NOT FOUND",
          backgroundColor: Colors.red.withValues(alpha: 0.5), colorText: Colors.white);
      return;
    }
    await OpenFilex.open(path);
  }

  Widget _buildAppBar() {
    return Obx(() {
      final session = controller.activePeerSession.value;
      final isOnline = controller.peerState.value == PeerState.connected;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: ThemeColors.darkBg.withValues(alpha: 0.8),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
            _buildAvatar(isOnline, session?.peerPhoto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session?.peerName ?? 'NEURAL NODE',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: isOnline ? ThemeColors.terminalGreen : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => controller.startCall(true),
              icon: const Icon(Icons.videocam_outlined, color: ThemeColors.neonCyan),
            ),
            IconButton(
              onPressed: () => controller.startCall(false),
              icon: const Icon(Icons.call_outlined, color: ThemeColors.neonCyan),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert, color: Colors.white70),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAvatar(bool isOnline, [String? photo]) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipOval(
            child: photo != null && io.File(photo).existsSync()
                ? Image.file(
                    io.File(photo),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                  )
                : const Icon(Icons.person, color: Colors.white),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: ThemeColors.terminalGreen,
                shape: BoxShape.circle,
                border: Border.all(color: ThemeColors.darkBg, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.3), size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Messages are end-to-end encrypted. No one outside of this chat can read them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: Obx(() {
        final messages = controller.messages.toList();
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final reversedMessages = messages.reversed.toList();
        
        return ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: reversedMessages.length,
          itemBuilder: (context, index) {
            final message = reversedMessages[index];
            return _buildMessageRow(context, message, index);
          },
        );
      }),
    );
  }

  Widget _buildMessageRow(BuildContext context, MessageCollection message, int index) {
    final session = controller.activePeerSession.value;
    final myPhoto = controller.localUser?.profilePhotoPath;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isMe) _buildMessageAvatar(session?.peerPhoto, session?.peerId ?? 'peer'),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildMessageBubble(context, message),
              const SizedBox(height: 6),
              _buildHopIndicator(message),
            ],
          ),
          const SizedBox(width: 12),
          if (message.isMe) _buildMessageAvatar(myPhoto, 'me'),
        ],
      ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildMessageAvatar(String? photo, String id) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: ClipOval(
        child: photo != null && io.File(photo).existsSync()
            ? Image.file(io.File(photo), fit: BoxFit.cover)
            : Center(
                child: Text(
                  id == 'me' ? 'ME' : (id.length > 2 ? id.substring(0, 2).toUpperCase() : id.toUpperCase()),
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, MessageCollection message) {
    Widget content;
    switch (message.type) {
      case MessageType.image:
        content = _buildImageContent(message);
        break;
      case MessageType.file:
        content = _buildFileContent(message);
        break;
      case MessageType.location:
        content = _buildLocationContent(message);
        break;
      default:
        content = _buildTextContent(message);
    }

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isMe ? const Color(0xFF00383F).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: message.isMe ? ThemeColors.neonCyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          content,
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
              if (message.isMe) ...[
                const SizedBox(width: 4),
                _buildStatusIcon(message),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(MessageCollection message) {
    return Text(
      message.text ?? "",
      style: const TextStyle(color: Colors.white, fontSize: 15),
    );
  }

  Widget _buildImageContent(MessageCollection message) {
    final bool isReady = message.progress >= 1.0 && message.imageUrl != null && io.File(message.imageUrl!).existsSync();

    if (!isReady) {
      return _buildShimmerPlaceholder(message.progress,
        status: message.progress < 1.0 ? (message.isMe ? "Sending..." : "Receiving...") : "Processing...",
        isMine: message.isMe);
    }

    return GestureDetector(
      onTap: () => _openFile(message.imageUrl!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          io.File(message.imageUrl!),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildShimmerPlaceholder(1.0, status: "Error", isMine: message.isMe),
        ),
      ),
    );
  }

  Widget _buildFileContent(MessageCollection message) {
    final isComplete = message.progress >= 1.0;
    final fileName = message.text ?? "Unknown File";
    final isVideo = ThumbnailService.isVideo(message.filePath ?? fileName);
    final isPdf = ThumbnailService.isPdf(message.filePath ?? fileName);

    return GestureDetector(
      onTap: () => _openFile(message.filePath ?? message.imageUrl ?? ""),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isComplete ? ThemeColors.neonPurple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isComplete ? (isPdf ? Icons.picture_as_pdf : (isVideo ? Icons.play_arrow : Icons.insert_drive_file)) : Icons.file_download_outlined,
                    color: isComplete ? ThemeColors.neonPurple : Colors.white54,
                    size: 20
                  ),
                ),
                if (!isComplete)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: message.progress,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(ThemeColors.neonPurple),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isComplete
                      ? 'Ready'
                      : '${(message.progress * 100).toInt()}%',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(double progress, {String status = "Loading...", bool isMine = false}) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.1,
            child: const Icon(Icons.image, size: 60, color: Colors.white),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: progress > 0 && progress < 1.0 ? progress : null,
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(ThemeColors.neonCyan),
              ),
              const SizedBox(height: 12),
              Text(
                status,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              if (progress > 0 && progress < 1.0)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(color: ThemeColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ).animate(onPlay: (controller) => controller.repeat())
       .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.05)),
    );
  }

  Widget _buildLocationContent(MessageCollection message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            height: 120,
            color: Colors.white.withValues(alpha: 0.1),
            child: const Icon(Icons.map, color: Colors.white38, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        Text(message.text ?? 'Current Location', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHopIndicator(MessageCollection message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.hub_outlined, color: ThemeColors.neonCyan, size: 10),
        const SizedBox(width: 4),
        Text(
          '1 hop',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.security, color: ThemeColors.terminalGreen, size: 10),
        const SizedBox(width: 4),
        Text(
          'Encrypted',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(MessageCollection message) {
    if (message.seenAt != null) {
      return const Icon(Icons.done_all, size: 12, color: ThemeColors.neonCyan);
    } else if (message.deliveredAt != null) {
      return const Icon(Icons.done_all, size: 12, color: Colors.white38);
    } else if (message.isSynced) {
       return const Icon(Icons.check, size: 12, color: Colors.white38);
    } else {
      return const Icon(Icons.access_time, size: 12, color: Colors.white38);
    }
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _showAttachmentSheet(context),
                    icon: Icon(Icons.attach_file, color: Colors.white.withValues(alpha: 0.4), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          controller.sendMessage(value);
                          textController.clear();
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.emoji_emotions_outlined, color: Colors.white.withValues(alpha: 0.4), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
               if (textController.text.trim().isNotEmpty) {
                  controller.sendMessage(textController.text);
                  textController.clear();
                }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [ThemeColors.neonCyan, ThemeColors.neonPurple]),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: ThemeColors.darkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.image, 'Gallery', Colors.purple, () {
                  Get.back();
                  controller.sendImage(source: ImageSource.gallery);
                }),
                _buildAttachmentOption(Icons.camera_alt, 'Camera', Colors.pink, () {
                  Get.back();
                  controller.sendImage(source: ImageSource.camera);
                }),
                _buildAttachmentOption(Icons.description, 'Document', Colors.blue, () {
                  Get.back();
                  controller.sendFile();
                }),
                _buildAttachmentOption(Icons.location_on, 'Location', Colors.green, () {
                   Get.back();
                   controller.sendLocation();
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
