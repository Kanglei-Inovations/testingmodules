import 'package:flutter/material.dart';

class CyberButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool fullWidth;
  final double height;

  const CyberButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.fullWidth = false,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
