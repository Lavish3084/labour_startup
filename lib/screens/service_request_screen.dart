import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import 'location_search_screen.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class ServiceRequestScreen extends StatefulWidget {
  final ServiceCategory category;

  const ServiceRequestScreen({Key? key, required this.category})
    : super(key: key);

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
    _selectedBookingMode = widget.category.supportedModes.first;
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
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
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 24),
                      Text(
                        'Where should we come?',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Saved Addresses List
                      Consumer<LocationProvider>(
                        builder: (context, provider, child) {
                          if (provider.savedLocations.isEmpty)
                            return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved Addresses',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
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
                                      child: Container(
                                        width: 150,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? Colors.blueAccent
                                                      .withOpacity(0.1)
                                                  : Colors.white,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Colors.blueAccent
                                                    : Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                  Icons.home_outlined,
                                                  size: 16,
                                                  color:
                                                      isSelected
                                                          ? Colors.blueAccent
                                                          : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    loc.label,
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color:
                                                          isSelected
                                                              ? Colors
                                                                  .blueAccent
                                                              : Colors.black,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              loc.address,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey[600],
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
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),

                      // Address Picker
                      Text(
                        'Work Address',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          await _pickAddress();
                          setSheetState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  _selectedAddress == null
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAddress ?? 'Select work location',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color:
                                        _selectedAddress == null
                                            ? Colors.grey
                                            : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedAddress == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            'Please select an address',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // House/Flat Number
                      Text(
                        'Flat / House / Floor Number',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _houseController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Flat 402, 4th Floor',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Landmark
                      Text(
                        'Landmark (Optional)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _landmarkController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Near the main gate',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Save Address Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _saveAddress,
                            onChanged: (val) {
                              setSheetState(() {
                                _saveAddress = val ?? false;
                              });
                            },
                            activeColor: Colors.blueAccent,
                          ),
                          Text(
                            'Save this address for future use',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Confirm Request',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
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

  Future<void> _submitRequest() async {
    if (_selectedAddress == null || _houseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select address and enter house number'),
        ),
      );
      return;
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

      final success = await ApiService.createBooking(
        labourerId: null, // Broadcast request
        category: widget.category.name,
        date: scheduledDateTime,
        bookingMode: _selectedBookingMode,
        numberOfHours: _selectedBookingMode == 'Hourly' ? _numberOfHours : null,
        notes: _notesController.text,
        address: _selectedAddress,
        houseNumber: _houseController.text,
        landmark: _landmarkController.text,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        if (success) {
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
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Close bottom sheet
          Navigator.pop(context); // Go back to Home
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Service',
          style: GoogleFonts.inter(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: const NetworkImage(
                'https://randomuser.me/api/portraits/men/32.jpg',
              ),
              backgroundColor: Colors.grey[200],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('BOOKING TYPE'),
              const SizedBox(height: 12),
              _buildBookingTypeSelection(),
              const SizedBox(height: 32),
              if (_selectedBookingMode == 'Hourly') ...[
                _buildDurationHeader(),
                const SizedBox(height: 16),
                _buildDurationSlider(),
                const SizedBox(height: 32),
              ],
              _buildSectionTitle('SCHEDULE'),
              const SizedBox(height: 12),
              _buildDateSelection(),
              const SizedBox(height: 16),
              _buildTimeSelection(),
              const SizedBox(height: 32),
              _buildSectionTitle('JOB DETAILS'),
              const SizedBox(height: 12),
              _buildJobDetailsTags(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 40),
              _buildActionButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBookingTypeSelection() {
    return Row(
      children:
          widget.category.supportedModes.map((mode) {
            final isSelected = _selectedBookingMode == mode;
            final isHourly = mode == 'Hourly';
            final isDaily = mode == 'Daily';

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedBookingMode = mode),
                child: Container(
                  margin: EdgeInsets.only(
                    left: mode == widget.category.supportedModes.first ? 0 : 8,
                    right: mode == widget.category.supportedModes.last ? 0 : 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected
                              ? const Color(0xFFFF6B2C)
                              : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFFFF6B2C).withOpacity(0.1)
                                      : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isHourly
                                  ? Icons.timer_outlined
                                  : isDaily
                                  ? Icons.calendar_today_outlined
                                  : Icons.task_outlined,
                              color:
                                  isSelected
                                      ? const Color(0xFFFF6B2C)
                                      : const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            mode,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHourly
                                ? 'Best for short tasks'
                                : isDaily
                                ? 'Full day projects'
                                : 'Fixed scope job',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFFFF6B2C),
                            size: 18,
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

  Widget _buildDurationHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle('DURATION'),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$_numberOfHours ',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF6B2C),
                ),
              ),
              TextSpan(
                text: 'hours',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF6B2C),
              inactiveTrackColor: const Color(0xFFF1F5F9),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFFF6B2C).withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
              ),
              trackHeight: 6,
            ),
            child: Slider(
              value: _numberOfHours.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (value) {
                setState(() => _numberOfHours = value.toInt());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  ['1H', '3H', '6H', '9H', '12H'].map((label) {
                    final val = int.parse(label.replaceAll('H', ''));
                    final isSelected =
                        (val == 6 && _numberOfHours == 6) ||
                        (val == 1 && _numberOfHours == 1) ||
                        (val == 12 && _numberOfHours == 12) ||
                        (val == 3 && _numberOfHours == 3) ||
                        (val == 9 && _numberOfHours == 9);

                    return Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected
                                ? const Color(0xFFFF6B2C)
                                : const Color(0xFFCBD5E1),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isToday = index == 0;
          final isSelected =
              _selectedDate.day == date.day &&
              _selectedDate.month == date.month &&
              _selectedDate.year == date.year;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'TODAY' : _getDayName(date.weekday).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.8)
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.white : const Color(0xFF1E293B),
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

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildTimeSelection() {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time_filled,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              _selectedTime.format(context),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Icon(Icons.unfold_more, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailsTags() {
    // Generate some tags based on category
    final tags = _getTagsForCategory(widget.category.name);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          tags.map((tag) {
            final isSelected = tag == 'Repair'; // Mock selection or use a set
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFFFFEFE6)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFFF6B2C).withOpacity(0.3)
                          : Colors.transparent,
                ),
              ),
              child: Text(
                tag,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected
                          ? const Color(0xFFFF6B2C)
                          : const Color(0xFF64748B),
                ),
              ),
            );
          }).toList(),
    );
  }

  List<String> _getTagsForCategory(String category) {
    switch (category) {
      case 'Plumbing':
        return ['Plumbing', 'Electrical', 'Cleaning', 'Repair'];
      case 'Electric':
        return ['Wiring', 'Installation', 'Repair', 'Switchboard'];
      default:
        return ['General', 'Installation', 'Repair', 'Maintenance'];
    }
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 4,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText:
              'Describe the job in detail (e.g., Leaking pipe in the master bathroom)...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showLocationBottomSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Request Laborer Now',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
