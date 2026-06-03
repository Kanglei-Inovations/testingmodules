import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../features/connection/controller/connection_controller.dart';
import '../utils/theme_colors.dart';

class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConnectionController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (Full Screen)
          Obx(() {
            if (controller.isInCall.value && controller.remoteStream.value != null && controller.isVideoCall.value) {
              return SizedBox.expand(
                child: RTCVideoView(
                  controller.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              );
            } else {
              return Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF1A1A2E), Colors.black],
                    radius: 0.8,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeColors.neonCyan.withValues(alpha: 0.05),
                          border: Border.all(color: ThemeColors.neonCyan.withValues(alpha: 0.3), width: 2),
                          boxShadow: [BoxShadow(color: ThemeColors.neonCyan.withValues(alpha: 0.2), blurRadius: 30)],
                        ),
                        child: const Icon(Icons.person, color: ThemeColors.neonCyan, size: 60),
                      ),
                      const SizedBox(height: 30),
                      Obx(() => Text(
                        controller.remoteCallerName.value,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                      )),
                      const SizedBox(height: 10),
                      Obx(() => Text(
                        controller.isInCall.value ? "SECURE AUDIO CHANNEL ACTIVE" : "CALLING...",
                        style: const TextStyle(color: ThemeColors.terminalGreen, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold),
                      )),
                    ],
                  ),
                ),
              );
            }
          }),

          // Local Video (PIP)
          Obx(() {
            if (controller.isInCall.value && controller.localStream.value != null && controller.isVideoCall.value) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: 20,
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: ThemeColors.neonPurple, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: RTCVideoView(
                      controller.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Call Controls (Bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Obx(() => _buildControlButton(
                        controller.isMuted.value ? Icons.mic_off : Icons.mic_none, 
                        controller.isMuted.value ? ThemeColors.neonPink : Colors.white, 
                        () => controller.toggleMute()
                      )),
                      Obx(() => _buildControlButton(
                        controller.isCameraOff.value ? Icons.videocam_off_outlined : Icons.videocam_outlined, 
                        controller.isCameraOff.value ? ThemeColors.neonPink : Colors.white, 
                        () => controller.toggleCamera()
                      )),
                      _buildControlButton(Icons.call_end, Colors.redAccent, () => controller.endCall(), isLarge: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback onTap, {bool isLarge = false}) {
    final size = isLarge ? 64.0 : 48.0;
    final iconSize = isLarge ? 30.0 : 22.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLarge ? color : Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: isLarge ? color : Colors.white24),
          boxShadow: isLarge ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15)] : [],
        ),
        child: Icon(icon, color: isLarge ? Colors.white : color, size: iconSize),
      ),
    );
  }
}
