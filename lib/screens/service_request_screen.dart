import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../utils/app_theme.dart';
import 'location_search_screen.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/app_state_provider.dart';

class ServiceRequestScreen extends StatefulWidget {
  final ServiceCategory category;

  const ServiceRequestScreen({super.key, required this.category});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final TextEditingController _notesController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedAddress;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _saveAddress = false;
  late String _selectedBookingMode;
  int _numberOfHours = 1;

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
    // Round current time to nearest 5 mins for initial view
    final int initialMinute = (_selectedTime.minute / 5).round() * 5;
    final TimeOfDay initialTime = TimeOfDay(hour: _selectedTime.hour, minute: initialMinute % 60);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.saffron,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith((states) => 
                states.contains(WidgetState.selected) 
                  ? AppTheme.saffron.withValues(alpha: 0.2) 
                  : Colors.white.withValues(alpha: 0.1)),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) => 
                states.contains(WidgetState.selected) 
                  ? AppTheme.saffron 
                  : AppTheme.textPrimary),
              dialBackgroundColor: Colors.white.withValues(alpha: 0.1),
              dialHandColor: AppTheme.saffron,
              dialTextColor: AppTheme.textPrimary,
              entryModeIconColor: AppTheme.saffron,
              dayPeriodColor: WidgetStateColor.resolveWith((states) => 
                states.contains(WidgetState.selected) 
                  ? AppTheme.saffron.withValues(alpha: 0.2) 
                  : Colors.transparent),
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: child!,
          ),
        );
      },
    );
    
    if (picked != null) {
      // Snap to nearest 5 minutes
      final int roundedMinute = (picked.minute / 5).round() * 5;
      final snappedTime = TimeOfDay(
        hour: (picked.hour + (roundedMinute >= 60 ? 1 : 0)) % 24,
        minute: roundedMinute % 60
      );
      
      // Immediate validation: check if time is at least 1 hr in advance
      final DateTime scheduledTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        snappedTime.hour,
        snappedTime.minute,
      );

      if (scheduledTime.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a time at least 1 hour from now.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return; // Don't update state if invalid
      }
      
      setState(() {
        _selectedTime = snappedTime;
      });
    }
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedAddress = result['address'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(top: 8, bottom: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.divider,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Checkout Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Finalize Booking',
                                style: AppTheme.heading2,
                              ),
                              Text(
                                widget.category.name,
                                style: AppTheme.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.saffron,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pricing Info',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),

                      Text(
                        'Where should we arrive?',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Saved Addresses - Refined Horizontal Cards
                      Consumer<LocationProvider>(
                        builder: (context, provider, child) {
                          if (provider.savedLocations.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 110,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: provider.savedLocations.length,
                                  itemBuilder: (context, index) {
                                    final loc = provider.savedLocations[index];
                                    final isSelected =
                                        _selectedAddress == loc.address &&
                                        _houseController.text ==
                                            loc.houseNumber;
                                    return GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          _selectedAddress = loc.address;
                                          _latitude = loc.latitude;
                                          _longitude = loc.longitude;
                                          _houseController.text =
                                              loc.houseNumber;
                                          _landmarkController.text =
                                              loc.landmark;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 180,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? AppTheme.textPrimary
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? AppTheme.textPrimary
                                                    : AppTheme.divider,
                                            width: 1.5,
                                          ),
                                          boxShadow:
                                              isSelected
                                                  ? AppTheme.shadowMd
                                                  : AppTheme.shadowSm,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.home_filled,
                                                  size: 16,
                                                  color:
                                                      isSelected
                                                          ? AppTheme.saffron
                                                          : AppTheme.textMuted,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    loc.label,
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : AppTheme
                                                                  .textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              loc.address,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color:
                                                    isSelected
                                                        ? Colors.white70
                                                        : AppTheme.textLight,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),

                      // Manual Address Entry
                      InkWell(
                        onTap: () async {
                          await _pickAddress();
                          setSheetState(() {});
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  _selectedAddress == null
                                      ? AppTheme.error.withValues(alpha: 0.3)
                                      : AppTheme.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map_rounded,
                                size: 20,
                                color:
                                    _selectedAddress == null
                                        ? AppTheme.error
                                        : AppTheme.saffron,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAddress ??
                                      'Search for your location...',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _selectedAddress == null
                                            ? AppTheme.textMuted
                                            : AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Detail Inputs
                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetInput(
                              controller: _houseController,
                              label: 'Flat / House No.',
                              hint: 'e.g. 402, 4th Floor',
                              icon: Icons.apartment_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSheetInput(
                              controller: _landmarkController,
                              label: 'Landmark',
                              hint: 'e.g. Near Park',
                              icon: Icons.assistant_navigation,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Save Checkbox - Modern Styled
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _saveAddress,
                                onChanged:
                                    (val) => setSheetState(
                                      () => _saveAddress = val ?? false,
                                    ),
                                activeColor: AppTheme.saffron,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Save this address for fast checkout',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Final Receipt & Button
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppTheme.shadowLg,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedBookingMode == 'Hourly'
                                      ? 'Est. Total (${_numberOfHours}h)'
                                      : 'Total Amount',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  '₹${(_selectedBookingMode == 'Hourly' ? widget.category.hourlyRate * _numberOfHours : widget.category.dailyRate).toInt()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () => _submitRequest(setSheetState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.saffron,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'BOOK FOR ₹${((_selectedBookingMode == 'Hourly' ? widget.category.hourlyRate * _numberOfHours : widget.category.dailyRate) * (widget.category.commissionPercentage / 100)).toInt()}',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                              ),
                            ),
                          ],
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

  Widget _buildSheetInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              icon: Icon(icon, size: 16, color: AppTheme.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateTotalPrice() {
    if (_selectedBookingMode == 'Hourly') {
      return widget.category.hourlyRate * _numberOfHours;
    } else if (_selectedBookingMode == 'Daily') {
      return widget.category.dailyRate;
    } else {
      // Task-based
      return widget.category.hourlyRate; // Default or base task rate
    }
  }

  Future<void> _submitRequest([StateSetter? setSheetState]) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an address')));
      return;
    }

    // Show confirmation dialog with breakdown
    final total = _calculateTotalPrice();
    final commission = (total * widget.category.commissionPercentage) / 100;
    final toWorker = total - commission;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Booking',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Job Amount',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                          Text(
                            '₹${total.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking Fee (Pay Now)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            '₹${commission.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pay to Worker (Later)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '₹${toWorker.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You will pay the booking fee of ₹${commission.toInt()} now to confirm. The rest should be paid directly to the worker after service.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (setSheetState != null) {
      setSheetState(() {
        _isLoading = true;
      });
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final DateTime scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Validation: Must be at least 1 hour in advance
      if (scheduledDateTime.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking must be scheduled at least 1 hour in advance.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      final result = await ApiService.createBooking(
        labourerId: null, // Broadcast request
        category: widget.category.name,
        date: scheduledDateTime.toUtc(),
        bookingMode: _selectedBookingMode,
        numberOfHours: _selectedBookingMode == 'Hourly' ? _numberOfHours : null,
        notes: _notesController.text,
        address: _selectedAddress,
        houseNumber: _houseController.text,
        landmark: _landmarkController.text,
        latitude: _latitude,
        longitude: _longitude,
        amount: _calculateTotalPrice(),
        minAmount: null,
        maxAmount: null,
      );

      if (mounted) {
        if (result['success']) {
          // Update global current address to the one used for booking
          Provider.of<LocationProvider>(
            context,
            listen: false,
          ).updateCurrentAddress(
            address: _selectedAddress!,
            houseNumber: _houseController.text,
            landmark: _landmarkController.text,
            latitude: _latitude,
            longitude: _longitude,
          );

          // Save address if requested
          if (_saveAddress && _selectedAddress != null) {
            final locationProvider = Provider.of<LocationProvider>(
              context,
              listen: false,
            );
            final alreadySaved = locationProvider.savedLocations.any(
              (loc) =>
                  loc.address == _selectedAddress &&
                  loc.houseNumber == _houseController.text,
            );

            if (!alreadySaved) {
              locationProvider.saveLocation(
                SavedLocation(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  label: _selectedAddress!.split(',').first.trim(),
                  address: _selectedAddress!,
                  houseNumber: _houseController.text,
                  landmark: _landmarkController.text,
                  latitude: _latitude ?? 0.0,
                  longitude: _longitude ?? 0.0,
                ),
              );
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service request sent to all nearby workers!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Return to main screen and switch to bookings tab
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          appState.setTab(1); // Index 1 is Bookings
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Something went wrong'),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (setSheetState != null) {
          setSheetState(() {
            _isLoading = false;
          });
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryBanner(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('mason')) return 'assets/images/mason_banner.png';
    if (name.contains('garden')) return 'assets/images/gardener_banner.png';
    if (name.contains('clean')) return 'assets/images/cleaner_banner.png';
    if (name.contains('plumb')) return 'assets/images/plumber_banner.png';
    if (name.contains('electric'))
      return 'assets/images/electrician_banner.png';
    if (name.contains('paint')) return 'assets/images/painter_banner.png';
    if (name.contains('carpent')) return 'assets/images/carpenter_banner.png';
    return 'assets/images/general_worker_banner.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Fixed Background Illustration
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 380,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          _getCategoryBanner(widget.category.name),
                        ),
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Scrolling Content
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Spacer to reveal image (leaves room for fixed back button)
                        const SizedBox(height: 220),

                        // Glassmorphic Full Form Sheet
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 16.0,
                              sigmaY: 16.0,
                            ),
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.of(context).size.height - 240,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.scaffoldBg.withValues(alpha: 0.0),
                                    AppTheme.scaffoldBg.withValues(alpha: 1.0),
                                  ],
                                  stops: const [0.0, 0.4],
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Setup Booking Header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      28,
                                      24,
                                      32,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Setup your booking',
                                                style: AppTheme.heading2
                                                    .copyWith(fontSize: 22),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'for ${widget.category.name}',
                                                style: AppTheme.bodySmall
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppTheme.textMuted,
                                                      fontSize: 13,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (widget.category.maxHourlyRate >
                                                widget.category.hourlyRate)
                                              Text(
                                                '₹${widget.category.maxHourlyRate.toInt()}',
                                                style: AppTheme.bodySmall
                                                    .copyWith(
                                                      decoration:
                                                          TextDecoration
                                                              .lineThrough,
                                                      color: AppTheme.textMuted,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            Text(
                                              '₹${widget.category.hourlyRate.toInt()}/hr',
                                              style: AppTheme.bodySmall
                                                  .copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 15,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // The rest of the form
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionLabel('BOOKING TYPE'),
                                        const SizedBox(height: 16),
                                        _buildBookingTypeCards(),

                                        if (_selectedBookingMode ==
                                            'Hourly') ...[
                                          const SizedBox(height: 24),
                                          _buildSectionLabel('DURATION'),
                                          const SizedBox(height: 12),
                                          _buildDurationCard(),
                                        ],

                                        const SizedBox(height: 24),
                                        _buildSectionLabel('SCHEDULE'),
                                        const SizedBox(height: 16),
                                        _buildDatePills(),
                                        const SizedBox(height: 16),
                                        _buildTimeCard(),

                                        const SizedBox(height: 32),
                                        _buildSectionLabel('NOTES'),
                                        const SizedBox(height: 16),
                                        _buildNotesCard(),

                                        const SizedBox(height: 40),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fixed Back Button placed on top of scrolling content
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.shadowMd,
                              border: Border.all(
                                color: AppTheme.divider.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.textPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Area
          _buildBottomBanner(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.textMuted,
      ),
    );
  }

  Widget _buildBookingTypeCards() {
    return Row(
      children: widget.category.supportedModes.map((mode) {
        final isSelected = _selectedBookingMode == mode;
        IconData modeIcon;
        String modeTitle;
        String modeDesc;
        Color activeColor;
        Color bgColor;

        if (mode == 'Hourly') {
          modeIcon = Icons.timer_outlined;
          modeTitle = 'Hourly';
          modeDesc = 'for quick tasks';
          activeColor = AppTheme.saffron;
          bgColor = isSelected ? const Color(0xFFFFE6D5).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.05);
        } else if (mode == 'Daily') {
          modeIcon = Icons.calendar_today_outlined;
          modeTitle = 'Daily';
          modeDesc = 'for a full day';
          activeColor = AppTheme.saffron;
          bgColor = isSelected ? const Color(0xFFFFE6D5).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.05);
        } else {
          modeIcon = Icons.assignment_outlined;
          modeTitle = mode;
          modeDesc = 'Per job';
          activeColor = AppTheme.saffron;
          bgColor = isSelected ? const Color(0xFFFFE6D5).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.05);
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedBookingMode = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(
                left: mode == widget.category.supportedModes.first ? 0 : 8,
                right: mode == widget.category.supportedModes.last ? 0 : 8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? activeColor.withValues(alpha: 0.4) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ] : [],
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Icon(
                      modeIcon,
                      color: isSelected ? Colors.white : AppTheme.textSecondary.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    modeTitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? activeColor : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    modeDesc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? activeColor.withValues(alpha: 0.8) : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$_numberOfHours',
                    style: GoogleFonts.inter(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HOURS',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Custom Slider with metallic style
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.saffron,
                  inactiveTrackColor: AppTheme.textPrimary.withValues(alpha: 0.05),
                  overlayColor: AppTheme.saffron.withValues(alpha: 0.1),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 4,
                    pressedElevation: 8,
                  ),
                  trackHeight: 6,
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _numberOfHours.toDouble().clamp(1.0, 6.0),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  onChanged: (val) => setState(() => _numberOfHours = val.toInt()),
                ),
              ),
              const SizedBox(height: 8),
              // Ticks (Precision Scale)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: List.generate(26, (index) {
                    final bool isMajor = index % 5 == 0;
                    final double currentVal = 1 + (index / 5);
                    
                    return Expanded(
                      child: Center(
                        child: Container(
                          width: isMajor ? 2.0 : 1.0,
                          height: isMajor ? 12 : 6,
                          decoration: BoxDecoration(
                            color: _numberOfHours >= currentVal 
                                ? AppTheme.saffron 
                                : AppTheme.textMuted.withValues(alpha: isMajor ? 0.4 : 0.2),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePills() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected =
              _selectedDate.day == date.day &&
              _selectedDate.month == date.month;
          final dayName =
              index == 0
                  ? 'Today'
                  : (index == 1
                      ? 'Tom'
                      : _getDayName(date.weekday).substring(0, 3));

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 72,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.textPrimary : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.divider,
                  width: 1.5,
                ),
                boxShadow: isSelected ? AppTheme.shadowLg : AppTheme.shadowSm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color:
                          isSelected
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _getMonthName(date.month).substring(0, 3).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppTheme.textMuted,
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

  Widget _buildTimeCard() {
    final h = _selectedTime.hour;
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final timeString =
        "${hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}";

    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
          boxShadow: AppTheme.shadowMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.saffron.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.alarm_on_rounded,
                color: AppTheme.saffron,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Time',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  timeString,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_calendar_rounded,
                color: AppTheme.textLight,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowMd,
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Any specific tools or details the worker should know?',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.textMuted.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
          suffixIcon: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.sticky_note_2_outlined,
              color: AppTheme.divider,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBanner() {
    final total = _calculateTotalPrice();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, -12),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${total.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.saffron.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _selectedBookingMode == 'Hourly'
                          ? '₹${widget.category.hourlyRate.toInt()}/hr'
                          : 'Fixed Rate',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.saffron,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showLocationBottomSheet(),
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textPrimary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Select Work Location',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}


