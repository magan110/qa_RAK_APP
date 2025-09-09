import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final bool animated;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final backButton = Container(
      width: size ?? 40,
      height: size ?? 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: color ?? Colors.blue.shade700,
          size: (size ?? 40) * 0.5,
        ),
        padding: EdgeInsets.zero,
        splashRadius: (size ?? 40) * 0.6,
      ),
    );

    if (!animated) return backButton;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: Opacity(opacity: value, child: child),
          ),
        );
      },
      child: backButton,
    );
  }
}
