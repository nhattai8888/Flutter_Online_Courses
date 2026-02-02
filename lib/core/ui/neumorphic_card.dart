import 'package:flutter/material.dart';

/// A simple reusable Neumorphic-style card to create soft 3D depth.
/// Use by wrapping content: `NeumorphicCard(child: ...)`.
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double elevation;

  const NeumorphicCard({
    Key? key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.color,
    this.elevation = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = color ?? theme.colorScheme.surface;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
                  // Light highlight (top-left)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.06),
                    offset: Offset(-elevation / 6, -elevation / 6),
                    blurRadius: elevation,
                  ),
                  // Dark shadow (bottom-right)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(elevation / 4, elevation / 4),
                    blurRadius: elevation,
                  ),
          ],
        ),
        child: child,
      ),
    );
  }
}
