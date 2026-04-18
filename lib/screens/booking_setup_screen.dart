import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import 'searching_worker_screen.dart';

class BookingSetupScreen extends StatefulWidget {
  final ServiceCategory category;
  final String bookingMode;
  final DateTime scheduledTime;
  final int? numberOfHours; // Only for Hourly
  final String address;
  final double latitude;
  final double longitude;
  final double amount;
  final int numberOfWorkers;
  final String workType;
  final String? taskImageBase64;

  const BookingSetupScreen({
    super.key,
    required this.category,
    required this.bookingMode,
    required this.scheduledTime,
    this.numberOfHours,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.amount,
    this.numberOfWorkers = 1,
    this.workType = '',
    this.taskImageBase64,
  });

  @override
  State<BookingSetupScreen> createState() => _BookingSetupScreenState();
}

class _BookingSetupScreenState extends State<BookingSetupScreen> {
  final TextEditingController _problemTitleController = TextEditingController();
  final TextEditingController _problemDescriptionController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleBookNow() async {
    if (_problemTitleController.text.isEmpty || _houseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields (Title and House No)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.createBooking(
        category: widget.category.name,
        bookingMode: widget.bookingMode,
        date: widget.scheduledTime,
        numberOfHours: widget.numberOfHours,
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
        amount: widget.amount,
        problemTitle: _problemTitleController.text,
        notes: _problemDescriptionController.text,
        houseNumber: _houseController.text,
        landmark: _landmarkController.text,
        numberOfWorkers: widget.numberOfWorkers,
        workType: widget.workType,
        taskImage: widget.taskImageBase64,
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SearchingWorkerScreen(
                category: widget.category,
                address: widget.address,
                scheduledTime: widget.scheduledTime,
                bookingData: result['data'],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to create booking')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('What\'s the problem?'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _problemTitleController,
                          hint: 'Short title (e.g. Broken Tap)',
                          icon: Icons.edit_note_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _problemDescriptionController,
                          hint: 'Describe the issue in detail...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Confirm Address Details'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _houseController,
                          hint: 'House / Flat / Block No.',
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _landmarkController,
                          hint: 'Landmark (Optional)',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/branding_banner.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Setup your booking',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'for ${widget.category.name}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    widget.bookingMode == 'Hourly' 
                        ? '₹${widget.amount.toInt()}/hr'
                        : '₹${widget.amount.toInt()}/day',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A9782),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.roboto(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF4A9782), size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleBookNow,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A9782),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Book Now',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
