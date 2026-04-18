import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_category.dart';
import '../utils/app_theme.dart';
import 'service_request_screen.dart';
import 'task_instructions_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceCategory category;

  const ServiceDetailScreen({super.key, required this.category});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBannerImage(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBookingBadge(),
                      const SizedBox(height: 16),
                      _buildTitleAndRating(),
                      const SizedBox(height: 24),
                      _buildTabs(),
                      const SizedBox(height: 20),
                      _buildTabContent(),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Spacing for sticky bottom bar
              ],
            ),
          ),

          // Back Button Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(
                    0xFF5EA28F,
                  ), // Matching the green in the screenshot icon
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Sticky Bottom Bar
          _buildBottomActionCard(),
        ],
      ),
    );
  }

  Widget _buildBannerImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/upper_setup_booking_poster.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBookingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3F1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '15 People booked this service in last 24hrs',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF4A9782),
        ),
      ),
    );
  }

  Widget _buildTitleAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.category.name,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFCD541), size: 20),
            const SizedBox(width: 4),
            Text(
              '4.2 (186 reviews)',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4A9782),
        unselectedLabelColor: Colors.black,
        indicatorColor: const Color(0xFF4A9782),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [Tab(text: 'About'), Tab(text: 'Review')],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 600, // Fixed height for tab content scrolling
      child: TabBarView(
        controller: _tabController,
        children: [_buildAboutSection(), _buildReviewsPlaceholder()],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'About Service',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final textStyle = GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            );

            if (_isDescriptionExpanded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.category.description, style: textStyle),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _isDescriptionExpanded = false),
                    child: const Text(
                      'Read Less',
                      style: TextStyle(
                        color: Color(0xFF4A9782),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              );
            }

            final span = TextSpan(text: widget.category.description, style: textStyle);
            final tp = TextPainter(
              text: span,
              maxLines: 3,
              textDirection: TextDirection.ltr,
            );
            tp.layout(maxWidth: constraints.maxWidth);

            if (tp.didExceedMaxLines) {
              final position = tp.getPositionForOffset(Offset(constraints.maxWidth, tp.height));
              int endOffset = position.offset;
              
              // Key: Use a non-breaking space to keep "Read More" together
              const readMoreText = '\u00A0Read\u00A0More';
              
              // Binary search to find the exact point where truncated text + " Read More" fits in 3 lines
              int low = 0;
              int high = endOffset;
              int bestIndex = 0;
              
              while (low <= high) {
                int mid = (low + high) ~/ 2;
                final testText = widget.category.description.substring(0, mid);
                
                // Lay out as a combined span to match RichText behavior
                final testSpan = TextSpan(
                  children: [
                    TextSpan(text: testText, style: textStyle),
                    TextSpan(text: readMoreText, style: textStyle),
                  ],
                );
                
                final testTp = TextPainter(
                  text: testSpan,
                  maxLines: 3,
                  textDirection: TextDirection.ltr,
                );
                // Increase margin to 30.0 to be absolutely sure it doesn't wrap
                testTp.layout(maxWidth: constraints.maxWidth - 30.0);
                
                if (testTp.didExceedMaxLines) {
                  high = mid - 1;
                } else {
                  bestIndex = mid;
                  low = mid + 1;
                }
              }

              final truncatedText = widget.category.description.substring(0, bestIndex).trim();

              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: truncatedText, style: textStyle),
                    TextSpan(
                      text: readMoreText,
                      style: const TextStyle(
                        color: Color(0xFF4A9782),
                        fontWeight: FontWeight.w400,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          setState(() => _isDescriptionExpanded = true);
                        },
                    ),
                  ],
                ),
              );
            }

            return Text(widget.category.description, style: textStyle);
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Know how Will Works',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/category_screen_banner.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsPlaceholder() {
    return Center(
      child: Text(
        'No reviews yet',
        style: GoogleFonts.inter(color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomActionCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starting from',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${widget.category.dailyRate.toInt()}/Day',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4A9782),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            TaskInstructionsScreen(category: widget.category),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Color(0xFF4A9782),
                ),
              ),
              label: const Text('Book Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9782),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
