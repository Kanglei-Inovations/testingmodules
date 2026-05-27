import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../features/connection/controller/connection_controller.dart';
import '../utils/theme_colors.dart';
import '../widgets/cyber_button.dart';
import '../widgets/mesh_background.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/neural_handshake_overlay.dart';
import '../widgets/glow_sphere.dart';
import 'chat_page.dart';
import '../features/connection/ui/qr_generator_screen.dart';
import '../features/connection/ui/qr_scanner_screen.dart';
import '../utils/sdp_compressor.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final controller = Get.find<ConnectionController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildMeshBackground(),
          MeshBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopHeader(context),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 20),
                      _buildStatusCard(),
                      const SizedBox(height: 30),
                      _buildConnectedNodeCard(context),
                      const SizedBox(height: 30),
                      _buildActionButtons(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedNodeCard(BuildContext context) {
    return Obx(() {
      final isConnected = controller.peerState.value == PeerState.connected || controller.peerState.value == PeerState.syncing;
      if (!isConnected) return const SizedBox();

      final session = controller.activePeerSession.value;
      final peerName = session?.peerName ?? "Initializing Node...";
      final peerPhoto = session?.peerPhoto;
      final address = session?.address ?? "Locating...";
      final gps = session?.latitude != null ? "${session!.latitude!.toStringAsFixed(4)}, ${session.longitude!.toStringAsFixed(4)}" : "GPS Pending";
      
      // Calculate duration
      final duration = session != null ? DateTime.now().difference(session.lastConnectedAt) : Duration.zero;
      final durationStr = "${duration.inMinutes}m ${duration.inSeconds % 60}s";

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeColors.glassBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ThemeColors.terminalGreen.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: ThemeColors.terminalGreen.withOpacity(0.1), blurRadius: 20),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ThemeColors.terminalGreen, width: 2),
                        boxShadow: [BoxShadow(color: ThemeColors.terminalGreen.withOpacity(0.3), blurRadius: 10)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: peerPhoto != null && File(peerPhoto).existsSync()
                            ? Image.file(File(peerPhoto), fit: BoxFit.cover)
                            : const CircleAvatar(
                                backgroundColor: Colors.white10,
                                child: Icon(Icons.person, color: ThemeColors.terminalGreen, size: 35),
                              ),
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(color: ThemeColors.terminalGreen, shape: BoxShape.circle),
                    )

                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🟢 CONNECTED NODE", style: TextStyle(color: ThemeColors.terminalGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      Text(peerName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: ThemeColors.neonPink, size: 10),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(address, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, overflow: TextOverflow.ellipsis)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBit("GPS COORDINATES", gps),
                _buildInfoBit("DURATION", durationStr),
                _buildInfoBit("SIGNAL", "98%"),
              ],
            ),
            const SizedBox(height: 20),
            CyberButton(
              label: "OPEN NEURAL CHANNEL",
              color: ThemeColors.terminalGreen,
              onPressed: () => Get.to(() => const ChatPage()),
              height: 45,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoBit(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return GetBuilder<ConnectionController>(
      builder: (controller) {
        final user = controller.localUser;
        final displayName = user?.name ?? "Identity not established";
        final isConnected = controller.peerState.value == PeerState.connected || controller.peerState.value == PeerState.syncing;
        final statusColor = isConnected ? ThemeColors.terminalGreen : Colors.white38;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Profile Image with Active Dot
                    GestureDetector(
                      onTap: () => _showProfileDialog(context),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: ThemeColors.neonPurple, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeColors.neonPurple.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white10,
                              backgroundImage: user?.profilePhotoPath != null 
                                  ? FileImage(File(user!.profilePhotoPath!)) 
                                  : null,
                              child: user?.profilePhotoPath == null 
                                  ? const Icon(Icons.person, color: ThemeColors.neonCyan) 
                                  : null,
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: ThemeColors.darkBg, width: 2),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: const Duration(seconds: 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Neural node active,',
                            style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_tethering, color: ThemeColors.neonCyan, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? "P2P LIVE" : "IDLE",
                      style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showProfileDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileDialog(),
    );
  }

  Widget _buildMeshBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -50,
          child: GlowSphere(color: ThemeColors.neonPurple.withOpacity(0.15), size: 400),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).move(duration: const Duration(seconds: 5), begin: const Offset(0, 0), end: const Offset(50, 50)),
        Positioned(
          bottom: -150,
          right: -50,
          child: GlowSphere(color: ThemeColors.neonCyan.withOpacity(0.15), size: 500),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).move(duration: const Duration(seconds: 7), begin: const Offset(0, 0), end: const Offset(-50, -30)),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Obx(() {
      final state = controller.peerState.value;
      final isConnected = state == PeerState.connected || state == PeerState.syncing;
      
      String statusText = "NODE OFFLINE";
      Color accentColor = Colors.white24;

      switch (state) {
        case PeerState.connected:
          statusText = "SECURE CHANNEL ACTIVE";
          accentColor = ThemeColors.neonCyan;
          break;
        case PeerState.syncing:
          statusText = "SYNCHRONIZING DATA...";
          accentColor = ThemeColors.neonPurple;
          break;
        case PeerState.reconnecting:
          statusText = "RE-ESTABLISHING LINK...";
          accentColor = Colors.amber;
          break;
        case PeerState.stale:
          statusText = "SIGNAL WEAK / STALE";
          accentColor = Colors.orange;
          break;
        case PeerState.gatheringIce:
          statusText = "GATHERING NETWORK PATHS";
          accentColor = ThemeColors.neonCyan;
          break;
        case PeerState.signaling:
          statusText = "NEGOTIATING HANDSHAKE";
          accentColor = ThemeColors.neonPink;
          break;
        default:
          break;
      }

      return Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: ThemeColors.glassBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isConnected ? accentColor : Colors.white10),
          boxShadow: [
            if (isConnected) BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 30)
          ],
        ),
        child: Column(
          children: [
            _buildStatusIndicator(state, accentColor),
            const SizedBox(height: 20),
            Text(
              statusText,
              style: TextStyle(
                color: isConnected ? accentColor : Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
            if (isConnected) ...[
              const SizedBox(height: 10),
              const Text("DIRECT P2P ENCRYPTION ENABLED", style: TextStyle(color: Colors.white30, fontSize: 10)),
            ]
          ],
        ),
      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
    });
  }

  Widget _buildStatusIndicator(PeerState state, Color color) {
    IconData icon = Icons.link_off;
    if (state == PeerState.connected || state == PeerState.syncing) icon = Icons.link;
    if (state == PeerState.reconnecting || state == PeerState.gatheringIce) icon = Icons.sync_problem;
    if (state == PeerState.stale) icon = Icons.wifi_off_rounded;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 40),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 2), color: color.withOpacity(0.3));
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          CyberButton(
            label: "⚡ HANDSHAKE NEURAL LINK",
            color: ThemeColors.neonCyan,
            onPressed: () => _showHandshakeOptions(context),
            fullWidth: true,
          ),


        ],
      ),
    );
  }

  void _showHandshakeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: ThemeColors.darkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: ThemeColors.neonCyan, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("NEURAL LINK HANDSHAKE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 30),
            CyberButton(
              label: "CREATE INITIAL OFFER",
              color: ThemeColors.neonCyan,
              onPressed: () {
                Get.back();
                controller.isSdpReady.value = false;
                controller.createOffer();
                Get.to(() => NeuralHandshakeOverlay(), opaque: false);
              },
              fullWidth: true,
            ),
            const SizedBox(height: 15),
            CyberButton(
              label: "PROCESS REMOTE LINK",
              color: ThemeColors.neonPink,
              onPressed: () {
                Get.back();
                _showAnswerInputChoice(context);
              },
              fullWidth: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAnswerInputChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: ThemeColors.darkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: ThemeColors.neonPink, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("PROCESS REMOTE LINK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 30),
            CyberButton(
              label: "ACTIVATE NEURAL SCANNER",
              color: ThemeColors.neonCyan,
              onPressed: () async {
                Get.back();
                final result = await Get.to<String>(() => const QrScannerScreen());
                if (result != null) {
                  _processRemoteSdp(context, result);
                }
              },
              fullWidth: true,
            ),
            const SizedBox(height: 15),
            CyberButton(
              label: "MANUAL DATA INJECTION",
              color: ThemeColors.neonPink,
              onPressed: () {
                Get.back();
                _showManualPasteDialog(context);
              },
              fullWidth: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showManualPasteDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: ThemeColors.darkBg.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ThemeColors.neonPink, width: 1.5),
          ),
          title: const Text("DATA INJECTION", style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: "PASTE REMOTE SDP STREAM...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white24)),
            ),
            CyberButton(
              label: "INJECT",
              color: ThemeColors.neonPink,
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  Get.back();
                  _processRemoteSdp(context, textController.text.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processRemoteSdp(BuildContext context, String sdp) {
    final decoded = SdpCompressor.decode(sdp);
    final Map<String, dynamic> sdpMap = jsonDecode(decoded);
    final type = sdpMap["type"];

    if (type == "offer") {
      // Device B Receiving Offer
      Get.to(() => NeuralHandshakeOverlay(isReceiving: true), opaque: false);
      controller.handleRemoteSdp(sdp);
    } else {
      // Device A Receiving Answer
      Get.to(() => NeuralHandshakeOverlay(isCompleting: true), opaque: false);
      controller.handleRemoteSdp(sdp);
    }
  }

  void _showSharePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: ThemeColors.darkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: ThemeColors.neonCyan, width: 2)),
        ),
        child: Obx(() {
          final isReady = controller.isSdpReady.value;
          final sdp = controller.localSdp.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isReady ? "NODE IDENTITY ACTIVE" : "GATHERING NETWORK PATHS",
                style: TextStyle(
                  color: isReady ? Colors.white : ThemeColors.neonCyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 30),
              if (!isReady)
                const Column(
                  children: [
                    CircularProgressIndicator(color: ThemeColors.neonCyan),
                    SizedBox(height: 20),
                    Text("SYNCING WITH STUN SERVERS...", style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                )
              else ...[
                CyberButton(
                  label: "GENERATE QR CODE",
                  color: ThemeColors.neonCyan,
                  onPressed: () => Get.to(() => QrGeneratorScreen(sdpData: sdp)),
                  fullWidth: true,
                ),
                const SizedBox(height: 15),
                CyberButton(
                  label: "SHARE SECURE LINK",
                  color: ThemeColors.neonPurple,
                  onPressed: () {
                    final encoded = SdpCompressor.encode(sdp);
                    Share.share(encoded, subject: "NEURAL NODE IDENTITY");
                  },
                  fullWidth: true,
                ),
              ],
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }
}
