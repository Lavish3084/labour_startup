import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../models/service_category.dart';
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

class _SearchingWorkerScreenState extends State<SearchingWorkerScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _pollingTimer;
  StreamSubscription? _notificationSubscription;
  bool _isNavigating = false;
  
  // Timer state
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    
    // Set timer to 30 minutes (1800 seconds)
    _remainingSeconds = 30 * 60;
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _startCountdown();

    final rawId = widget.bookingData?['_id'] ?? widget.bookingData?['id'];
    if (rawId != null) {
      final String bookingId = rawId.toString();
      _startPolling(bookingId);
      _notificationSubscription = NotificationService.onNotification.listen((_) {
        _checkBookingStatus(bookingId);
      });
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _notificationSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkBookingStatus(String id) async {
    if (_isNavigating || !mounted) return;
    try {
      final booking = await ApiService.getBooking(id);
      if (!mounted) return;

      if (booking['status'] == 'confirmed' || booking['labourer'] != null) {
        _handleSuccess();
      }
    } catch (e) {
      debugPrint('Status check error: $e');
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\${widget.category.name} worker found!'),
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Cancel Search?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel the search?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Waiting', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '\${minutes.toString().padLeft(2, '0')}:\${seconds.toString().padLeft(2, '0')} Remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPatternedHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildMapContainer(),
                  const SizedBox(height: 20),
                  Text(
                    _formattedTime,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  Text(
                    'High demand...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We will notify you, once we assign\na worker for the task!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildCancelButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternedHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF388E3C),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E876E), Color(0xFF4A9782)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderPatternPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Notifying \${widget.category.name}\nworkers near you',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Booking Details',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer() {
    return Container(
      width: double.infinity,
      height: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated Map Background
          Positioned.fill(
            child: CustomPaint(
              painter: _MapRoadsPainter(),
            ),
          ),
          // Pulsing Circles
          ...List.generate(4, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final progress = (_pulseController.value + (index / 4)) % 1.0;
                return Container(
                  width: 150 * progress,
                  height: 150 * progress,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2E876E).withOpacity(1.0 - progress),
                      width: 1,
                    ),
                  ),
                );
              },
            );
          }),
          // Center Marker
          const Icon(
            Icons.location_on,
            color: Color(0xFF4A9782),
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    // We visually represent a 30 min progress bar
    double total = 30 * 60;
    double progress = (total - _remainingSeconds) / total;
    
    return Container(
      height: 6,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.01, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF4A9782),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: 180,
      height: 48,
      child: ElevatedButton(
        onPressed: _handleCancel,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A9782),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          'Cancel Search',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    const spacing = 20.0;
    const radius = 1.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapRoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draws a fake road map background resembling Kharar or a generic map.
    final paint = Paint()
      ..color = const Color(0xFF8BA5CD).withOpacity(0.5) // Light blue/grey roads
      ..style = PaintingStyle.stroke;
      
    // Main slanted road
    paint.strokeWidth = 16.0;
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.6), paint);
    
    // Vertical road
    paint.strokeWidth = 8.0;
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.85, size.height), paint);
    
    // Thin local lines
    paint.strokeWidth = 2.0;
    paint.color = Colors.black12;
    // Draw some random horizontal/vertical lines
    for (int i = 1; i <= 6; i++) {
       canvas.drawLine(Offset(0, size.height * (i/7)), Offset(size.width, size.height * (i/7) + (i%2 == 0 ? 20 : -20)), paint);
       canvas.drawLine(Offset(size.width * (i/7), 0), Offset(size.width * (i/7) + (i%3 == 0 ? 30 : -10), size.height), paint);
    }
    
    _drawText(canvas, 'GURU TEG\nBAHADUR NAGAR', Offset(size.width * 0.35, size.height * 0.15));
    _drawText(canvas, 'SECTOR 43', Offset(size.width * 0.35, size.height * 0.40));
    _drawText(canvas, 'RANJIT NAGAR', Offset(size.width * 0.25, size.height * 0.85));
  }
  
  void _drawText(Canvas canvas, String text, Offset offset) {
    final textStyle = GoogleFonts.inter(
      color: Colors.black54,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(minWidth: 0, maxWidth: 100);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
