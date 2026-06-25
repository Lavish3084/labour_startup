import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

/// Pulsing map-pin loader (e.g. "Fetching location...").
class LocationLoadingIndicator extends StatefulWidget {
  final String message;
  final bool showMessage;

  const LocationLoadingIndicator({
    super.key,
    this.message = 'Fetching location...',
    this.showMessage = true,
  });

  @override
  State<LocationLoadingIndicator> createState() =>
      _LocationLoadingIndicatorState();
}

class _LocationLoadingIndicatorState extends State<LocationLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _buildPulseRing(0.0),
                  _buildPulseRing(0.33),
                  _buildPulseRing(0.66),
                  child!,
                ],
              );
            },
            child: _buildPinCore(),
          ),
        ),
        if (widget.showMessage) ...[
          const SizedBox(height: 28),
          Text(
            widget.message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPulseRing(double phaseOffset) {
    final t = (_pulseController.value + phaseOffset) % 1.0;
    final scale = 0.55 + (t * 0.55);
    final opacity = (1.0 - t) * 0.35;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.brandGreenMain.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildPinCore() {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8F5F1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(92, 92), painter: _MapGridPainter()),
          Icon(
            Icons.location_on_rounded,
            size: 44,
            color: AppTheme.brandGreenMain,
            shadows: [
              Shadow(
                color: AppTheme.brandGreenMain.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const spacing = 14.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), paint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paint);
    }

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.38,
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
