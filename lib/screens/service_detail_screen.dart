import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/floating_cart_banner.dart';
import 'cart_screen.dart';

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

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  List<dynamic> _faqs = [];
  bool _isLoadingFaqs = true;
  int _selectedMinutes = 60;

  double _rating = 0.0;
  int _totalReviews = 0;
  bool _isLoadingRating = true;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
    _loadLabourerData();
  }

  Future<void> _loadLabourerData() async {
    try {
      final labourers = await ApiService.getLabourers();
      final categoryLabourers =
          labourers.where((l) => l.category == widget.category.name).toList();

      if (categoryLabourers.isNotEmpty) {
        double totalRating = 0;
        int reviewCount = 0;
        for (var l in categoryLabourers) {
          totalRating += l.rating;
          reviewCount += l.jobsCompleted ?? 15;
        }

        if (mounted) {
          setState(() {
            _rating = totalRating / categoryLabourers.length;
            _totalReviews =
                reviewCount > 0 ? reviewCount : categoryLabourers.length * 15;
            _isLoadingRating = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _rating = 0.0;
            _totalReviews = 0;
            _isLoadingRating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rating = 0.0;
          _totalReviews = 0;
          _isLoadingRating = false;
        });
      }
    }
  }

  Future<void> _loadFaqs() async {
    try {
      final faqs = await ApiService.getFaqsForCategory(widget.category.name);
      if (mounted) {
        setState(() {
          _faqs = faqs.isNotEmpty ? faqs : _getFallbackFaqs();
          _isLoadingFaqs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _faqs = _getFallbackFaqs();
          _isLoadingFaqs = false;
        });
      }
    }
  }

  List<dynamic> _getFallbackFaqs() {
    return [
      {
        'question': 'Can I book a recurring service?',
        'answer':
            'Yes, you can easily schedule recurring services from the booking options.',
      },
      {
        'question': 'How can I trust your service?',
        'answer':
            'All our professionals are background verified and highly trained.',
      },
      {
        'question': 'Do I need to provide all the cleaning equipment?',
        'answer':
            'No, our professionals carry their own specialized equipment and cleaning supplies.',
      },
      {
        'question': 'How are the prices calculated?',
        'answer':
            'Prices are calculated based on the standard hourly rate and the total time required.',
      },
      {
        'question': 'How do I contact support?',
        'answer':
            'You can reach out to our 24/7 customer support via the Help section.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleAndPricing(),
                      if (!widget.isInstant) ...[
                        const SizedBox(height: 24),
                        _buildScheduleSection(),
                      ],
                      const SizedBox(height: 12),
                      _buildRatingRow(),
                      const SizedBox(height: 32),
                      _buildDescriptionSection(),
                      const SizedBox(height: 32),
                      _buildIncludesExcludesSection(),
                      const SizedBox(height: 32),
                      _buildHowItsDoneSection(),
                      const SizedBox(height: 32),
                      _buildFaqsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FloatingCartBanner(bottomInset: 0),
                _buildBottomActionCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_getBannerImage()),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _getBannerImage() {
    final cat = widget.category.name.toLowerCase();
    switch (cat) {
      case 'cleanup':
        return 'assets/images/service_banner_washing.png';
      case 'electrician':
        return 'assets/images/banner_electrician.png';
      case 'garden':
        return 'assets/images/banner_garden.png';
      case 'general':
        return 'assets/images/banner_general.png';
      case 'masonry':
        return 'assets/images/banner_masonry.png';
      case 'moving':
        return 'assets/images/banner_moving.png';
      case 'painting':
        return 'assets/images/banner_painting.png';
      case 'plumbing':
        return 'assets/images/banner_plumbing.png';
      default:
        return 'assets/images/service_banner_washing.png';
    }
  }

  Widget _buildTitleAndPricing() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category.name,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${widget.category.hourlyRate.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.category.maxHourlyRate > widget.category.hourlyRate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '₹${widget.category.maxHourlyRate.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.brandGreenMain.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_selectedMinutes > 30) {
                        setState(() => _selectedMinutes -= 30);
                      }
                    },
                    child: const Icon(
                      Icons.remove,
                      color: AppTheme.brandGreenMain,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$_selectedMinutes',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandGreenMain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedMinutes += 30);
                    },
                    child: const Icon(
                      Icons.add,
                      color: AppTheme.brandGreenMain,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Minutes',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandGreenMain.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppTheme.brandGreenMain,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.brandGreenMain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Choose Date',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppTheme.brandGreenMain,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Time',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.brandGreenMain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Choose Time',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    if (_isLoadingRating) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.brandGreenMain,
        ),
      );
    }
    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xFFFCD541), size: 18),
        const SizedBox(width: 4),
        Text(
          '${_rating.toStringAsFixed(1)} (${_totalReviews > 1000 ? '${(_totalReviews / 1000).toStringAsFixed(1)}k' : _totalReviews} ratings)',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional ${widget.category.name} Services',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.category.description,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  List<String> _getCategoryIncludes() {
    final cat = widget.category.name.toLowerCase();
    switch (cat) {
      case 'cleanup':
        return [
          'Deep cleaning of all surfaces',
          'Dusting and wiping',
          'Floor mopping',
        ];
      case 'electrician':
        return [
          'Wiring repairs and installation',
          'Switchboard fixing',
          'Appliance testing',
        ];
      case 'plumbing':
        return ['Leak detection', 'Pipe repairs', 'Faucet replacement'];
      case 'painting':
        return [
          'Surface preparation',
          'Premium paint application',
          'Post-paint cleanup',
        ];
      case 'moving':
        return [
          'Careful packing',
          'Safe transportation',
          'Unpacking assistance',
        ];
      case 'garden':
        return ['Lawn mowing', 'Plant trimming', 'Weed removal'];
      case 'masonry':
        return ['Brick laying', 'Surface smoothing', 'Concrete repair'];
      default:
        return [
          'Standard service execution',
          'Professional equipment',
          'Basic cleanup',
        ];
    }
  }

  List<String> _getCategoryExcludes() {
    final cat = widget.category.name.toLowerCase();
    switch (cat) {
      case 'cleanup':
        return [
          'Cleaning outdoor areas',
          'Waste disposal',
          'Deep stain removal',
        ];
      case 'electrician':
        return [
          'Major structural rewiring',
          'Providing new appliances',
          'Wall breaking',
        ];
      case 'plumbing':
        return [
          'Underground pipe replacement',
          'Providing new fixtures',
          'Major excavation',
        ];
      case 'painting':
        return [
          'Providing premium imported paints',
          'Wall structural repairs',
          'Moving heavy furniture',
        ];
      case 'moving':
        return [
          'Providing packing boxes',
          'Inter-state transportation',
          'Disassembling complex furniture',
        ];
      case 'garden':
        return ['Providing new plants', 'Tree removal', 'Major landscaping'];
      case 'masonry':
        return [
          'Providing raw materials',
          'Demolition work',
          'Painting over masonry',
        ];
      default:
        return [
          'Material costs',
          'Major structural changes',
          'Tasks outside scope',
        ];
    }
  }

  Widget _buildIncludesExcludesSection() {
    final includes = _getCategoryIncludes();

    final excludes = _getCategoryExcludes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Includes',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...includes.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: AppTheme.brandGreenMain,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Does not include',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...excludes.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getCategorySteps() {
    final cat = widget.category.name.toLowerCase();
    switch (cat) {
      case 'cleanup':
        return [
          {
            'title': 'Utensils washing',
            'desc': 'The dirty utensils are washed thoroughly',
            'image': 'assets/images/step_utensils.png',
          },
          {
            'title': 'Reracking',
            'desc': 'The washed utensils are dried and rearranged',
            'image': 'assets/images/step_reracking.png',
          },
          {
            'title': 'Utensils sink',
            'desc':
                'The utensils sink is cleaned after washing up of the utensils',
            'image': 'assets/images/step_sink.png',
          },
          {
            'title': 'Dishwashing area',
            'desc':
                'The dishwashing area is cleaned and dried off at the end of the process',
            'image': 'assets/images/step_dishwashing.png',
          },
        ];
      case 'electrician':
        return [
          {
            'title': 'Inspection',
            'desc': 'Checking the electrical panel and components',
            'image': 'assets/images/step_tester.png',
          },
          {
            'title': 'Repairing',
            'desc': 'Fixing the identified electrical issues',
            'image': 'assets/images/step_wrench.png',
          },
        ];
      case 'painting':
        return [
          {
            'title': 'Preparation',
            'desc': 'Taping and covering surfaces to protect them',
            'image': 'assets/images/step_tape.png',
          },
          {
            'title': 'Painting',
            'desc': 'Applying the chosen premium color',
            'image': 'assets/images/step_paint_roller.png',
          },
        ];
      case 'moving':
        return [
          {
            'title': 'Packing',
            'desc': 'Carefully packing your items in secure boxes',
            'image': 'assets/images/step_box.png',
          },
          {
            'title': 'Transporting',
            'desc': 'Moving boxes securely to the new location',
            'image': 'assets/images/step_truck.png',
          },
        ];
      case 'plumbing':
        return [
          {
            'title': 'Diagnosis',
            'desc': 'Locating the pipe leak or water issue',
            'image': 'assets/images/step_drop.png',
          },
          {
            'title': 'Fixing',
            'desc': 'Replacing or repairing the pipe and fixtures',
            'image': 'assets/images/step_wrench.png',
          },
        ];
      default:
        return [
          {
            'title': 'Assessment',
            'desc': 'Evaluating the required work for the task',
            'image': 'assets/images/step_clipboard.png',
          },
          {
            'title': 'Execution',
            'desc': 'Performing the required professional service',
            'image': 'assets/images/step_wrench.png',
          },
        ];
    }
  }

  Widget _buildHowItsDoneSection() {
    final steps = _getCategorySteps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it\'s done?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        ...steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Image.asset(
                      step['image']!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['desc']!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqsSection() {
    if (_isLoadingFaqs) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAQs',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
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
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isInCart = cartProvider.items.any(
          (item) => item.category.name == widget.category.name,
        );

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 16 + bottomPadding,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F6),
            border: Border(
              top: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (isInCart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                      return;
                    }

                    if (!widget.isInstant &&
                        (_selectedDate == null || _selectedTime == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select Date and Time'),
                        ),
                      );
                      return;
                    }

                    final pickedWorkType = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder:
                          (context) => const WorkTypePickerSheet(
                            options: [
                              'Emergency Repair',
                              'Standard Maintenance',
                              'New Installation',
                              'Periodic Checkup',
                              'Other (please specify)',
                            ],
                            selected: null,
                          ),
                    );

                    if (pickedWorkType == null) return;

                    final cartItem = CartItem(
                      category: widget.category,
                      durationMinutes: _selectedMinutes,
                      isInstant: widget.isInstant,
                      scheduledDate: _selectedDate,
                      scheduledTime: _selectedTime,
                      workType: pickedWorkType,
                    );

                    if (!context.mounted) return;

                    Provider.of<CartProvider>(
                      context,
                      listen: false,
                    ).addItem(cartItem);
                    
                    // Stay on screen and let the floating cart banner appear!
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGreenMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isInCart ? 'Go to Cart' : 'Add to Cart',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            widget.question,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.remove : Icons.add,
            color: Colors.black54,
            size: 20,
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  bottom: 20.0,
                ),
                child: Text(
                  widget.answer,
                  textAlign: TextAlign.start,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
