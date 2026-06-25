import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'location_loading_indicator.dart';
import 'location_map_circle.dart';
import 'location_address_labels.dart';

/// White-screen location flow: pulse → lift up → address below → callback.
class SplashLocationSequence extends StatefulWidget {
  final bool isFetching;
  final String? locality;
  final String? fullAddress;
  final double? latitude;
  final double? longitude;
  final VoidCallback onSequenceComplete;

  const SplashLocationSequence({
    super.key,
    required this.isFetching,
    required this.locality,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.onSequenceComplete,
  });

  @override
  State<SplashLocationSequence> createState() => _SplashLocationSequenceState();
}

class _SplashLocationSequenceState extends State<SplashLocationSequence>
    with TickerProviderStateMixin {
  late AnimationController _liftController;
  late AnimationController _textController;
  late Animation<double> _liftAnimation;
  late Animation<double> _textAnimation;

  bool _showMap = false;
  bool _sequenceStarted = false;

  @override
  void initState() {
    super.initState();
    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _liftAnimation = CurvedAnimation(
      parent: _liftController,
      curve: Curves.easeOutCubic,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    if (!widget.isFetching && _hasLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runFoundSequence());
    }
  }

  @override
  void didUpdateWidget(SplashLocationSequence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFetching &&
        !widget.isFetching &&
        _hasLocation &&
        !_sequenceStarted) {
      _runFoundSequence();
    }
  }

  bool get _hasLocation =>
      widget.locality != null &&
      widget.fullAddress != null &&
      widget.latitude != null &&
      widget.longitude != null;

  Future<void> _runFoundSequence() async {
    if (_sequenceStarted || !_hasLocation) return;
    _sequenceStarted = true;

    setState(() => _showMap = true);
    await _liftController.forward();
    if (!mounted) return;

    await _textController.forward();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) widget.onSequenceComplete();
  }

  @override
  void dispose() {
    _liftController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liftOffset = -52 * _liftAnimation.value;

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_liftController, _textController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, liftOffset),
            child: SizedBox(
              width: screenWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child:
                        _showMap && _hasLocation
                            ? LocationMapCircle(
                              key: const ValueKey('map'),
                              latitude: widget.latitude!,
                              longitude: widget.longitude!,
                            )
                            : const LocationLoadingIndicator(
                              key: ValueKey('pulse'),
                              showMessage: false,
                            ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedOpacity(
                    opacity:
                        widget.isFetching ? 1.0 : (1.0 - _liftAnimation.value),
                    duration: const Duration(milliseconds: 200),
                    child:
                        widget.isFetching
                            ? Text(
                              'Fetching location...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            )
                            : const SizedBox(height: 22),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SizeTransition(
                      sizeFactor: _textAnimation,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child:
                            _hasLocation
                                ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Center(
                                    child: LocationAddressLabels(
                                      locality: widget.locality!,
                                      fullAddress: widget.fullAddress!,
                                    ),
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
