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
import 'qr_generator_screen.dart';
import 'qr_scanner_screen.dart';
import 'create_connect_page.dart';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(context),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "WELCOME BACK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        "Your Neural Network is Ready",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _buildQuickActions(context),
                      const SizedBox(height: 30),
                      _buildNetworkAnalytics(context),
                      const SizedBox(height: 30),
                      _buildConnectedNodeCard(context),
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

  Widget _buildNetworkAnalytics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "NETWORK ANALYTICS",
          style: TextStyle(
            color: Colors.white30,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeColors.glassBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricTile("TRANSFER SPEED", controller.transportSpeed, Icons.speed, ThemeColors.neonCyan),
                  _buildMetricTile("DISCOVERY", controller.discoveryStatus, Icons.radar, ThemeColors.neonPurple),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricTile("SIGNAL QUALITY", controller.networkStatus, Icons.wifi, ThemeColors.terminalGreen),
                  _buildMetricTile("SYNC QUEUE", RxString("HEALTHY"), Icons.sync, ThemeColors.neonPink),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, RxString value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 16),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Obx(() => Text(value.value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUICK ACTIONS",
          style: TextStyle(
            color: Colors.white30,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        _QuickActionButton(
          label: "Create / Connect",
          icon: Icons.add_circle_outline,
          color: ThemeColors.neonPurple,
          trailing: const Icon(Icons.add, color: Colors.white38, size: 18),
          onPressed: () => Get.to(() => CreateConnectPage()),
        ),
        _QuickActionButton(
          label: "Join with QR / Link",
          icon: Icons.qr_code_scanner_rounded,
          color: ThemeColors.neonCyan,
          trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          onPressed: () => _showAnswerInputChoice(context),
        ),
        _QuickActionButton(
          label: "My Peers",
          icon: Icons.people_outline_rounded,
          color: Colors.white38,
          trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          onPressed: () {},
        ),
        _QuickActionButton(
          label: "Settings",
          icon: Icons.settings_outlined,
          color: Colors.white38,
          trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          onPressed: () {
             // Navigation logic
          },
        ),
      ],
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
      
      final duration = session != null ? DateTime.now().difference(session.lastConnectedAt) : Duration.zero;
      final durationStr = "${duration.inMinutes}m ${duration.inSeconds % 60}s";

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeColors.glassBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ThemeColors.terminalGreen.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: ThemeColors.terminalGreen.withValues(alpha: 0.1), blurRadius: 20),
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
                        boxShadow: [BoxShadow(color: ThemeColors.terminalGreen.withValues(alpha: 0.3), blurRadius: 10)],
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
                            child: Text(address, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, overflow: TextOverflow.ellipsis)),
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
                                  color: ThemeColors.neonPurple.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white10,
                              backgroundImage: user?.profilePhotoPath != null && File(user!.profilePhotoPath!).existsSync()
                                  ? FileImage(File(user.profilePhotoPath!)) 
                                  : null,
                              child: user?.profilePhotoPath == null || !File(user!.profilePhotoPath!).existsSync()
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
                            begin: const Offset(1, 1), end: const Offset(1.2, 1.2),
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
                          const Text('Neural node active,', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
                          Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_tethering, color: ThemeColors.neonCyan, size: 14),
                    const SizedBox(width: 6),
                    Text(isConnected ? "P2P LIVE" : "IDLE", style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
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
          child: GlowSphere(color: ThemeColors.neonPurple.withValues(alpha: 0.15), size: 400),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).move(duration: const Duration(seconds: 5), begin: const Offset(0, 0), end: const Offset(50, 50)),
        Positioned(
          bottom: -150,
          right: -50,
          child: GlowSphere(color: ThemeColors.neonCyan.withValues(alpha: 0.15), size: 500),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).move(duration: const Duration(seconds: 7), begin: const Offset(0, 0), end: const Offset(-50, -30)),
      ],
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
                if (result != null) _processRemoteSdp(context, result);
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
          backgroundColor: ThemeColors.darkBg.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ThemeColors.neonPink, width: 1.5),
          ),
          title: const Text("DATA INJECTION", style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 16)),
          content: TextField(
            controller: textController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: "PASTE REMOTE SDP STREAM...",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
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

  void _processRemoteSdp(BuildContext context, String sdp) async {
    final decoded = await SdpCompressor.decode(sdp);
    final Map<String, dynamic> sdpMap = jsonDecode(decoded);
    final type = sdpMap["type"];

    if (type == "offer") {
      Get.to(() => NeuralHandshakeOverlay(isReceiving: true), opaque: false);
      controller.handleRemoteSdp(sdp);
    } else {
      Get.to(() => NeuralHandshakeOverlay(isCompleting: true), opaque: false);
      controller.handleRemoteSdp(sdp);
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Widget trailing;
  final VoidCallback onPressed;

  const _QuickActionButton({required this.label, required this.icon, required this.color, required this.trailing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
