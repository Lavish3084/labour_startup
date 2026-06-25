import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/service_category.dart';
import '../models/labourer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/pattern_painter.dart';
import 'main_screen.dart';
import 'track_status_screen.dart';

class WorkerAssignedScreen extends StatelessWidget {
  final ServiceCategory category;
  final String address;
  final DateTime scheduledTime;
  final Map<String, dynamic> bookingData;
  final Labourer worker;

  const WorkerAssignedScreen({
    super.key,
    required this.category,
    required this.address,
    required this.scheduledTime,
    required this.bookingData,
    required this.worker,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 30),
            _buildMainCard(context),
            const SizedBox(height: 30),
            _buildTrackButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: const ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.50, 0.00),
          end: Alignment(0.50, 1.00),
          colors: [Color(0xFF06644A), Color(0xFF4A9782)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success Icon Circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF06644A),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Worker Assigned',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: ShapeDecoration(
        color: const Color(0xFFF2F2F2),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFD2D2D2)),
          borderRadius: BorderRadius.circular(17),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          _buildWorkerInfoCard(context),
          const SizedBox(height: 20),
          _buildActionButtons(context),
          const SizedBox(height: 25),
          _buildWorkDetailsSection(context),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: Color(0xFFD0D0D0)),
          ),
          _buildAmountSection(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWorkerInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Worker Image
            Container(
              width: 56,
              height: 56,
              decoration: ShapeDecoration(
                image: DecorationImage(
                  image:
                      worker.imageUrl.isNotEmpty
                          ? NetworkImage(worker.imageUrl)
                          : const NetworkImage("https://placehold.co/100x100"),
                  fit: BoxFit.cover,
                ),
                shape: OvalBorder(
                  side: const BorderSide(width: 1, color: Color(0xFF4A9782)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.name} Worker',
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.40,
                    ),
                  ),
                ],
              ),
            ),
            // Rating
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Color(0xFFFCD541), size: 16),
                const SizedBox(width: 2),
                Text(
                  '${worker.rating}',
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF595959),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(
                          bookingId: bookingData['_id'],
                          otherUserName: worker.name,
                          otherUserPhoto: worker.imageUrl,
                        ),
                  ),
                );
              },
              child: Container(
                height: 41,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF5FFFC),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFF4A9782)),
                    borderRadius: BorderRadius.circular(25.50),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Message',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4A9782),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final phone = worker.phoneNumber;
              if (phone != null && phone.isNotEmpty) {
                final url = 'tel:$phone';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Worker's phone number not available"),
                  ),
                );
              }
            },
            child: Container(
              width: 50,
              height: 41,
              decoration: ShapeDecoration(
                color: const Color(0xFF4A9782),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Center(
                child: Icon(Icons.call, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDetailsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Details :',
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.40,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailColumn('Service', category.name),
              _buildVerticalDivider(),
              _buildDetailColumn(
                'Duration',
                bookingData['bookingMode'] == 'Hourly'
                    ? '${bookingData['numberOfHours']} Hours'
                    : 'Daily',
              ),
              _buildVerticalDivider(),
              _buildDetailColumn(
                'Date',
                DateFormat('dd MMMM').format(scheduledTime),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailColumn(
                'Arrival Time',
                DateFormat('hh:mm a').format(scheduledTime),
              ),
              _buildVerticalDivider(),
              Expanded(flex: 2, child: _buildDetailColumn('Location', address)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.40,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 33,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFCCCCCC),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    final amount = bookingData['amount'] ?? bookingData['minAmount'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount Due :',
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.40,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pay to worker after work completion',
                style: GoogleFonts.roboto(
                  color: const Color(0xFF2D2D2D),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Text(
            '₹$amount',
            style: GoogleFonts.roboto(
              color: const Color(0xFF47907D),
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) =>
                        TrackStatusScreen(bookingId: bookingData['_id']),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A9782),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: Text(
            'Track Status',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
            ),
          ),
        ),
      ),
    );
  }
}
