import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../features/connection/controller/connection_controller.dart';
import '../utils/theme_colors.dart';
import 'cyber_button.dart';

class IncomingCallDialog extends StatelessWidget {
  const IncomingCallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConnectionController>();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: ThemeColors.neonCyan.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: ThemeColors.neonCyan.withValues(alpha: 0.2), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColors.neonCyan.withValues(alpha: 0.1),
                ),
                child: Obx(() => Icon(
                  controller.isVideoCall.value ? Icons.videocam : Icons.call,
                  color: ThemeColors.neonCyan,
                  size: 40,
                )),
              ),
              const SizedBox(height: 30),
              const Text(
                "INCOMING TRANSMISSION",
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Obx(() => Text(
                controller.remoteCallerName.value,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
                textAlign: TextAlign.center,
              )),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.redAccent,
                    onTap: () => controller.rejectCall(),
                  ),
                  _buildActionButton(
                    icon: Icons.check,
                    color: ThemeColors.terminalGreen,
                    onTap: () => controller.acceptCall(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
