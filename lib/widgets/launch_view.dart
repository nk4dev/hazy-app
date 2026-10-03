import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The one loading screen shown from launch until the app is usable: the
/// Hazy mark dead-centre (where the native launch splash draws it) with a
/// spinner beneath.
///
/// It is rendered by two different owners in sequence — `ClerkAuth`'s
/// `loading` slot while the Clerk SDK starts, then the `/splash` route
/// until auth resolves — so it deliberately depends on nothing but its
/// arguments (no theme, no `Directionality`), and its spinner takes its
/// phase from the wall clock so the hand-over between the two is invisible
/// instead of looking like a second loading animation starting.
class LaunchView extends StatelessWidget {
  const LaunchView({super.key, required this.background});

  final Color background;

  static const logoAsset = 'assets/branding/app_logo.png';
  // Sized so the mark matches the Android 12+ system splash icon exactly.
  static const _logoSize = 178.0;
  static const _accent = Color(0xFF9184D9);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(logoAsset, width: _logoSize, height: _logoSize),
          const Align(
            alignment: Alignment(0, 0.3),
            child: _ClockSpinner(color: _accent),
          ),
        ],
      ),
    );
  }
}

class _ClockSpinner extends StatefulWidget {
  const _ClockSpinner({required this.color});

  final Color color;

  @override
  State<_ClockSpinner> createState() => _ClockSpinnerState();
}

class _ClockSpinnerState extends State<_ClockSpinner>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  @override
  void initState() {
    super.initState();
    // Start at the angle the wall clock dictates, so a new instance picks
    // up exactly where the previous one left off.
    final ms = DateTime.now().millisecondsSinceEpoch % _period.inMilliseconds;
    _controller
      ..value = ms / _period.inMilliseconds
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ArcPainter(_controller.value, widget.color),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.turn, this.color);

  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      (Offset.zero & size).deflate(1.5),
      turn * 2 * math.pi,
      1.5 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.turn != turn || old.color != color;
}
