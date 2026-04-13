import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../models/service_category.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';

class SearchingWorkerScreen extends StatefulWidget {
  final ServiceCategory category;
  final String address;
  final DateTime scheduledTime;
  final Map<String, dynamic>? bookingData;

  const SearchingWorkerScreen({
    super.key,
    required this.category,
    required this.address,
    required this.scheduledTime,
    this.bookingData,
  });

  @override
  State<SearchingWorkerScreen> createState() => _SearchingWorkerScreenState();
}

class _SearchingWorkerScreenState extends State<SearchingWorkerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _contentController;
  late AnimationController _backgroundController;
  
  late final List<String> _searchStatuses;
  int _statusIndex = 0;
  Timer? _statusTimer;
  Timer? _pollingTimer;
  StreamSubscription? _notificationSubscription;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _searchStatuses = [
      'Finding available ${widget.category.name}s...',
      'Matching you with top-rated workers...',
      'Connecting to nearby partners...',
      'Assigning your service request...',
      'Finalizing connection...',
    ];
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _searchStatuses.length;
        });
      }
    });

    final rawId = widget.bookingData?['_id'] ?? widget.bookingData?['id'];
    if (rawId != null) {
      final String bookingId = rawId.toString();
      debugPrint('SearchingWorkerScreen: Starting search for Booking ID: $bookingId');
      _startPolling(bookingId);
      _notificationSubscription = NotificationService.onNotification.listen((_) {
        debugPrint('SearchingWorkerScreen: Notification received, triggering manual status check');
        _checkBookingStatus(bookingId);
      });
    } else {
      debugPrint('SearchingWorkerScreen: Warning - No booking ID found in bookingData');
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pollingTimer?.cancel();
    _notificationSubscription?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _contentController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _checkBookingStatus(String id) async {
    if (_isNavigating || !mounted) return;
    try {
      debugPrint('SearchingWorkerScreen: Polling status for $id...');
      final booking = await ApiService.getBooking(id);
      if (!mounted) return;

      debugPrint('SearchingWorkerScreen: Current status: ${booking['status']}');

      if (booking['status'] == 'confirmed' || booking['labourer'] != null) {
        debugPrint('SearchingWorkerScreen: Worker found! Navigating to success.');
        _handleSuccess();
      }
    } catch (e) {
      debugPrint('SearchingWorkerScreen: Status check error: $id - $e');
    }
  }

  void _startPolling(String id) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _checkBookingStatus(id);
    });
  }

  void _handleSuccess() {
    if (_isNavigating) return;
    _isNavigating = true;
    _pollingTimer?.cancel();
    _statusTimer?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.category.name} worker found!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 1)),
        (route) => false,
      );
    }
  }


  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            title: Text('Cancel Search?', style: AppTheme.heading2),
            content: Text('Are you sure you want to cancel the search?', style: AppTheme.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Keep Waiting', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: AppTheme.dangerButton.copyWith(
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                child: const Text('Cancel Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy background
      body: Stack(
        children: [
          // Dynamic Background Blobs
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (50 * sin(_backgroundController.value * 2 * pi)),
                    right: -50 + (30 * cos(_backgroundController.value * 2 * pi)),
                    child: _buildBlob(300, AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  Positioned(
                    bottom: -100 + (40 * cos(_backgroundController.value * 2 * pi)),
                    left: -80 + (60 * sin(_backgroundController.value * 2 * pi)),
                    child: _buildBlob(350, AppTheme.accent.withValues(alpha: 0.15)),
                  ),
                ],
              );
            },
          ),

          // Glass Backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: const Color(0xFF0F172A).withValues(alpha: 0.6)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _contentController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const Spacer(),
                    _buildRadarAnimation(),
                    const Spacer(),
                    _buildStatusText(),
                    const SizedBox(height: 32),
                    _buildBookingDetails(),
                    const SizedBox(height: 48),
                    _buildCancelButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Connecting...',
          style: GoogleFonts.baloo2(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE SEARCH',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadarAnimation() {
    return SizedBox(
      height: 300,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Circles
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double progress = (_pulseController.value + (index / 3)) % 1.0;
                return Container(
                  width: 300 * progress,
                  height: 300 * progress,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: (1 - progress) * 0.5),
                      width: 1.5,
                    ),
                  ),
                );
              },
            );
          }),

          // Rotating Scanner
          RotationTransition(
            turns: _rotationController,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.primary.withValues(alpha: 0.0),
                    AppTheme.primary.withValues(alpha: 0.3),
                    AppTheme.primary.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Inner Glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Central Icon
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              widget.category.icon,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          
          // Worker Blips
          _buildWorkerBlip(0.2, 0.1),
          _buildWorkerBlip(0.8, 0.3),
          _buildWorkerBlip(0.15, 0.75),
          _buildWorkerBlip(0.65, 0.85),
        ],
      ),
    );
  }

  Widget _buildWorkerBlip(double top, double left) {
    return Positioned(
      top: top * 300,
      left: left * 300,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final double opacity = 0.3 + (0.7 * sin(_pulseController.value * 2 * pi + (top * 5)).abs());
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.saffron,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _searchStatuses[_statusIndex],
        key: ValueKey(_statusIndex),
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(radius: 28),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMM dd • hh:mm a').format(widget.scheduledTime),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.category.icon, color: Colors.white, size: 28),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white12, height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.address,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _handleCancel,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white54,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: Text(
        'Cancel Searching',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

