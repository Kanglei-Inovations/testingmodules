import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/connection_controller.dart';
import '../../../utils/theme_colors.dart';
import '../../../widgets/cyber_button.dart';
import 'available_peers_page.dart';

class DhtDiscoveryPage extends StatefulWidget {
  const DhtDiscoveryPage({super.key});

  @override
  State<DhtDiscoveryPage> createState() => _DhtDiscoveryPageState();
}

class _DhtDiscoveryPageState extends State<DhtDiscoveryPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final controller = Get.find<ConnectionController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Simulate discovery for UI demo if needed, but normally it would be driven by the controller
    _startSimulatedDiscovery();
  }

  void _startSimulatedDiscovery() async {
    // In a real app, the controller would start the actual discovery
    // and update peersFound, checkedNodes etc.
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Get.to(() => const AvailablePeersPage());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          "DHT AUTO DISCOVERY",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: RadarPainter(_animationController.value),
                        size: const Size(280, 280),
                      );
                    },
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: ThemeColors.terminalGreen, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Discovering peers...",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const Text(
            "Scanning DHT network",
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          _buildStatsPanel(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: CyberButton(
              label: "CANCEL",
              color: Colors.white12,
              onPressed: () => Get.back(),
              fullWidth: true,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Peers Found", controller.peersFound.value.toString(), ThemeColors.terminalGreen),
          _buildStatItem("Checked Nodes", controller.checkedNodes.value.toString(), Colors.white70),
          _buildStatItem("Network", controller.networkStatus.value, ThemeColors.terminalGreen),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class RadarPainter extends CustomPainter {
  final double angle;
  RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = ThemeColors.terminalGreen.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw rings
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.75, ringPaint);
    canvas.drawCircle(center, radius * 0.5, ringPaint);
    canvas.drawCircle(center, radius * 0.25, ringPaint);

    // Draw sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          ThemeColors.terminalGreen.withOpacity(0.0),
          ThemeColors.terminalGreen.withOpacity(0.5),
        ],
        stops: const [0.0, 1.0],
        transform: GradientRotation(angle * 2 * pi - pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = sweepPaint);
    
    // Draw sweeping line
    final lineAngle = angle * 2 * pi - pi / 2;
    final lineEnd = Offset(center.dx + radius * cos(lineAngle), center.dy + radius * sin(lineAngle));
    canvas.drawLine(center, lineEnd, Paint()..color = ThemeColors.terminalGreen.withOpacity(0.8)..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => oldDelegate.angle != angle;
}
