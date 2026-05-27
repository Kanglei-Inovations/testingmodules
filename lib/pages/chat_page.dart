import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../features/connection/controller/connection_controller.dart';
import '../data/collections/message_collection.dart';
import '../services/thumbnail_service.dart';
import '../utils/theme_colors.dart';
import '../widgets/cyber_button.dart';
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
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          MeshBackground(),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 5),

              Expanded(
                child: Obx(() {
                  final messages = controller.messages.toList();
                  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                  
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final showDate = index == 0 || 
                          DateFormat('yyyy-MM-dd').format(messages[index-1].timestamp) != 
                          DateFormat('yyyy-MM-dd').format(msg.timestamp);

                      return Column(
                        children: [
                          if (showDate) _buildDateHeader(msg.timestamp),
                          _ChatMessageTile(
                            message: msg, 
                            peerPhoto: controller.activePeerSession.value?.peerPhoto,
                            onInfo: (offset) => _showMessageInfo(context, msg, offset),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.5),
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: Obx(() {
        final session = controller.activePeerSession.value;
        final isOnline = controller.peerState.value == PeerState.connected;
        
        return Row(
          children: [
            _buildAvatar(session?.peerPhoto),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session?.peerName ?? "NEURAL NODE", 
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  isOnline ? "Online" : "Connecting...",
                  style: TextStyle(color: isOnline ? ThemeColors.terminalGreen : Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        );
      }),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_outlined, color: ThemeColors.neonCyan, size: 22), onPressed: () {}),
        IconButton(icon: const Icon(Icons.call_outlined, color: ThemeColors.neonCyan, size: 20), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.white70), onPressed: () {}),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildAvatar(String? photo) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ThemeColors.neonPurple.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: ThemeColors.neonPurple.withOpacity(0.2), blurRadius: 15)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: photo != null && File(photo).existsSync()
            ? Image.file(File(photo), fit: BoxFit.cover)
            : const Icon(Icons.person, color: Colors.white38),
      ),
    );
  }


  Widget _buildDateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 25),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white10)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              DateFormat('MMMM d').format(date).toUpperCase(),
              style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildCircleAction(Icons.add, ThemeColors.neonCyan, () => _showAttachmentMenu(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (val) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.white38),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildCircleAction(
              textController.text.isNotEmpty ? Icons.send : Icons.mic_none, 
              ThemeColors.neonCyan, 
              () {
                if (textController.text.isNotEmpty) {
                  controller.sendMessage(textController.text);
                  textController.clear();
                  setState(() {});
                }
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // Fix: Background is now seen
      builder: (context) => _AttachmentMenu(
        onAction: (action) {
          Get.back();
          switch (action) {
            case "Image": controller.sendImage(source: ImageSource.gallery); break;
            case "File": controller.sendFile(); break;
            case "Location": controller.sendLocation(); break;
            case "Contact": controller.sendContact(); break;
            case "Camera": controller.sendImage(source: ImageSource.camera); break;
            case "Code": _showCodeInputDialog(context); break;
          }
        },
      ),
    );
  }

  void _showCodeInputDialog(BuildContext context) {
    final codeController = TextEditingController();
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: ThemeColors.darkBg.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: ThemeColors.neonPurple)),
          title: const Text("CODE INJECTION", style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2)),
          content: TextField(
            controller: codeController,
            maxLines: 10,
            style: const TextStyle(color: ThemeColors.neonCyan, fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: "Enter code snippet...",
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
            CyberButton(
              label: "TRANSMIT",
              color: ThemeColors.neonPurple,
              onPressed: () {
                if (codeController.text.isNotEmpty) {
                  Get.back();
                  controller.sendCode(codeController.text.trim());
                }
              },
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageInfo(BuildContext context, MessageCollection msg, Offset offset) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _MessageInfoPopup(message: msg, offset: offset),
    );
  }
}

class _ChatMessageTile extends StatelessWidget {
  final MessageCollection message;
  final String? peerPhoto;
  final Function(Offset) onInfo;

  const _ChatMessageTile({required this.message, this.peerPhoto, required this.onInfo});

  @override
  Widget build(BuildContext context) {
    final ConnectionController controller = Get.find();
    final myPhoto = controller.localUser?.profilePhotoPath;

    return GestureDetector(
      onLongPressStart: message.isMe ? (details) => onInfo(details.globalPosition) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isMe) _buildAvatar(peerPhoto, ThemeColors.terminalGreen),
            const SizedBox(width: 8),
            Flexible(
              child: CustomPaint(
                painter: ChatBubblePainter(
                  color: message.isMe 
                      ? ThemeColors.neonPurple.withOpacity(0.12) 
                      : ThemeColors.neonCyan.withOpacity(0.08),
                  isMe: message.isMe,
                  borderColor: message.isMe 
                      ? ThemeColors.neonPurple.withOpacity(0.3) 
                      : ThemeColors.neonCyan.withOpacity(0.2),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.image)
                        _buildImageContent(context)
                      else if (message.type == MessageType.file)
                        _buildFileContent(context)
                      else
                        Text(
                          message.text ?? "",
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Spacer(),
                          Text(
                            DateFormat('h:mm a').format(message.timestamp),
                            style: const TextStyle(color: Colors.white24, fontSize: 7),
                          ),
                          if (message.isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all, 
                              size: 10, 
                              color: message.seenAt != null ? ThemeColors.neonCyan : Colors.white24
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (message.isMe) _buildAvatar(myPhoto, ThemeColors.neonPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photo, Color accentColor) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: photo != null && File(photo).existsSync()
            ? Image.file(File(photo), fit: BoxFit.cover)
            : Icon(Icons.person, color: accentColor.withOpacity(0.3), size: 18),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          message.imageUrl != null && File(message.imageUrl!).existsSync()
              ? Image.file(File(message.imageUrl!), fit: BoxFit.cover, width: 220)
              : Container(
                  width: 220, 
                  height: 160, 
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image, color: Colors.white10)
                ),
          if (message.progress < 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(
                value: message.progress,
                backgroundColor: Colors.white10,
                color: ThemeColors.neonCyan,
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    final isVideo = ThumbnailService.isVideo(message.filePath ?? message.text ?? "");
    final isPdf = ThumbnailService.isPdf(message.filePath ?? message.text ?? "");
    
    return GestureDetector(
      onTap: () => _openFile(message.filePath ?? message.imageUrl ?? ""),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                message.imageUrl != null && File(message.imageUrl!).existsSync()
                    ? Image.file(File(message.imageUrl!), fit: BoxFit.cover, width: 220, height: 160)
                    : Container(
                        width: 220,
                        height: 160,
                        color: Colors.white10,
                        child: Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                          color: Colors.white24,
                          size: 48,
                        ),
                      ),
                if (isVideo)
                  const Icon(Icons.play_circle_fill, color: Colors.white70, size: 50),
              ],
            ),
          ),
          if (message.progress < 1.0)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: LinearProgressIndicator(
                 value: message.progress,
                 backgroundColor: Colors.white10,
                 color: ThemeColors.neonCyan,
                 minHeight: 2,
               ),
             ),
          const SizedBox(height: 8),
          Text(
            message.text ?? "File",
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _openFile(String path) async {
    if (path.isEmpty || !File(path).existsSync()) {
      Get.snackbar("SYSTEM", "TRANSMISSION INCOMPLETE OR FILE NOT FOUND", 
        backgroundColor: Colors.red.withOpacity(0.5), colorText: Colors.white);
      return;
    }
    await OpenFilex.open(path);
  }
}

class ChatBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isMe;

  ChatBubblePainter({required this.color, required this.isMe, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    const radius = 20.0;
    const tailWidth = 8.0;
    const tailHeight = 8.0;

    if (isMe) {
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - tailHeight - radius);
      path.quadraticBezierTo(size.width, size.height - tailHeight, size.width - radius, size.height - tailHeight);
      
      // Sharp Tail
      path.lineTo(size.width - radius, size.height - tailHeight);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width - tailWidth, size.height - tailHeight);
      
      path.lineTo(radius, size.height - tailHeight);
      path.quadraticBezierTo(0, size.height - tailHeight, 0, size.height - tailHeight - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    } else {
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - tailHeight - radius);
      path.quadraticBezierTo(size.width, size.height - tailHeight, size.width - radius, size.height - tailHeight);
      
      path.lineTo(tailWidth, size.height - tailHeight);
      path.lineTo(0, size.height); // Sharp Tail
      path.lineTo(radius, size.height - tailHeight);
      
      path.lineTo(radius, size.height - tailHeight);
      path.quadraticBezierTo(0, size.height - tailHeight, 0, size.height - tailHeight - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AttachmentMenu extends StatelessWidget {
  final Function(String) onAction;
  const _AttachmentMenu({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
        margin: const EdgeInsets.all(20), // Floating effect
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117).withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ThemeColors.neonCyan.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40),
            BoxShadow(color: ThemeColors.neonCyan.withOpacity(0.1), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 25,
              crossAxisSpacing: 15,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildItem(Icons.image_outlined, "Image", ThemeColors.neonPurple),
                _buildItem(Icons.insert_drive_file_outlined, "File", ThemeColors.neonPurple),
                _buildItem(Icons.location_on_outlined, "Location", ThemeColors.neonCyan),
                _buildItem(Icons.person_outline, "Contact", ThemeColors.neonPurple),
                _buildItem(Icons.camera_alt_outlined, "Camera", ThemeColors.neonPurple),
                _buildItem(Icons.code, "Code", ThemeColors.neonPurple),
              ],
            ),
            const SizedBox(height: 20),
            _buildItem(Icons.close, "Cancel", Colors.white24, isCancel: true),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, Color color, {bool isCancel = false}) {
    return GestureDetector(
      onTap: () => isCancel ? Get.back() : onAction(label),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.25)),
              boxShadow: [if (!isCancel) BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label, 
            style: TextStyle(
              color: isCancel ? Colors.white24 : Colors.white70, 
              fontSize: 11, 
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5
            )
          ),
        ],
      ),
    );
  }
}

class _MessageInfoPopup extends StatelessWidget {
  final MessageCollection message;
  final Offset offset;

  const _MessageInfoPopup({required this.message, required this.offset});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final controller = Get.find<ConnectionController>();
    final peerName = controller.activePeerSession.value?.peerName ?? "Unknown Node";

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(onTap: () => Get.back(), child: Container(color: Colors.black26)),
          Positioned(
            left: 35,
            right: 35,
            top: offset.dy > MediaQuery.of(context).size.height / 2 ? null : offset.dy,
            bottom: offset.dy > MediaQuery.of(context).size.height / 2 ? (MediaQuery.of(context).size.height - offset.dy) : null,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ThemeColors.neonPurple.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black, blurRadius: 50),
                  BoxShadow(color: ThemeColors.neonPurple.withOpacity(0.1), blurRadius: 20)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("MESSAGE INFO", style: TextStyle(color: ThemeColors.neonCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3)),
                      IconButton(
                        icon: const Icon(Icons.close, color: ThemeColors.neonPurple, size: 20),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  // Original Message Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      message.text ?? "[Transmitted Media]", 
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInfoRow(Icons.done_all, "Delivered", DateFormat('h:mm a').format(message.timestamp), ThemeColors.neonCyan),
                  _buildInfoRow(Icons.visibility_outlined, "Seen", message.seenAt != null ? DateFormat('h:mm a').format(message.seenAt!) : DateFormat('h:mm a').format(message.timestamp.add(const Duration(minutes: 1))), ThemeColors.neonCyan),
                  _buildInfoRow(Icons.person_outline, "Received by", peerName, ThemeColors.neonPurple),
                  _buildInfoRow(Icons.lock_outline, "Encrypted", "End-to-end", Colors.white38),
                  _buildInfoRow(Icons.tag, "Message ID", message.messageId.substring(0, 12), Colors.white38),
                ],
              ),
            ).animate().scale(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, duration: 200.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Text(value, style: TextStyle(color: iconColor == ThemeColors.neonPurple ? ThemeColors.neonPurple : Colors.white70, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
