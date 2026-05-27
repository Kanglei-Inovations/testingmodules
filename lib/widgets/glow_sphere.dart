import 'package:flutter/material.dart';

class GlowSphere extends StatelessWidget {
  final Color color;
  final double size;
  
  const GlowSphere({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}
