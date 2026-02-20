import 'package:flutter/material.dart';

class InteractiveScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final double scaleUp;
  final BorderRadius? borderRadius;

  const InteractiveScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.scaleUp = 1.02,
    this.borderRadius,
  });

  @override
  State<InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends State<InteractiveScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double scale = 1.0;

          if (_controller.value > 0) {
            // Pressed state
            scale = 1.0 - (_controller.value * (1.0 - widget.scaleDown));
          } else if (_isHovered) {
            // Hover state
            scale = widget.scaleUp;
          }

          return Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (isHighlighted) {
                  if (isHighlighted) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                },
                onHover: (isHovering) {
                  setState(() => _isHovered = isHovering);
                },
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
