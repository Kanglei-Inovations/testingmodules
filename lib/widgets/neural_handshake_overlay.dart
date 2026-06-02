import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../features/connection/controller/connection_controller.dart';
import '../utils/theme_colors.dart';
import '../widgets/cyber_button.dart';
import '../pages/qr_generator_screen.dart';
import '../pages/qr_scanner_screen.dart';
import '../utils/sdp_compressor.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class NeuralHandshakeOverlay extends StatelessWidget {
  final bool isReceiving; // Device B side
  final bool isCompleting; // Device A finalizing side
  final ConnectionController controller = Get.find();

  NeuralHandshakeOverlay({super.key, this.isReceiving = false, this.isCompleting = false});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        body: SafeArea(
          child: Obx(() {
            final hStage = controller.handshakeStage.value;
            final rStage = controller.receiveStage.value;
            final cStage = controller.completionStage.value;
            
            int stageIndex = 0;
            bool isComplete = false;
            dynamic currentStage;

            if (isCompleting) {
              stageIndex = cStage.index;
              isComplete = cStage == CompletionStage.ready;
              currentStage = cStage;
            } else if (isReceiving) {
              stageIndex = rStage.index;
              isComplete = rStage == ReceiveStage.ready;
              currentStage = rStage;
            } else {
              stageIndex = hStage.index;
              isComplete = hStage == HandshakeStage.ready || hStage == HandshakeStage.waitingForResponse;
              currentStage = hStage;
            }

            return Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const Spacer(),
                  _buildNeuralAnimation(stageIndex, isComplete),
                  const SizedBox(height: 40),
                  _buildStatusText(currentStage),
                  const SizedBox(height: 30),
                  _buildProgressPipeline(stageIndex),
                  const Spacer(),
                  if (isComplete || hStage == HandshakeStage.waitingForResponse) 
                    _buildActionArea(context) 
                  else 
                    _buildLoadingFooter(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String sub = "INITIALIZING P2P TUNNEL";
    if (isReceiving) sub = "SYNCHRONIZING REMOTE NODE";
    if (isCompleting) sub = "ESTABLISHING NEURAL LINK";

    return Column(
      children: [
        const Text(
          "NEURAL LINK HANDSHAKE",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
        ).animate().fadeIn().slideY(begin: -0.2),
        Text(
          sub,
          style: const TextStyle(color: ThemeColors.neonCyan, fontSize: 8, letterSpacing: 2),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildNeuralAnimation(int stageIndex, bool isComplete) {
    final hStage = controller.handshakeStage.value;
    final rStage = controller.receiveStage.value;
    final cStage = controller.completionStage.value;
    
    final isFailed = hStage == HandshakeStage.none || rStage == ReceiveStage.failed || cStage == CompletionStage.failed;
    final color = isFailed ? Colors.redAccent : (isComplete ? ThemeColors.terminalGreen : ThemeColors.neonCyan);
    final isWaiting = controller.handshakeStage.value == HandshakeStage.waitingForResponse;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse Rings
        ...List.generate(3, (index) => Container(
          width: 120 + (index * 40.0),
          height: 120 + (index * 40.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: (isWaiting ? ThemeColors.neonPink : color).withOpacity(0.1 - (index * 0.02)), width: 1),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: Duration(seconds: 2 + index), begin: const Offset(1, 1), end: const Offset(1.2, 1.2))),
        
        // Radar Sweep for Waiting State
        if (isWaiting && !isFailed)
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: RadarSweepPainter(ThemeColors.neonPink.withOpacity(0.2)),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: const Duration(seconds: 4)),

        // Core Node
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Icon(
            isFailed ? Icons.error_outline : (isComplete ? Icons.bolt_rounded : (isWaiting ? Icons.radar : Icons.hub_outlined)),
            color: color,
            size: 40,
          ),
        ).animate(onPlay: (c) => c.repeat()).rotate(duration: const Duration(seconds: 5)),
        
        if (!isComplete && !isWaiting && !isFailed)
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: stageIndex / 5.0,
              strokeWidth: 2,
              color: color,
            ),
          ),

        // Neural Scan Particles
        if (isWaiting && !isFailed)
          ...List.generate(10, (i) => Positioned(
            left: 80.0 + (i * 10.0 % 40.0),
            top: 80.0 + (i * 15.0 % 40.0),
            child: Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(color: ThemeColors.neonPink, shape: BoxShape.circle),
            ),
          ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: -100, duration: Duration(seconds: 1 + i % 2)).fadeOut()),
      ],
    );
  }

  Widget _buildStatusText(dynamic stage) {
    String text = "CALIBRATING...";
    Color textColor = Colors.white;

    if (stage is HandshakeStage) {
      switch (stage) {
        case HandshakeStage.initializing: text = "🌐 INITIALIZING LOCAL NODE..."; break;
        case HandshakeStage.discovering: text = "🛰️ DISCOVERING NETWORK ROUTE..."; break;
        case HandshakeStage.analyzing: text = "🔍 ANALYZING NETWORK PATHS..."; break;
        case HandshakeStage.generating: text = "🧠 GENERATING NODE IDENTITY..."; break;
        case HandshakeStage.ready: text = "🟢 NODE IDENTITY ACTIVE"; break;
        case HandshakeStage.waitingForResponse: text = "🛰️ WAITING FOR RESPONSE STREAM..."; break;
        default: break;
      }
    } else if (stage is ReceiveStage) {
      switch (stage) {
        case ReceiveStage.receiving: text = "📥 RECEIVING REMOTE NODE STREAM..."; break;
        case ReceiveStage.validating: text = "🔎 VALIDATING REMOTE NODE..."; break;
        case ReceiveStage.generatingResponse: text = "🛰️ GENERATING RESPONSE STREAM..."; break;
        case ReceiveStage.preparingTunnel: text = "🔄 PREPARING SYNC TUNNEL..."; break;
        case ReceiveStage.ready: text = "🟢 RESPONSE STREAM READY"; break;
        case ReceiveStage.failed: 
          text = "❌ NEURAL HANDSHAKE FAILED"; 
          textColor = Colors.redAccent;
          break;
        default: break;
      }
    } else if (stage is CompletionStage) {
      switch (stage) {
        case CompletionStage.verifying: text = "🛰️ VALIDATING RESPONSE..."; break;
        case CompletionStage.synchronizing: text = "🔄 SYNCHRONIZING NETWORK PATHS..."; break;
        case CompletionStage.establishing: text = "🔗 ESTABLISHING P2P TUNNEL..."; break;
        case CompletionStage.openingChannel: text = "⚡ OPENING DATA CHANNEL..."; break;
        case CompletionStage.ready: 
          text = "🟢 NEURAL LINK ESTABLISHED";
          break;
        case CompletionStage.failed: 
          text = "❌ LINK FINALIZATION FAILED"; 
          textColor = Colors.redAccent;
          break;
        default: break;
      }
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: textColor, fontFamily: 'monospace', fontSize: 12, letterSpacing: 1),
    ).animate(key: ValueKey(text)).fadeIn().slideX(begin: 0.1);
  }

  Widget _buildProgressPipeline(int stageIndex) {
    List<String> stages = ["INIT", "DISCOVER", "ANALYZE", "GENERATE", "READY"];
    if (isReceiving) stages = ["RECEIVE", "VALIDATE", "RESPOND", "PREPARE", "READY"];
    if (isCompleting) stages = ["VERIFY", "CONNECT", "SYNC", "FINAL", "READY"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(stages.length, (index) {
        final isActive = index < stageIndex;
        final color = isActive ? ThemeColors.neonCyan : Colors.white10;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(height: 5),
                Text(stages[index], style: TextStyle(color: color, fontSize: 5, fontWeight: FontWeight.bold)),
              ],
            ),
            if (index < stages.length - 1)
              Container(width: 25, height: 1, margin: const EdgeInsets.symmetric(horizontal: 4), color: color),
          ],
        );
      }),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    if (isCompleting) {
      if (controller.completionStage.value == CompletionStage.ready) {
        return CyberButton(
          label: "ENTER NEURAL CHANNEL",
          color: ThemeColors.terminalGreen,
          onPressed: () => Get.back(),
          fullWidth: true,
        ).animate().fadeIn();
      } else if (controller.completionStage.value == CompletionStage.failed) {
        return CyberButton(
          label: "CLOSE & RESTART",
          color: Colors.redAccent,
          onPressed: () => Get.back(),
          fullWidth: true,
        ).animate().fadeIn();
      } else {
        return _buildLoadingFooter();
      }
    }

    if (isReceiving) {
      if (controller.receiveStage.value == ReceiveStage.failed) {
        return CyberButton(
          label: "CLOSE",
          color: Colors.redAccent,
          onPressed: () => Get.back(),
          fullWidth: true,
        ).animate().fadeIn();
      }
      return _buildDeviceBActionArea(context);
    }

    // Device A logic
    return _buildDeviceAActionArea(context);
  }

  Widget _buildDeviceAActionArea(BuildContext context) {
    final hStage = controller.handshakeStage.value;
    final sdp = controller.localSdp.value;

    return Column(
      children: [
        if (hStage == HandshakeStage.ready) ...[
          Row(
            children: [
              Expanded(
                child: CyberButton(
                  label: "GENERATE QR",
                  color: ThemeColors.neonCyan,
                  onPressed: () {
                    Get.to(() => QrGeneratorScreen(sdpData: sdp));
                    controller.handshakeStage.value = HandshakeStage.waitingForResponse;
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: CyberButton(
                  label: "SHARE LINK",
                  color: ThemeColors.neonPurple,
                  onPressed: () async {
                    final encoded = await SdpCompressor.encode(sdp);
                    Share.share(encoded);
                    controller.handshakeStage.value = HandshakeStage.waitingForResponse;
                  },
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.2),
        ],
        if (hStage == HandshakeStage.waitingForResponse) ...[
          const SizedBox(height: 20),
          _buildResponseInputSection(context),
        ],
        const SizedBox(height: 20),
        TextButton(onPressed: () => Get.back(), child: const Text("CANCEL HANDSHAKE", style: TextStyle(color: Colors.white24, fontSize: 10))),
      ],
    );
  }

  Widget _buildDeviceBActionArea(BuildContext context) {
    final sdp = controller.localSdp.value;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), 
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: ThemeColors.neonPink.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_outlined, color: ThemeColors.neonPink, size: 18),
                  SizedBox(width: 10),
                  Text("RESPONSE STREAM GENERATED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Device B has created the return connection signal.\nTo finalize the link, this must be sent back to Device A.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ],
          ),
        ).animate().fadeIn(),
        
        Row(
          children: [
            Expanded(
              child: CyberButton(
                label: "SHOW RESPONSE QR",
                color: ThemeColors.neonCyan,
                onPressed: () => Get.to(() => QrGeneratorScreen(sdpData: sdp)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: CyberButton(
                label: "SHARE RESPONSE LINK",
                color: ThemeColors.neonPurple,
                onPressed: () async {
                  final encoded = await SdpCompressor.encode(sdp);
                  Share.share(encoded);
                },              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 20),
        TextButton(onPressed: () => Get.back(), child: const Text("CLOSE OVERLAY", style: TextStyle(color: Colors.white24, fontSize: 10))),
      ],
    );
  }

  Widget _buildResponseInputSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.glassBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.neonPink.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: ThemeColors.neonPink.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text("📥 RECEIVE RESPONSE STREAM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CyberButton(
                  label: "SCAN QR",
                  color: ThemeColors.neonCyan,
                  onPressed: () async {
                    final result = await Get.to<String>(() => const QrScannerScreen());
                    if (result != null) {
                      _finalizeDeviceALink(context, result);
                    }
                  },
                  height: 45,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CyberButton(
                  label: "PASTE LINK",
                  color: ThemeColors.neonPink,
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      _finalizeDeviceALink(context, data.text!.trim());
                    } else {
                      Get.snackbar(
                        "INJECTION FAILED",
                        "CLIPBOARD IS EMPTY",
                        backgroundColor: Colors.redAccent.withOpacity(0.5),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  height: 45,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  void _finalizeDeviceALink(BuildContext context, String sdp) {
    controller.completionStage.value = CompletionStage.verifying;
    Get.off(() => NeuralHandshakeOverlay(isCompleting: true), opaque: false);
    controller.handleRemoteSdp(sdp);
  }

  Widget _buildLoadingFooter() {
    return Column(
      children: [
        const Text("NEURAL HANDSHAKE IN PROGRESS", style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 2)),
        const SizedBox(height: 10),
        LinearProgressIndicator(backgroundColor: Colors.white.withOpacity(0.05), color: ThemeColors.neonCyan),
      ],
    ).animate().fadeIn(delay: const Duration(seconds: 1));
  }
}

class RadarSweepPainter extends CustomPainter {
  final Color color;
  RadarSweepPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0), color],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
