import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../features/connection/controller/settings_controller.dart';
import '../utils/theme_colors.dart';
import '../widgets/glow_sphere.dart';
import 'user_setup_page.dart';
import 'main_hub.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DatabaseService _db = Get.find();
  final SettingsController _settings = Get.find();

  String _status = "INITIALIZING NEURAL CORE...";
  int _bootPhase = 0; // 0-6
  double _progress = 0.0;
  // bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    _startNeuralBoot();
  }

  Future<void> _startNeuralBoot() async {
    // PHASE 1: CORE INIT
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _bootPhase = 1;
      _progress = 0.15;
    });

    // PHASE 2: STUN REGISTRY
    setState(() {
      _status = "LOADING STUN REGISTRY...";
      _bootPhase = 2;
      _progress = 0.30;
    });
    await Future.delayed(const Duration(milliseconds: 1000));

    // PHASE 3: LATENCY ANALYSIS (REAL)
    setState(() {
      _status = "ANALYZING NETWORK LATENCY...";
      _bootPhase = 3;
      _progress = 0.45;
    });
    await _settings.performNeuralBootSync();
    setState(() => _progress = 0.65);

    // PHASE 4: ROUTE OPTIMIZATION
    setState(() {
      _status = "SELECTING OPTIMAL PATHS...";
      _bootPhase = 4;
      _progress = 0.80;
    });
    await Future.delayed(const Duration(milliseconds: 1200));

    // PHASE 5: NODE VERIFICATION
    setState(() {
      _status = "VERIFYING NODE IDENTITY...";
      _bootPhase = 5;
      _progress = 0.95;
    });
    final user = await _db.getUser();
    await Future.delayed(const Duration(milliseconds: 1000));

    // FINAL: ACTIVATE
    setState(() {
      _status = "DECENTRALIZED NETWORK READY";
      _bootPhase = 6;
      _progress = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 800));

    // Cinematic Flash before transition
    // setState(() => _showFlash = true);
    // await Future.delayed(const Duration(milliseconds: 200));

    if (user != null) {
      Get.offAllNamed('/hub');
    } else {
      Get.off(() => const UserSetupPage(), transition: Transition.fade, duration: const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.darkBg,
      body: Stack(
        children: [
          _buildCinematicBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildAnimatedLogo(),
                  const Spacer(),
                  if (_bootPhase == 3 || _bootPhase == 4) _buildLiveLatencyGrid(),
                  const Spacer(),
                  _buildBootTerminal(),
                  const SizedBox(height: 30),
                  _buildSegmentedPipeline(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          // if (_showFlash)
          //   Positioned.fill(
          //     child: Container(color: Colors.white).animate().fadeOut(duration: const Duration(milliseconds: 300)),
          //   ),
        ],
      ),
    );
  }

  Widget _buildCinematicBackground() {
    return Stack(
      children: [
        // Mesh Gradients
        Positioned(
          top: -100,
          left: -100,
          child: GlowSphere(color: ThemeColors.neonPurple.withOpacity(0.1), size: 400),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).move(duration: const Duration(seconds: 5), begin: const Offset(0, 0), end: const Offset(50, 50)),
        
        Positioned(
          bottom: -100,
          right: -100,
          child: GlowSphere(color: ThemeColors.neonCyan.withOpacity(0.1), size: 500),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).move(duration: const Duration(seconds: 7), begin: const Offset(0, 0), end: const Offset(-50, -50)),

        // Radar Sweep
        if (_bootPhase >= 3 && _bootPhase <= 4)
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ThemeColors.neonCyan.withOpacity(0.1)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 2,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [ThemeColors.neonCyan.withOpacity(0.5), Colors.transparent],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: const Duration(seconds: 3)),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(),
      ],
    );
  }

  Widget _buildAnimatedLogo() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ThemeColors.neonCyan, width: 2),
                boxShadow: [BoxShadow(color: ThemeColors.neonCyan.withOpacity(0.2), blurRadius: 20)],
              ),
              child: const Icon(Icons.hub_outlined, color: ThemeColors.neonCyan, size: 40),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: const Duration(seconds: 2), begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "NEURAL LINK",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
        ).animate().fadeIn(delay: 300.ms),
        const Text(
          "DECENTRALIZED NODE OS",
          style: TextStyle(color: ThemeColors.neonCyan, fontSize: 8, letterSpacing: 4),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildLiveLatencyGrid() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Obx(() {
        final stuns = _settings.stunServers.where((s) => s.isEnabled).toList();
        return ListView.builder(
          itemCount: stuns.length,
          itemBuilder: (context, index) {
            final s = stuns[index];
            final isTesting = _settings.currentTestingServer.value == s.url.replaceFirst("stun:", "");
            final latency = s.latency;
            
            Color color = Colors.white24;
            if (latency != null) {
              if (latency < 200) color = ThemeColors.terminalGreen;
              else if (latency < 500) color = Colors.amber;
              else color = Colors.redAccent;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isTesting ? ThemeColors.neonCyan : color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.url.replaceFirst("stun:", ""),
                      style: TextStyle(color: isTesting ? Colors.white : Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                  if (latency != null)
                    Text(
                      latency > 9000 ? "TIMEOUT" : "${latency}ms",
                      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  if (isTesting)
                    const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1, color: ThemeColors.neonCyan)),
                ],
              ),
            ).animate().fadeIn();
          },
        );
      }),
    );
  }

  Widget _buildBootTerminal() {
    return Column(
      children: [
        Text(
          _status,
          style: const TextStyle(color: ThemeColors.neonCyan, fontSize: 11, fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold),
        ).animate(key: ValueKey(_status)).fadeIn().slideX(begin: 0.1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${(_progress * 100).toInt()}%",
              style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              width: 150,
              height: 2,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 150 * _progress,
                decoration: BoxDecoration(
                  color: ThemeColors.neonCyan,
                  boxShadow: [BoxShadow(color: ThemeColors.neonCyan.withOpacity(0.5), blurRadius: 10)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentedPipeline() {
    final stages = ["CORE", "STUN", "LATENCY", "ROUTE", "NODE", "READY"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (index) {
        final isActive = index < _bootPhase;
        final isCurrent = index == _bootPhase - 1;
        final color = isActive ? ThemeColors.neonCyan : Colors.white10;

        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color,
                boxShadow: [if (isCurrent) BoxShadow(color: color, blurRadius: 10)],
              ),
            ).animate(onPlay: (c) => isCurrent ? c.repeat(reverse: true) : null).shimmer(duration: const Duration(seconds: 1)),
            const SizedBox(height: 8),
            Text(stages[index], style: TextStyle(color: color, fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        );
      }),
    );
  }
}
