import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../features/connection/controller/connection_controller.dart';
import '../utils/theme_colors.dart';
import '../widgets/cyber_button.dart';
import '../widgets/neural_handshake_overlay.dart';
import 'lan_discovery_page.dart';

class CreateConnectPage extends StatelessWidget {
  const CreateConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConnectionController>();

    return Scaffold(
      backgroundColor: ThemeColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "CREATE / CONNECT",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CHOOSE DISCOVERY MODE",
              style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 20),
            Obx(() => _DiscoveryModeCard(
              title: "Manual QR / Link",
              subtitle: "Create offer and share QR or link manually",
              icon: Icons.qr_code_2_rounded,
              isSelected: controller.discoveryMode.value == DiscoveryMode.manual,
              onTap: () => controller.discoveryMode.value = DiscoveryMode.manual,
            )),
            const SizedBox(height: 12),
            Obx(() => _DiscoveryModeCard(
              title: "Nearby Discovery (LAN)",
              subtitle: "Automatically discover peers on local network",
              icon: Icons.wifi_tethering_rounded,
              isSelected: controller.discoveryMode.value == DiscoveryMode.lan,
              onTap: () => controller.discoveryMode.value = DiscoveryMode.lan,
            )),
            const SizedBox(height: 12),
            Obx(() => _DiscoveryModeCard(
              title: "Global Discovery",
              subtitle: "Connect across different networks (Coming Soon)",
              icon: Icons.public_rounded,
              isSelected: controller.discoveryMode.value == DiscoveryMode.global,
              onTap: () => {}, // controller.discoveryMode.value = DiscoveryMode.global,
            )),
            const SizedBox(height: 40),
            const Text(
              "NETWORK TRANSPORT",
              style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 20),
            _NetworkTransportCard(),
            const Spacer(),
            CyberButton(
              label: "START DISCOVERY",
              color: ThemeColors.neonPurple,
              onPressed: () {
                print("[DEBUG-UI] 'START DISCOVERY' tapped. Selected mode: ${controller.discoveryMode.value}");
                if (controller.discoveryMode.value == DiscoveryMode.manual) {
                  print("[DEBUG-UI] Initiating Manual mode (QR/Link)...");
                  controller.isSdpReady.value = false;
                  controller.createOffer();
                  Get.off(() => NeuralHandshakeOverlay(), opaque: false);
                } else if (controller.discoveryMode.value == DiscoveryMode.lan) {
                  print("[DEBUG-UI] Initiating LAN Discovery...");
                  controller.startLanDiscovery();
                  Get.to(() => const LanDiscoveryPage());
                }
              },
              fullWidth: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


class _DiscoveryModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiscoveryModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ThemeColors.neonPurple.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? ThemeColors.neonPurple : Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? ThemeColors.neonPurple.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? ThemeColors.neonPurple : Colors.white38, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: ThemeColors.terminalGreen, size: 20)
            else
              const Icon(Icons.chevron_right, color: Colors.white10, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NetworkTransportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white38, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Auto (STUN + TURN Fallback)", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text("Use STUN for direct connection and TURN if needed", style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white10, size: 20),
        ],
      ),
    );
  }
}
