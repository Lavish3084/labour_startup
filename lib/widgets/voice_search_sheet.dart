import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class VoiceSearchSheet extends StatefulWidget {
  final Function(String) onResult;

  const VoiceSearchSheet({Key? key, required this.onResult}) : super(key: key);

  @override
  State<VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends State<VoiceSearchSheet>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  String _statusText = "Listening...";
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Simulated "Listening" logic
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusText = "Searching for 'Electrician'...";
          _isFinished = true;
        });

        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            widget.onResult("Electrician");
            Navigator.pop(context);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Background Ripple Effect
          if (!_isFinished)
            Center(
              child: AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRipple(
                        1.0 + (_rippleController.value * 0.5),
                        0.3 - (_rippleController.value * 0.3),
                      ),
                      _buildRipple(
                        1.0 + ((_rippleController.value + 0.3) % 1.0 * 0.5),
                        0.2 - ((_rippleController.value + 0.3) % 1.0 * 0.2),
                      ),
                    ],
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ScaleTransition(
                    scale: Tween(
                      begin: 0.95,
                      end: 1.05,
                    ).animate(_pulseController),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color:
                            _isFinished ? AppTheme.success : AppTheme.saffron,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isFinished
                                    ? AppTheme.success
                                    : AppTheme.saffron)
                                .withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFinished ? Icons.check_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isFinished
                      ? 'Found matches!'
                      : 'Try saying "Plumber near me" or "Electrician"',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Handle
          Positioned(
            top: 12,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double scale, double opacity) {
    return Container(
      width: 160 * scale,
      height: 160 * scale,
      decoration: BoxDecoration(
        color: AppTheme.saffron.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
