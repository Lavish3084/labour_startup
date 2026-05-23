import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_category.dart';
import '../models/labourer.dart';
import '../services/api_service.dart';
import 'task_instructions_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceCategory category;
  final bool isInstant;

  const ServiceDetailScreen({
    super.key,
    required this.category,
    this.isInstant = false,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;
  
  List<LabourerReview> _allReviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoadingReviews = true;

  List<dynamic> _faqs = [];
  bool _isLoadingFaqs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadLabourerData();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    try {
      final faqs = await ApiService.getFaqsForCategory(widget.category.name);
      if (mounted) {
        setState(() {
          _faqs = faqs;
          _isLoadingFaqs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading FAQs: $e');
      if (mounted) {
        setState(() {
          _isLoadingFaqs = false;
        });
      }
    }
  }

  void _handleTabSelection() {
    setState(() {});
  }

  Future<void> _loadLabourerData() async {
    try {
      final labourers = await ApiService.getLabourers();
      final categoryLabourers = labourers.where(
        (l) => l.category.trim().toLowerCase() == widget.category.name.trim().toLowerCase()
      ).toList();

      List<LabourerReview> reviews = [];
      double totalRating = 0.0;
      int ratingCount = 0;

      for (var l in categoryLabourers) {
        if (l.reviews.isNotEmpty) {
          for (var r in l.reviews) {
            reviews.add(r);
            totalRating += r.rating;
            ratingCount++;
          }
        }
      }

      // Sort reviews by date descending
      reviews.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allReviews = reviews;
          _totalReviews = ratingCount;
          _averageRating = ratingCount > 0 ? (totalRating / ratingCount) : 0.0;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
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
                      _tabController.index == 0
                          ? _buildAboutSection()
                          : _buildReviewsSection(),
                    ],
                  ),
                ),
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
        ],
      ),
      bottomNavigationBar: _buildBottomActionCard(),
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
        Expanded(
          child: Text(
            widget.category.name,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFCD541), size: 20),
            const SizedBox(width: 4),
            Text(
              _isLoadingReviews
                  ? '... (...)'
                  : '${_averageRating > 0 ? _averageRating.toStringAsFixed(1) : "0.0"} ($_totalReviews ${_totalReviews == 1 ? "review" : "reviews"})',
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

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9782)),
          ),
        ),
      );
    }

    if (_allReviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F3F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: Color(0xFF4A9782),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No reviews yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to book and rate this service!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Reviews ($_totalReviews)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFCD541), size: 18),
                const SizedBox(width: 4),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._allReviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(LabourerReview review) {
    final dateStr = '${review.date.day.toString().padLeft(2, '0')}/${review.date.month.toString().padLeft(2, '0')}/${review.date.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE8F3F1),
                    child: Text(
                      review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'C',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A9782),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFCD541),
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ],
        ],
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
        _buildFaqsSection(),
      ],
    );
  }

  Widget _buildFaqsSection() {
    if (_isLoadingFaqs) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9782)),
          ),
        ),
      );
    }

    if (_faqs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'Frequently Asked Questions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ..._faqs.map((faq) {
          final question = faq['question']?.toString() ?? '';
          final answer = faq['answer']?.toString() ?? '';
          return FaqAccordionItem(question: question, answer: answer);
        }),
      ],
    );
  }

  Widget _buildBottomActionCard() {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 100 + bottomPadding,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + bottomPadding,
      ),
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
                          TaskInstructionsScreen(
                            category: widget.category,
                            isInstant: widget.isInstant,
                          ),
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
    );
  }
}

class FaqAccordionItem extends StatefulWidget {
  final String question;
  final String answer;

  const FaqAccordionItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<FaqAccordionItem> createState() => _FaqAccordionItemState();
}

class _FaqAccordionItemState extends State<FaqAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            widget.question,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: const Color(0xFF4A9782),
            size: 24,
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Text(
                widget.answer,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
