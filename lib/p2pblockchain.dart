// import 'dart:convert';
// import 'dart:io';
// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
// import 'package:share_plus/share_plus.dart';
//
// import 'features/connection/ui/qr_generator_screen.dart';
// import 'features/connection/ui/qr_scanner_screen.dart';
// import 'models/message_model.dart';
// import 'models/transfer_packet.dart';
// import 'services/image_transfer_manager.dart';
// import 'package:uuid/uuid.dart';
// import 'utils/sdp_compressor.dart';
//
// class P2PPage extends StatefulWidget {
//   const P2PPage({super.key});
//
//   @override
//   State<P2PPage> createState() => _P2PPageState();
// }
//
// class _P2PPageState extends State<P2PPage> {
//   RTCPeerConnection? peerConnection;
//   RTCDataChannel? dataChannel;
//   final ImageTransferManager _imageManager = ImageTransferManager();
//   final Uuid _uuid = const Uuid();
//
//   final TextEditingController localSdpController = TextEditingController();
//   final TextEditingController remoteSdpController = TextEditingController();
//   final TextEditingController messageController = TextEditingController();
//
//   final List<MessageModel> messages = [];
//
//   final Map<String, dynamic> configuration = {
//     'iceServers': [
//       {
//         'urls': [
//           'stun:stun.l.google.com:19302',
//           'stun:stun1.l.google.com:19302',
//         ]
//       }
//     ]
//   };
//
//   // Neon Colors
//   static const Color neonCyan = Color(0xFF00FFFF);
//   static const Color neonPink = Color(0xFFFE019A);
//   static const Color neonPurple = Color(0xFFB026FF);
//   static const Color darkBg = Color(0xFF0A0A12);
//   static const Color glassBg = Color(0x1AFFFFFF);
//
//   @override
//   void initState() {
//     super.initState();
//     initConnection();
//   }
//
//   Future<void> initConnection() async {
//     if (peerConnection != null) return; // Prevent double init
//     peerConnection = await createPeerConnection(configuration);
//
//     peerConnection!.onIceCandidate = (candidate) async {
//       RTCSessionDescription? localDescription =
//           await peerConnection!.getLocalDescription();
//
//       if (localDescription != null) {
//         final data = {
//           "sdp": localDescription.sdp,
//           "type": localDescription.type,
//         };
//
//         localSdpController.text = jsonEncode(data);
//         setState(() {});
//       }
//     };
//
//     peerConnection!.onConnectionState = (state) {
//       debugPrint("STATE: $state");
//     };
//
//     peerConnection!.onDataChannel = (channel) {
//       dataChannel = channel;
//       _setupDataChannel();
//     };
//   }
//
//   void resetConnection() async {
//     await dataChannel?.close();
//     await peerConnection?.close();
//     peerConnection = null;
//     dataChannel = null;
//
//     localSdpController.clear();
//     remoteSdpController.clear();
//     messageController.clear();
//     messages.clear();
//
//     await initConnection();
//     setState(() {});
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Node Identity Reset')),
//     );
//   }
//
//   void _setupDataChannel() {
//     dataChannel!.onMessage = (message) async {
//       try {
//         final packet = TransferPacket.fromJson(jsonDecode(message.text));
//
//         if (packet.type == PacketType.text_msg) {
//           setState(() {
//             messages.add(MessageModel(
//               text: packet.data,
//               type: MessageType.text,
//               isMe: false,
//             ));
//           });
//         } else {
//           // Image transfer packet
//           final file = await _imageManager.handleIncomingPacket(
//             message.text,
//             onProgress: _updateProgress,
//           );
//
//           if (file != null) {
//             _updateMessageForTransfer(packet.transferId, imageUrl: file.path);
//           }
//         }
//       } catch (e) {
//         debugPrint("Error handling message: $e");
//       }
//     };
//   }
//
//   void _updateProgress(String transferId, double progress) {
//     setState(() {
//       final index = messages.indexWhere((m) => m.transferId == transferId);
//       if (index != -1) {
//         messages[index] = messages[index].copyWith(progress: progress);
//       } else {
//         // New incoming transfer
//         messages.add(MessageModel(
//           type: MessageType.image,
//           isMe: false,
//           transferId: transferId,
//           progress: progress,
//         ));
//       }
//     });
//   }
//
//   void _updateMessageForTransfer(String transferId, {String? imageUrl}) {
//     setState(() {
//       final index = messages.indexWhere((m) => m.transferId == transferId);
//       if (index != -1) {
//         messages[index] = messages[index].copyWith(
//           progress: 1.0,
//           imageUrl: imageUrl,
//         );
//       }
//     });
//   }
//
//   Future<void> createOffer() async {
//     RTCDataChannelInit init = RTCDataChannelInit();
//     dataChannel = await peerConnection!.createDataChannel("chat", init);
//     _setupDataChannel();
//
//     RTCSessionDescription offer = await peerConnection!.createOffer();
//     await peerConnection!.setLocalDescription(offer);
//   }
//
//   Future<void> createAnswer() async {
//     if (remoteSdpController.text.isEmpty) return;
//     try {
//       final decoded = SdpCompressor.decode(remoteSdpController.text.trim());
//       Map<String, dynamic> offer = jsonDecode(decoded);
//
//       await peerConnection!.setRemoteDescription(
//         RTCSessionDescription(offer["sdp"], offer["type"]),
//       );
//
//       RTCSessionDescription answer = await peerConnection!.createAnswer();
//       await peerConnection!.setLocalDescription(answer);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Invalid Remote SDP: $e')),
//       );
//     }
//   }
//
//   Future<void> setAnswer() async {
//     if (remoteSdpController.text.isEmpty) return;
//     try {
//       final decoded = SdpCompressor.decode(remoteSdpController.text.trim());
//       Map<String, dynamic> answer = jsonDecode(decoded);
//
//       await peerConnection!.setRemoteDescription(
//         RTCSessionDescription(answer["sdp"], answer["type"]),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Invalid Remote Answer: $e')),
//       );
//     }
//   }
//
//   void sendMessage() {
//     if (messageController.text.trim().isEmpty) return;
//
//     final packet = TransferPacket(
//       type: PacketType.text_msg,
//       transferId: _uuid.v4(),
//       data: messageController.text,
//     );
//
//     dataChannel?.send(RTCDataChannelMessage(packet.encode()));
//
//     setState(() {
//       messages.add(MessageModel(
//         text: messageController.text,
//         type: MessageType.text,
//         isMe: true,
//       ));
//     });
//
//     messageController.clear();
//   }
//
//   Future<void> attachImage() async {
//     if (dataChannel == null) return;
//
//     final String? transferId = await _imageManager.sendImage(
//       sendPacket: (packet) => dataChannel?.send(RTCDataChannelMessage(packet)),
//       onProgress: _updateProgress,
//     );
//
//     if (transferId != null) {
//       // Logic for local image display is already handled by _updateProgress if we want
//       // but let's make sure it's added as "Me"
//       setState(() {
//         if (!messages.any((m) => m.transferId == transferId)) {
//           messages.add(MessageModel(
//             type: MessageType.image,
//             isMe: true,
//             transferId: transferId,
//           ));
//         }
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: darkBg,
//       body: Stack(
//         children: [
//           // Background Glows
//           Positioned(
//             top: -100,
//             left: -100,
//             child: _GlowSphere(color: neonPurple.withOpacity(0.2), size: 300),
//           ),
//           Positioned(
//             bottom: -50,
//             right: -50,
//             child: _GlowSphere(color: neonCyan.withOpacity(0.2), size: 400),
//           ),
//
//           SafeArea(
//             child: Column(
//               children: [
//                 _buildHeader(),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 10),
//                         _buildActionButtons(),
//                         const SizedBox(height: 16),
//                         _buildSdpInputs(),
//                         const SizedBox(height: 16),
//                         Expanded(child: _buildChatList()),
//                         _buildMessageInput(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: neonCyan, width: 2),
//               boxShadow: [
//                 BoxShadow(color: neonCyan.withOpacity(0.5), blurRadius: 10)
//               ],
//             ),
//             child: const Icon(Icons.hub_outlined, color: neonCyan, size: 28),
//           ),
//           const SizedBox(width: 15),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "NEURAL LINK",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 2,
//                   ),
//                 ),
//                 Text(
//                   "P2P ENCRYPTED PROTOCOL",
//                   style: TextStyle(
//                     color: neonCyan,
//                     fontSize: 10,
//                     letterSpacing: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: resetConnection,
//             icon: const Icon(Icons.refresh_rounded, color: neonPink),
//             tooltip: "Reset Node Identity",
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: _NeonButton(
//             label: "OFFER",
//             color: neonCyan,
//             onPressed: createOffer,
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: _NeonButton(
//             label: "ANSWER",
//             color: neonPink,
//             onPressed: createAnswer,
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: _NeonButton(
//             label: "SYNC",
//             color: neonPurple,
//             onPressed: setAnswer,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSdpInputs() {
//     return Container(
//       constraints: const BoxConstraints(maxHeight: 180), // Prevent vertical overflow
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             _GlassTextField(
//               controller: localSdpController,
//               label: "LOCAL DATA STREAM",
//               icon: Icons.upload_rounded,
//               accentColor: neonCyan,
//               readOnly: true,
//               suffixIcon: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.qr_code, color: neonCyan, size: 20),
//                     onPressed: () {
//                       if (localSdpController.text.isEmpty) return;
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => QrGeneratorScreen(sdpData: localSdpController.text),
//                         ),
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.copy, color: neonCyan, size: 20),
//                     onPressed: () {
//                       if (localSdpController.text.isEmpty) return;
//                       Clipboard.setData(ClipboardData(text: localSdpController.text));
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('SDP Copied to clipboard')),
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.share, color: neonCyan, size: 20),
//                     onPressed: () {
//                       if (localSdpController.text.isEmpty) return;
//                       Share.share(SdpCompressor.encode(localSdpController.text));
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//             _GlassTextField(
//               controller: remoteSdpController,
//               label: "REMOTE DATA STREAM",
//               icon: Icons.download_rounded,
//               accentColor: neonPink,
//               suffixIcon: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.qr_code_scanner, color: neonPink, size: 20),
//                     onPressed: () async {
//                       final result = await Navigator.push<String>(
//                         context,
//                         MaterialPageRoute(builder: (_) => const QrScannerScreen()),
//                       );
//                       if (result != null) {
//                         try {
//                           remoteSdpController.text = SdpCompressor.decode(result);
//                           // Auto-start connection
//                           if (localSdpController.text.isEmpty) {
//                             await createAnswer();
//                           } else {
//                             await setAnswer();
//                           }
//                         } catch (e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Invalid QR Data')),
//                           );
//                         }
//                       }
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.paste, color: neonPink, size: 20),
//                     onPressed: () async {
//                       final data = await Clipboard.getData('text/plain');
//                       final text = data?.text;
//                       if (text != null && text.isNotEmpty) {
//                         try {
//                           // Try decoding if it's compressed, otherwise use raw
//                           remoteSdpController.text = SdpCompressor.decode(text.trim());
//                         } catch (e) {
//                           remoteSdpController.text = text.trim();
//                         }
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildChatList() {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(
//         color: glassBg,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: ListView.builder(
//             padding: const EdgeInsets.all(15),
//             itemCount: messages.length,
//             itemBuilder: (context, index) {
//               final msg = messages[index];
//               return _ChatMessageTile(message: msg);
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessageInput() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: attachImage,
//             icon: const Icon(Icons.add_a_photo, color: neonCyan),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: _GlassTextField(
//               controller: messageController,
//               label: "TRANSMIT MESSAGE",
//               accentColor: neonPurple,
//               showGlow: true,
//             ),
//           ),
//           const SizedBox(width: 10),
//           GestureDetector(
//             onTap: sendMessage,
//             child: Container(
//               padding: const EdgeInsets.all(15),
//               decoration: BoxDecoration(
//                 color: neonPurple,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(color: neonPurple.withOpacity(0.4), blurRadius: 15)
//                 ],
//               ),
//               child: const Icon(Icons.send_rounded, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _ChatMessageTile extends StatelessWidget {
//   final MessageModel message;
//   const _ChatMessageTile({required this.message});
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Container(
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             padding: message.type == MessageType.image ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
//             decoration: BoxDecoration(
//               color: message.isMe ? _P2PPageState.neonPurple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(15),
//                 topRight: const Radius.circular(15),
//                 bottomLeft: Radius.circular(message.isMe ? 15 : 0),
//                 bottomRight: Radius.circular(message.isMe ? 0 : 15),
//               ),
//               border: Border.all(
//                 color: message.isMe ? _P2PPageState.neonPurple.withOpacity(0.5) : Colors.white10,
//               ),
//             ),
//             child: message.type == MessageType.image
//                 ? _buildImageBubble(context)
//                 : Text(
//                     message.text ?? "",
//                     style: const TextStyle(color: Colors.white, fontSize: 15),
//                   ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: Text(
//               "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
//               style: const TextStyle(color: Colors.white30, fontSize: 10),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImageBubble(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(15),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           if (message.imageUrl != null)
//             Image.file(
//               File(message.imageUrl!),
//               fit: BoxFit.cover,
//             )
//           else
//             Container(
//               height: 150,
//               width: 200,
//               color: Colors.white10,
//               child: const Icon(Icons.image, color: Colors.white24, size: 40),
//             ),
//           if (message.progress < 1.0)
//             Container(
//               color: Colors.black54,
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(
//                     value: message.progress,
//                     color: _P2PPageState.neonCyan,
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "${(message.progress * 100).toInt()}%",
//                     style: const TextStyle(color: _P2PPageState.neonCyan, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// class _NeonButton extends StatelessWidget {
//   final String label;
//   final Color color;
//   final VoidCallback onPressed;
//
//   const _NeonButton({
//     required this.label,
//     required this.color,
//     required this.onPressed,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Container(
//         height: 45,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: color, width: 1.5),
//           boxShadow: [
//             BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
//           ],
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//             letterSpacing: 1.2,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _GlassTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String label;
//   final IconData? icon;
//   final Color accentColor;
//   final bool readOnly;
//   final bool showGlow;
//   final Widget? suffixIcon;
//
//   const _GlassTextField({
//     required this.controller,
//     required this.label,
//     this.icon,
//     required this.accentColor,
//     this.readOnly = false,
//     this.showGlow = false,
//     this.suffixIcon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: _P2PPageState.glassBg,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(color: Colors.white10),
//         boxShadow: showGlow ? [
//           BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 15)
//         ] : null,
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//           child: TextField(
//             controller: controller,
//             readOnly: readOnly,
//             style: const TextStyle(color: Colors.white, fontSize: 14),
//             maxLines: readOnly ? 1 : null,
//             decoration: InputDecoration(
//               isDense: true,
//               labelText: label,
//               labelStyle: TextStyle(color: accentColor.withOpacity(0.7), fontSize: 12),
//               prefixIcon: icon != null ? Icon(icon, color: accentColor, size: 20) : null,
//               suffixIcon: suffixIcon,
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _GlowSphere extends StatelessWidget {
//   final Color color;
//   final double size;
//   const _GlowSphere({required this.color, required this.size});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: RadialGradient(
//           colors: [color, color.withOpacity(0)],
//         ),
//       ),
//     );
//   }
// }