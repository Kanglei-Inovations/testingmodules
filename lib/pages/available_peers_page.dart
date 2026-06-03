import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/network/discovery_manager.dart';
import '../features/connection/controller/connection_controller.dart';
import '../utils/theme_colors.dart';
import '../widgets/neural_handshake_overlay.dart';

class AvailablePeersPage extends StatelessWidget {
  const AvailablePeersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConnectionController>();
    final discovery = Get.find<DiscoveryManager>();

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
          "AVAILABLE PEERS",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white38),
            onPressed: () => discovery.startDiscovery(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Select a peer to connect",
              style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Obx(() {
                if (discovery.discoveredNodes.isEmpty) {
                  return const Center(child: Text("No peers found yet...", style: TextStyle(color: Colors.white24)));
                }
                return ListView.builder(
                  itemCount: discovery.discoveredNodes.length,
                  itemBuilder: (context, index) {
                    final peerId = discovery.discoveredNodes.keys.elementAt(index);
                    final peerData = discovery.discoveredNodes[peerId]!;
                    final ip = peerData["ip"]!;
                    final peerName = peerData["name"] ?? peerId;
                    
                    // Mock signal strength for demo
                    final signalStr = index == 0 ? "Strong Signal" : "Medium Signal";
                    final signalIcon = index == 0 ? Icons.signal_cellular_alt : Icons.network_cell;
                    final signalColor = index == 0 ? ThemeColors.terminalGreen : Colors.orangeAccent;

                    return _PeerListCard(
                      peerName: peerName,
                      peerId: peerId,
                      signalText: signalStr,
                      signalIcon: signalIcon,
                      signalColor: signalColor,
                      onConnect: () {
                         print("[DEBUG-UI] 'CONNECT' tapped for peer: $peerName ($peerId) at IP: $ip");
                         controller.connectToPeer(peerId, ip);
                         Get.snackbar("LINK INITIATED", "Attempting secure handshake with $peerName");
                         Get.to(() => NeuralHandshakeOverlay(), opaque: false);
                      },
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              "Tip: Strong signal gives better connection",
              style: TextStyle(color: Colors.white24, fontSize: 9),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PeerListCard extends StatelessWidget {
  final String peerName;
  final String peerId;
  final String signalText;
  final IconData signalIcon;
  final Color signalColor;
  final VoidCallback onConnect;

  const _PeerListCard({
    required this.peerName,
    required this.peerId,
    required this.signalText,
    required this.signalIcon,
    required this.signalColor,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: ThemeColors.neonPurple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeColors.neonPurple.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.hub_outlined, color: ThemeColors.neonPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peerName,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  peerId,
                  style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(signalIcon, color: signalColor, size: 10),
                    const SizedBox(width: 4),
                    Text(signalText, style: TextStyle(color: Colors.white38, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(

            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: ThemeColors.terminalGreen,
              side: const BorderSide(color: ThemeColors.terminalGreen, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 30),
              elevation: 0,
            ),
            child: const Text("CONNECT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
