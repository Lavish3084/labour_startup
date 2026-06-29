import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'track_status_screen.dart';
import '../models/labourer.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';
import 'main_screen.dart';

class SearchingWorkerScreen extends StatefulWidget {
  final ServiceCategory category;
  final String address;
  final DateTime scheduledTime;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? bookingData;

  const SearchingWorkerScreen({
    super.key,
    required this.category,
    required this.address,
    required this.scheduledTime,
    required this.latitude,
    required this.longitude,
    this.bookingData,
  });

  @override
  State<SearchingWorkerScreen> createState() => _SearchingWorkerScreenState();
}

class _SearchingWorkerScreenState extends State<SearchingWorkerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  final SocketService _socketService = SocketService();
  StreamSubscription? _notificationSubscription;
  bool _isNavigating = false;
  bool _isTimedOut = false;
  bool _isRecreating = false;
  String? _currentBookingId;

  // Timer state
  late int _remainingSeconds;
  Timer? _countdownTimer;

  // Fake worker state
  final List<LatLng> _fakeWorkers = [];
  Timer? _workerMovementTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentBookingId =
        (widget.bookingData?['_id'] ?? widget.bookingData?['id'])?.toString();

    // Calculate remaining seconds based on createdAt to ensure persistence
    final createdAtStr = widget.bookingData?['createdAt'];
    if (createdAtStr != null) {
      try {
        final createdAt = DateTime.parse(createdAtStr.toString()).toLocal();
        final expiryTime = createdAt.add(const Duration(minutes: 30));
        final now = DateTime.now();
        _remainingSeconds = expiryTime.difference(now).inSeconds;

        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _isTimedOut = true;
        }
      } catch (e) {
        _remainingSeconds = 30 * 60;
      }
    } else {
      _remainingSeconds = 30 * 60;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initFakeWorkers();

    if (!_isTimedOut) {
      _startCountdown();
      if (_currentBookingId != null) {
        _initSocket(_currentBookingId!);
        _notificationSubscription = NotificationService.onNotification.listen((
          _,
        ) {
          _checkBookingStatus(_currentBookingId!);
        });
      }
    }
  }

  void _initFakeWorkers() {
    int workerCount = 3 + _random.nextInt(4); // 3 to 6 fake workers
    for (int i = 0; i < workerCount; i++) {
      // offset by roughly 0.015 degrees max (~1.5 km)
      double latOffset = (_random.nextDouble() - 0.5) * 0.03;
      double lngOffset = (_random.nextDouble() - 0.5) * 0.03;
      _fakeWorkers.add(LatLng(widget.latitude + latOffset, widget.longitude + lngOffset));
    }

    _workerMovementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !_isTimedOut && !_isNavigating) {
        setState(() {
          for (int i = 0; i < _fakeWorkers.length; i++) {
            // move roughly 10-20 meters
            double latMove = (_random.nextDouble() - 0.5) * 0.0004;
            double lngMove = (_random.nextDouble() - 0.5) * 0.0004;

            double newLat = _fakeWorkers[i].latitude + latMove;
            double newLng = _fakeWorkers[i].longitude + lngMove;

            // keep them within a bound
            if ((newLat - widget.latitude).abs() > 0.02) newLat -= latMove * 2;
            if ((newLng - widget.longitude).abs() > 0.02) newLng -= lngMove * 2;

            _fakeWorkers[i] = LatLng(newLat, newLng);
          }
        });
      }
    });
  }

  void _initSocket(String id) {
    _socketService.connect();
    _socketService.offBookingUpdate();
    _socketService.joinBooking(id);
    _socketService.onBookingUpdate((data) {
      if (mounted) {
        debugPrint('[Socket] SearchingWorkerScreen received update');
        if (data['status'] == 'confirmed' || data['labourer'] != null) {
          _handleSuccess(data);
        }
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
        _handleExpiry();
      }
    });
  }

  Future<void> _handleExpiry() async {
    if (_isNavigating || _isTimedOut) return;

    if (_currentBookingId != null) {
      try {
        await ApiService.updateBookingStatus(_currentBookingId!, 'cancelled');
      } catch (e) {
        debugPrint('Error cancelling expired booking: $e');
      }
    }

    if (mounted) {
      _countdownTimer?.cancel();
      setState(() {
        _isTimedOut = true;
        _remainingSeconds = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search timed out. You can try searching again.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSearchAgain() async {
    if (_isRecreating) return;

    setState(() {
      _isRecreating = true;
    });

    try {
      final newBookingData = Map<String, dynamic>.from(widget.bookingData ?? {});
      newBookingData.remove('_id');
      newBookingData.remove('id');
      newBookingData.remove('createdAt');
      newBookingData.remove('updatedAt');
      newBookingData.remove('status');
      newBookingData.remove('labourer');
      newBookingData.remove('__v');

      final response = await ApiService.createBooking(
        category: widget.category.name,
        date: widget.scheduledTime,
        bookingMode: widget.bookingData?['bookingMode'] ?? 'Hourly',
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
        numberOfHours: int.tryParse(widget.bookingData?['numberOfHours']?.toString() ?? ''),
        numberOfWorkers: int.tryParse(widget.bookingData?['numberOfWorkers']?.toString() ?? '1') ?? 1,
        notes: widget.bookingData?['notes']?.toString(),
        problemTitle: widget.bookingData?['problemTitle']?.toString(),
        landmark: widget.bookingData?['landmark']?.toString(),
        houseNumber: widget.bookingData?['houseNumber']?.toString(),
        workType: widget.bookingData?['workType']?.toString(),
      );
      final newId = (response['_id'] ?? response['id'])?.toString();

      if (mounted && newId != null) {
        setState(() {
          _currentBookingId = newId;
          _isTimedOut = false;
          _isRecreating = false;
          _remainingSeconds = 30 * 60;
        });

        _startCountdown();
        _initSocket(newId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search restarted!'),
            backgroundColor: AppTheme.brandGreenMain,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restart search: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_currentBookingId != null) {
      _socketService.leaveBooking(_currentBookingId!);
      _socketService.offBookingUpdate();
    }
    _countdownTimer?.cancel();
    _workerMovementTimer?.cancel();
    _notificationSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_currentBookingId != null) {
        _checkBookingStatus(_currentBookingId!);
        _initSocket(_currentBookingId!);
      }
    }
  }

  Future<void> _checkBookingStatus(String id) async {
    if (_isNavigating || !mounted) return;
    try {
      final booking = await ApiService.getBooking(id);
      if (!mounted) return;

      if (booking['status'] == 'confirmed' || booking['labourer'] != null) {
        _handleSuccess(booking);
      }
    } catch (e) {
      debugPrint('Status check error: $e');
    }
  }

  void _handleSuccess(Map<String, dynamic> bookingData) {
    if (_isNavigating) return;
    _isNavigating = true;

    if (mounted) {
      final workerData = bookingData['labourer'];
      Labourer? assignedWorker;
      if (workerData != null) {
        assignedWorker = Labourer.fromJson(workerData);
      }

      if (assignedWorker != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => TrackStatusScreen(
              bookingId: (bookingData['_id'] ?? bookingData['id']).toString(),
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(initialIndex: 1),
          ),
          (route) => false,
        );
      }
    }
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Cancel Search?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel the search?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Waiting',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final rawId = widget.bookingData?['_id'] ?? widget.bookingData?['id'];
              if (rawId != null) {
                await ApiService.updateBookingStatus(
                  rawId.toString(),
                  'cancelled',
                );
              }
              if (mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialIndex: 0),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    if (_isTimedOut) return '00:00 - Search Timed Out';
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} Remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Stack(
        children: [
          // Bottom Layer: Map
          _buildFullMap(),

          // Top Layer: Floating Searching Bar
          _buildTopBar(),

          // Top Layer: Bottom Status Card Overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomCardOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullMap() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(widget.latitude, widget.longitude),
        initialZoom: 14.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.lavish3084.labour',
        ),
        MarkerLayer(
          markers: [
            // Fake Workers
            ..._fakeWorkers.map((pos) => Marker(
              point: pos,
              width: 48,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2)),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/default_avatar.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            )),
            // User Location
            Marker(
              point: LatLng(widget.latitude, widget.longitude),
              width: 80,
              height: 80,
              child: _buildUserMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final progress = _pulseController.value;
            return Container(
              width: 80 * progress,
              height: 80 * progress,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandGreenMain.withOpacity(0.4 * (1.0 - progress)),
                border: Border.all(
                  color: AppTheme.brandGreenMain.withOpacity(0.8 * (1.0 - progress)),
                  width: 2,
                ),
              ),
            );
          },
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isTimedOut) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandGreenMain),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isTimedOut ? 'Search Timed Out' : 'Searching for ${widget.category.name}...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCardOverlay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isTimedOut
                ? 'Search Timed Out'
                : 'Notifying ${widget.category.name}\nworkers near you',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _formattedTime,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandGreenMain,
            ),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(),
          const SizedBox(height: 24),
          Text(
            _isTimedOut
                ? 'No worker accepted the request in time.\nYou can restart the search to try again!'
                : 'We will notify you, once we assign\na worker for the task!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildFooterButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    double total = 30 * 60;
    double progress = (total - _remainingSeconds) / total;

    return Container(
      height: 6,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.01, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.brandGreenMain,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 52,
              child: ElevatedButton(
                onPressed: _isTimedOut ? _handleSearchAgain : _handleCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreenMain,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _isRecreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isTimedOut ? 'Search Again' : 'Cancel Search',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 52,
              width: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.home_rounded,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Search will continue even if you go home\nto explore other services!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
