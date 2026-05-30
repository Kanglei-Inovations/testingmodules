import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/connection_controller.dart';
import '../../../utils/theme_colors.dart';
import '../../../widgets/cyber_button.dart';
import 'dht_discovery_page.dart';

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
              title: "Manual (QR / Link)",
              subtitle: "Create offer and share QR or link manually",
              icon: Icons.qr_code_2_rounded,
              isSelected: controller.discoveryMode.value == DiscoveryMode.manual,
              onTap: () => controller.discoveryMode.value = DiscoveryMode.manual,
            )),
            const SizedBox(height: 12),
            Obx(() => _DiscoveryModeCard(
              title: "DHT Auto Discovery",
              subtitle: "Automatically discover peers on DHT network",
              icon: Icons.hub_outlined,
              isSelected: controller.discoveryMode.value == DiscoveryMode.dht,
              onTap: () => controller.discoveryMode.value = DiscoveryMode.dht,
            )),
            const SizedBox(height: 12),
            Obx(() => _DiscoveryModeCard(
              title: "Nearby Discovery (LAN)",
              subtitle: "Find peers on the same local network",
              icon: Icons.wifi_tethering_rounded,
              isSelected: controller.discoveryMode.value == DiscoveryMode.lan,
              onTap: () => controller.discoveryMode.value = DiscoveryMode.lan,
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
                if (controller.discoveryMode.value == DiscoveryMode.manual) {
                  controller.isSdpReady.value = false;
                  controller.createOffer();
                  _showManualShareSheet(context, controller);
                } else {
                  controller.startDhtDiscovery();
                  Get.to(() => const DhtDiscoveryPage());
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

  void _showManualShareSheet(BuildContext context, ConnectionController controller) {
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
                  onPressed: () {
                    Get.back();
                    Get.to(() => QrGeneratorScreen(sdpData: sdp));
                  },
                  fullWidth: true,
                ),
                const SizedBox(height: 15),
                CyberButton(
                  label: "COPY SECURE LINK",
                  color: ThemeColors.neonPurple,
                  onPressed: () {
                    // Implement copy logic or share logic
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
          color: isSelected ? ThemeColors.neonPurple.withOpacity(0.05) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? ThemeColors.neonPurple : Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? ThemeColors.neonPurple.withOpacity(0.1) : Colors.white.withOpacity(0.05),
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
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
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
