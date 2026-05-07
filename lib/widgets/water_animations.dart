import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/vapor_theme.dart';

class WaterRippleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? color;

  const WaterRippleButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
  });

  @override
  State<WaterRippleButton> createState() => _WaterRippleButtonState();
}

class _WaterRippleButtonState extends State<WaterRippleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class FloatingBubble extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const FloatingBubble({
    super.key,
    this.size = 8,
    this.color = VaporTheme.primaryLight,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _opacityAnim;
  final _random = Random();
  late double _startX;

  @override
  void initState() {
    super.initState();
    _startX = _random.nextDouble();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    _offsetAnim = Tween<Offset>(
      begin: Offset(_startX, 1.2),
      end: Offset(_startX + (_random.nextDouble() - 0.5) * 0.3, -0.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 20),
    ]).animate(_controller);
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
      builder: (context, _) => FractionalTranslation(
        translation: _offsetAnim.value,
        child: Opacity(
          opacity: _opacityAnim.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.3),
              border: Border.all(color: widget.color, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class SpringCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SpringCheckbox({super.key, required this.value, required this.onChanged});

  @override
  State<SpringCheckbox> createState() => _SpringCheckboxState();
}

class _SpringCheckboxState extends State<SpringCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0);
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.value ? VaporTheme.primary : Colors.transparent,
            border: Border.all(
              color: widget.value ? VaporTheme.primary : VaporTheme.textHint,
              width: 2,
            ),
          ),
          child: widget.value
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
