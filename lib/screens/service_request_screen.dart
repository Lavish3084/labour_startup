import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'location_search_screen.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'searching_worker_screen.dart';
import 'booking_setup_screen.dart';
import '../widgets/concave_header_clipper.dart';
import '../widgets/pattern_painter.dart';

class ServiceRequestScreen extends StatefulWidget {
  final ServiceCategory category;
  final bool isInstant;
  final int numberOfWorkers;
  final String workType;
  final List<String>? taskImagesBase64;
  final String? taskAudioBase64;
  final String? taskNotes;

  const ServiceRequestScreen({
    super.key,
    required this.category,
    this.isInstant = false,
    this.numberOfWorkers = 1,
    this.workType = '',
    this.taskImagesBase64,
    this.taskAudioBase64,
    this.taskNotes,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final TextEditingController _notesController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 65));
  late TimeOfDay _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  final bool _saveAddress = true;
  late String _selectedBookingMode;
  int _numberOfHours = 2; // Default 2h
  final Set<DateTime> _selectedDates = {}; // For multi-date selection in Daily mode

  @override
  void initState() {
    super.initState();
    _selectedBookingMode =
        widget.category.supportedModes.contains('Hourly')
            ? 'Hourly'
            : widget.category.supportedModes.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromProvider();
    });
  }

  void _initializeFromProvider() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentAddress != null) {
      setState(() {
        _selectedAddress = locationProvider.currentAddress;
        _latitude = locationProvider.currentLatitude;
        _longitude = locationProvider.currentLongitude;

        if (locationProvider.currentHouseNumber != null) {
          _houseController.text = locationProvider.currentHouseNumber!;
        }
        if (locationProvider.currentLandmark != null) {
          _landmarkController.text = locationProvider.currentLandmark!;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TimePickerSheet(
        initialTime: _selectedTime,
        selectedDate: _selectedDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickAddress() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.loadSavedLocations();

    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ServiceLocationSelectionSheet(
        savedLocations: locationProvider.savedLocations,
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedAddress = result['address'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        if (result['houseNumber'] != null) {
          _houseController.text = result['houseNumber'] as String;
        }
        if (result['landmark'] != null) {
          _landmarkController.text = result['landmark'] as String;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPatternedHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: _selectedAddress != null ? 28 : 20),
                  if (widget.isInstant) ...[
                    _buildInstantHelpBanner(),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    _buildHourlyContent(),
                    const SizedBox(height: 32),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildModeToggle(),
                        if (_selectedBookingMode == 'Hourly') _buildArrivalTimeShortCard(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select Date',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateSelectionRow(),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    if (_selectedBookingMode == 'Hourly') 
                      _buildHourlyContent() 
                    else 
                      _buildDailyContent(),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedAddress == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: _buildLocationSection(),
            ),
          _buildBottomFooter(),
        ],
      ),
    );
  }

  Widget _buildPatternedHeader() {
    final double headerHeight = _selectedAddress != null ? 268 : 222;
    return ClipPath(
      clipper: const ConcaveBottomHeaderClipper(radius: 40),
      child: Container(
        width: double.infinity,
        height: headerHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, -0.00),
            end: Alignment(0.50, 1.00),
            colors: [Color(0xFF06644A), Color(0xFF4A9782)],
          ),
        ),
        child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'When should we start ?',
                    style: GoogleFonts.roboto( // Changed to Roboto
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  if (_selectedAddress != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickAddress,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFFE1FFF6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _selectedAddress!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 12,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Change',
                              style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE1FFF6),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFFE1FFF6),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      width: 172,
      height: 52,
      decoration: ShapeDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.50, 0.50),
          radius: 0.50,
          colors: [Color(0xFF4A9782), Color(0xFF216F5A)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _selectedBookingMode == 'Hourly'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                width: 90,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1FFF6),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedBookingMode = 'Hourly'),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: _selectedBookingMode == 'Hourly'
                                ? const Color(0xFF4A9782)
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hourly',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedBookingMode == 'Hourly'
                                  ? const Color(0xFF4A9782)
                                  : Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedBookingMode = 'Daily'),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _selectedBookingMode == 'Daily'
                                ? const Color(0xFF4A9782)
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Daily',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedBookingMode == 'Daily'
                                  ? const Color(0xFF4A9782)
                                  : Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalTimeShortCard() {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAF7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.access_alarm,
                  size: 24, color: Color(0xFF4A9782)),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arrival Time',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _selectedTime.format(context),
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A9782), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectionRow() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _selectedBookingMode == 'Hourly'
              ? DateUtils.isSameDay(_selectedDate, date)
              : _selectedDates.any((d) => DateUtils.isSameDay(d, date));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedBookingMode == 'Hourly') {
                    _selectedDate = date;
                  } else {
                    if (_selectedDates.any((d) => DateUtils.isSameDay(d, date))) {
                      _selectedDates
                          .removeWhere((d) => DateUtils.isSameDay(d, date));
                    } else {
                      _selectedDates.add(date);
                    }
                  }
                });
              },
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A9782)
                        : const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: GoogleFonts.roboto(
                          fontSize: 8,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.40,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(date),
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                          letterSpacing: 0.40,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourlyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Duration of work'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _numberOfHours.toString().padLeft(2, '0'),
                    style: GoogleFonts.roboto(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A9782),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hours',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC9C9C9),
                      height: 1.43,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF4A9782),
                  inactiveTrackColor: const Color(0xFFBBBBBB),
                  thumbColor: const Color(0xFF4A9782),
                  overlayColor: const Color(0xFF4A9782).withValues(alpha: 0.1),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _numberOfHours.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  onChanged: (val) =>
                      setState(() => _numberOfHours = val.toInt()),
                ),
              ),
              const SizedBox(height: 8),
              _buildRuler(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyContent() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                Icons.calendar_month,
                'Total Days Selected',
                '${_selectedDates.length.toString().padLeft(2, '0')} Days',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                Icons.access_alarm,
                'Fixed Working Hours',
                '08:00 AM - 06:00 PM',
                isLocked: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(IconData icon, String label, String value,
      {bool isLocked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1FAF7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 26, color: const Color(0xFF4A9782)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF636363),
                        ),
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_outline, size: 10, color: Color(0xFF636363)),
                    ],
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuler() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6, // Show 6 main points
              (index) => Column(
                children: [
                  Container(
                    width: 1,
                    height: 13,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Sub-ticks (visual only)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              21, // 4 gaps of 4 ticks each between 6 points (5 gaps * 4 ticks = 20, + 1 for alignment)
              (index) => Container(
                width: 1,
                height: (index % 4 == 0) ? 0 : 7, // Hide sub-ticks that overlap with main ticks
                color: const Color(0xFFD2D2D2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return GestureDetector(
      onTap: _pickAddress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1FAF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4A9782).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF4A9782),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select Location',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF216F5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to set your work location from where you are',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF636363),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF4A9782),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomFooter() {
    final totalPrice = _calculateTotalPrice();
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Total',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.40,
                  color: const Color(0xFF636363),
                ),
              ),
              Text(
                '₹${totalPrice.toInt()}',
                style: GoogleFonts.roboto(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF47907D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedAddress == null || _latitude == null || _longitude == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a valid location first')),
                  );
                  return;
                }

                // Call address saving in background if enabled
                if (_saveAddress) {
                  ApiService.addSavedAddress({
                    'address': _selectedAddress,
                    'latitude': _latitude,
                    'longitude': _longitude,
                    'houseNumber': _houseController.text,
                    'landmark': _landmarkController.text,
                    'name': 'Saved Location',
                  });
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingSetupScreen(
                      category: widget.category,
                      bookingMode: widget.isInstant ? 'Hourly' : _selectedBookingMode,
                      scheduledTime: widget.isInstant
                          ? DateTime.now()
                          : DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _selectedTime.hour,
                              _selectedTime.minute,
                            ),
                      isInstant: widget.isInstant,
                      numberOfHours: (widget.isInstant || _selectedBookingMode == 'Hourly') ? _numberOfHours.toInt() : null,
                      address: _selectedAddress!,
                      latitude: _latitude!,
                      longitude: _longitude!,
                      amount: totalPrice,
                      numberOfWorkers: widget.numberOfWorkers,
                      workType: widget.workType,
                      taskImagesBase64: widget.taskImagesBase64,
                      taskAudioBase64: widget.taskAudioBase64,
                      taskNotes: widget.taskNotes,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9782),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Center(
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  double _calculateTotalPrice() {
    if (widget.isInstant || _selectedBookingMode == 'Hourly') {
      return widget.category.hourlyRate * _numberOfHours;
    } else {
      // Daily mode is fixed 10 hours (8 AM to 6 PM)
      return widget.category.hourlyRate * 10 * (_selectedDates.length.clamp(1, 100));
    }
  }

  Widget _buildInstantHelpBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A9782).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Color(0xFF4A9782),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instant Booking Active',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A worker will be assigned to arrive as soon as possible (ASAP).',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final DateTime selectedDate;

  const _TimePickerSheet({
    required this.initialTime,
    required this.selectedDate,
  });

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late DateTime _tempDateTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tempDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      widget.initialTime.hour,
      widget.initialTime.minute,
    );
    _validate(_tempDateTime);
  }

  void _validate(DateTime dt) {
    final now = DateTime.now();
    final minTime = now.add(const Duration(minutes: 60));
    
    if (dt.isBefore(minTime)) {
      final hour = minTime.hour == 0 ? 12 : (minTime.hour > 12 ? minTime.hour - 12 : minTime.hour);
      final ampm = minTime.hour >= 12 ? 'PM' : 'AM';
      final minute = minTime.minute.toString().padLeft(2, '0');
      setState(() {
        _error = 'Please book after $hour:$minute $ampm';
      });
    } else {
      setState(() {
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Start Time',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 200,
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.light,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _tempDateTime,
                  use24hFormat: false,
                  onDateTimeChanged: (dt) {
                    final updatedDt = DateTime(
                      widget.selectedDate.year,
                      widget.selectedDate.month,
                      widget.selectedDate.day,
                      dt.hour,
                      dt.minute,
                    );
                    _tempDateTime = updatedDt;
                    _validate(updatedDt);
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                   Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _error != null 
                        ? null 
                        : () => Navigator.pop(context, TimeOfDay.fromDateTime(_tempDateTime)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5EA28F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm'),
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
}

class _ServiceLocationSelectionSheet extends StatelessWidget {
  final List<SavedLocation> savedLocations;

  const _ServiceLocationSelectionSheet({
    required this.savedLocations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Work Location',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black54),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (savedLocations.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.location_off_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No saved locations found',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: savedLocations.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, index) {
                    final location = savedLocations[index];
                    IconData iconData = Icons.location_on_rounded;
                    if (location.label.toLowerCase() == 'home') {
                      iconData = Icons.home_rounded;
                    } else if (location.label.toLowerCase() == 'work') {
                      iconData = Icons.work_rounded;
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5F1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: const Color(0xFF4A9782),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        location.label,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (location.houseNumber.isNotEmpty) 'House: ${location.houseNumber}',
                            if (location.landmark.isNotEmpty) 'Landmark: ${location.landmark}',
                            location.address,
                          ].join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, {
                          'address': location.address,
                          'latitude': location.latitude,
                          'longitude': location.longitude,
                          'houseNumber': location.houseNumber,
                          'landmark': location.landmark,
                        });
                      },
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                tileColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF4EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_location_alt_outlined,
                    color: Color(0xFFFF6B00),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Select a New Address',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Search and pin a new address',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationSearchScreen(),
                    ),
                  );
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

