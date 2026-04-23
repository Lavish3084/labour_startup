import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/labourer.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class BookingCompleteScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingCompleteScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingCompleteScreen> createState() => _BookingCompleteScreenState();
}

class _BookingCompleteScreenState extends State<BookingCompleteScreen> {
  double _rating = 0;
  bool _isSubmitting = false;
  bool _hasRated = false;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await ApiService.rateWorker(
        widget.booking['_id'],
        _rating,
        '', // Optional comment
      );

      if (success) {
        setState(() => _hasRated = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit rating. Please try again.')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labourerData = widget.booking['labourer'];
    final labourer = labourerData != null ? Labourer.fromJson(labourerData) : null;
    final amount = widget.booking['amount'] ?? 0;
    final workerName = labourer?.name ?? "Worker";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Booking Complete',
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(flex: 1),
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4A9782),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Done',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹$amount paid directly to ${workerName.split(' ')[0]}',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: const Color(0xFF8D8D8D),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.40,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Thank you for using WILL',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF47907D),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const Spacer(flex: 2),
            // Rating Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Rate your experience with $workerName',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF4A9782)),
                                image: labourer?.imageUrl != null && labourer!.imageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(labourer.imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: labourer?.imageUrl == null || labourer!.imageUrl.isEmpty
                                  ? const Icon(Icons.person, color: Color(0xFF4A9782))
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workerName,
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    labourer?.category ?? 'Worker',
                                    style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStarRating(),
                        if (!_hasRated)
                          TextButton(
                            onPressed: _isSubmitting ? null : _submitRating,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Submit Rating'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            // Go to Home Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9782),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Go to Home',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: _hasRated ? null : () {
            setState(() {
              _rating = index + 1.0;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: const Color(0xFFFFB300),
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}
