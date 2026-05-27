import 'dart:math';
import 'package:flutter/material.dart';

import '../utils/theme_colors.dart';

class MeshBackground extends StatefulWidget {
  const MeshBackground({super.key});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Node> nodes = List.generate(20, (index) => Node());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: MeshPainter(nodes, _controller.value),
          child: Container(),
        );
      },
    );
  }
}

class Node {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double vx = (Random().nextDouble() - 0.5) * 0.002;
  double vy = (Random().nextDouble() - 0.5) * 0.002;

  void update() {
    x += vx;
    y += vy;
    if (x < 0 || x > 1) vx *= -1;
    if (y < 0 || y > 1) vy *= -1;
  }
}

class MeshPainter extends CustomPainter {
  final List<Node> nodes;
  final double animationValue;

  MeshPainter(this.nodes, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ThemeColors.neonCyan.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    final nodePaint = Paint()
      ..color = ThemeColors.neonPurple.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (var node in nodes) {
      node.update();
      final pos = Offset(node.x * size.width, node.y * size.height);
      canvas.drawCircle(pos, 2, nodePaint);

      for (var other in nodes) {
        final otherPos = Offset(other.x * size.width, other.y * size.height);
        final distance = (pos - otherPos).distance;
        if (distance < 150) {
          paint.color = ThemeColors.neonCyan.withValues(
            alpha: (1 - distance / 150) * 0.2,
          );
          canvas.drawLine(pos, otherPos, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) => true;
}
