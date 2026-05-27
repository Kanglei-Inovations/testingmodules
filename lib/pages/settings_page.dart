import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../features/connection/controller/settings_controller.dart';
import '../utils/theme_colors.dart';

import '../data/collections/stun_collection.dart';
import '../widgets/cyber_button.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.darkBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      _buildNetworkStatusCard(),
                      const SizedBox(height: 25),
                      _buildStunManager(context),
                      const SizedBox(height: 25),
                      _buildWebRtcPanel(),
                      const SizedBox(height: 25),
                      _buildEncryptionPanel(),
                      const SizedBox(height: 25),
                      _buildStoragePanel(),
                      const SizedBox(height: 40),
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

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: 200,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ThemeColors.neonCyan.withOpacity(0.05),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: const Duration(seconds: 5), begin: const Offset(1, 1), end: const Offset(1.5, 1.5)),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SYSTEM CONFIG",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3),
              ),
              Text(
                "NEURAL NODE CONTROL CENTER",
                style: TextStyle(color: ThemeColors.neonCyan, fontSize: 8, letterSpacing: 1.5),
              ),
            ],
          ),
          const Spacer(),
          _buildPulseIndicator(),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ThemeColors.terminalGreen,
        boxShadow: [BoxShadow(color: ThemeColors.terminalGreen, blurRadius: 10)],
      ),
    ).animate(onPlay: (c) => c.repeat()).scale(duration: const Duration(seconds: 1), begin: const Offset(1, 1), end: const Offset(1.3, 1.3)).fadeOut();
  }

  Widget _buildNetworkStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ThemeColors.neonCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SMART NETWORK MODE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              Obx(() => Switch(
                value: controller.smartNetworkMode.value,
                onChanged: controller.toggleSmartMode,
                activeColor: ThemeColors.neonCyan,
              )),
            ],
          ),
          const Divider(color: Colors.white10),
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: ThemeColors.neonCyan, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() => Text(
                  "ACTIVE STUN: ${controller.activeStunUrls.isNotEmpty ? controller.activeStunUrls.first.replaceAll("stun:", "") : "GATHERING..."}",
                  style: const TextStyle(color: ThemeColors.neonCyan, fontSize: 10, fontFamily: 'monospace'),
                )),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildStunManager(BuildContext context) {
    return _SettingsSection(
      title: "STUN PROTOCOL NODES",
      icon: Icons.hub_rounded,
      children: [
        Obx(() => Column(
          children: controller.stunServers.map((server) {
            return _StunTile(
              server: server,
              onDelete: () => controller.deleteStun(server.id),
              onToggle: (val) => controller.toggleStun(server, val!),
            );
          }).toList(),
        )),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _CyberOutlineButton(
                label: "ADD PROTOCOL NODE",
                icon: Icons.add_link_rounded,
                onPressed: () => _showAddStunDialog(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CyberOutlineButton(
                label: "RUN DIAGNOSTICS",
                icon: Icons.speed_rounded,
                onPressed: () => controller.runStunSpeedTest(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddStunDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.darkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ThemeColors.neonCyan),
        ),
        title: const Text("NEW STUN NODE", style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: "stun:example.com:3478",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          CyberButton(
            label: "ESTABLISH",
            color: ThemeColors.neonCyan,
            onPressed: () {
              if (textController.text.isNotEmpty) {
                controller.addStun(textController.text.trim());
                Get.back();
              }
            },
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildWebRtcPanel() {
    return _SettingsSection(
      title: "WEBRTC ENGINE",
      icon: Icons.settings_input_component_rounded,
      children: [
        _buildSliderSetting("TRANSFER CHUNK SIZE", controller.chunkSize, 4096, 65536, "KB"),
        _buildSliderSetting("IMAGE COMPRESSION", controller.compressionQuality, 10, 100, "%"),
        _buildToggleSetting("LOCAL DISCOVERY", controller.localDiscovery),
        _buildToggleSetting("IPV6 PROTOCOL", controller.ipv6Enabled),
      ],
    );
  }

  Widget _buildEncryptionPanel() {
    return _SettingsSection(
      title: "ENCRYPTION & IDENTITY",
      icon: Icons.security_rounded,
      children: [
        _buildToggleSetting("END-TO-END ENCRYPTION", controller.encryptionEnabled),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("NODE IDENTITY HASH", style: TextStyle(color: Colors.white30, fontSize: 9)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Obx(() => Text(controller.devicePeerId.value, style: const TextStyle(color: ThemeColors.neonPurple, fontWeight: FontWeight.bold))),
                  const Spacer(),
                  const Icon(Icons.copy_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoragePanel() {
    return _SettingsSection(
      title: "STORAGE & OPTIMIZATION",
      icon: Icons.storage_rounded,
      children: [
        _CyberOutlineButton(label: "CLEAR DATA CACHE", icon: Icons.delete_sweep_rounded, color: Colors.redAccent, onPressed: () {}),
        const SizedBox(height: 10),
        _CyberOutlineButton(label: "OPTIMIZE DATABASE", icon: Icons.auto_fix_high_rounded, onPressed: () {}),
      ],
    );
  }

  Widget _buildSliderSetting(String label, RxInt value, double min, double max, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Obx(() => Text("${value.value} $unit", style: const TextStyle(color: ThemeColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Obx(() => Slider(
          value: value.value.toDouble(),
          min: min,
          max: max,
          activeColor: ThemeColors.neonCyan,
          inactiveColor: Colors.white10,
          onChanged: (val) => value.value = val.toInt(),
        )),
      ],
    );
  }

  Widget _buildToggleSetting(String label, RxBool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Obx(() => Switch(
          value: value.value,
          onChanged: (val) => value.value = val,
          activeColor: ThemeColors.neonPurple,
        )),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white30, size: 16),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeColors.glassBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}

class _StunTile extends StatelessWidget {
  final StunCollection server;
  final VoidCallback onDelete;
  final Function(bool?) onToggle;

  const _StunTile({required this.server, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    String status = "UNKNOWN";
    Color statusColor = Colors.white24;
    if (server.latency != null) {
      if (server.latency! < 150) {
        status = "EXCELLENT";
        statusColor = ThemeColors.terminalGreen;
      } else if (server.latency! < 400) {
        status = "GOOD";
        statusColor = Colors.amber;
      } else if (server.latency! < 9000) {
        status = "SLOW";
        statusColor = Colors.orange;
      } else {
        status = "OFFLINE";
        statusColor = Colors.redAccent;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: server.isEnabled,
            onChanged: onToggle,
            activeColor: ThemeColors.neonCyan,
            checkColor: Colors.black,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.url.replaceAll("stun:", ""),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 2),
                Text(
                  "$status ${server.latency != null && server.latency! < 9000 ? '(${server.latency}ms)' : ''}",
                  style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 18),
          ),
        ],
      ),
    );
  }
}

class _CyberOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _CyberOutlineButton({required this.label, required this.icon, required this.onPressed, this.color = ThemeColors.neonCyan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
