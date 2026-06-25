import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import '../models/service_category.dart';
import 'service_request_screen.dart';
import 'service_detail_screen.dart';
import 'history_screen.dart';
import '../providers/location_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/address_selection_sheet.dart';
import '../providers/app_state_provider.dart';
import '../services/error_handler.dart';
import '../widgets/glass_card.dart';
import '../utils/app_theme.dart';
import 'searching_worker_screen.dart';
import 'booking_accepted_screen.dart';
import 'worker_assigned_screen.dart';
import 'track_status_screen.dart';
import '../models/labourer.dart';
import '../widgets/pattern_painter.dart';
import 'settings_screen.dart';
import 'refer_earn_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;
  AppStateProvider? _appState;
  bool _showAllCategories = false;

  final TextEditingController _searchController = TextEditingController();
  int _currentActiveBookingPage = 0;
  String? _lastCategoriesError;
  int? _selectedCategoryIndex;

  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  final List<Map<String, String>> _bannerData = [
    {
      'title': 'Need strong\nhands?',
      'subtitle': 'Skilled masonry & labour',
      'image': 'assets/images/banner_masonry.png',
    },
    {
      'title': 'Electrical\nissues?',
      'subtitle': 'Expert wiring & repair',
      'image': 'assets/images/banner_electrician.png',
    },
    {
      'title': 'We are here\nfor you',
      'subtitle': 'All your home needs sorted',
      'image': 'assets/images/banner_general.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState = Provider.of<AppStateProvider>(context, listen: false);
      _appState?.loadCategories();
      _appState?.fetchBookings(); // Load bookings for active card
      _initLocation();
      _appState?.addListener(_errorListener);
    });

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= _bannerData.length) nextPage = 0;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _errorListener() {
    if (!mounted || _appState == null) return;
    final currentError = _appState!.categoriesError;
    if (currentError != null && currentError != _lastCategoriesError) {
      _lastCategoriesError = currentError;
      if (_appState!.selectedTab == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentError),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    } else if (currentError == null) {
      _lastCategoriesError = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _appState?.removeListener(_errorListener);
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentAddress == null) {
      await _getCurrentLocation();
    }
  }
  //ejjfjs fweihdwsefike

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final address = '${place.locality}, ${place.country}';
        if (mounted) {
          Provider.of<LocationProvider>(
            context,
            listen: false,
          ).updateCurrentAddress(
            address: address,
            latitude: position.latitude,
            longitude: position.longitude,
            label: 'Current Location',
          );
        }
      }
    } catch (e) {
      debugPrint(
        ErrorHandler.getErrorMessage(e, action: 'Location fetch failed'),
      );
    }
  }

  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddressSelectionSheet(),
    );
  }

  Widget _buildComingSoonState(String cityName) {
    final String resolvedCity =
        (cityName.isNotEmpty && cityName != 'Enable location')
            ? cityName
            : 'your area';
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 40,
          bottom: 40,
          width: 32,
          child: CustomPaint(
            painter: DotPatternPainter(
              color: const Color(0xFF6B7280).withOpacity(0.08),
              spacing: 10.0,
              radius: 1.2,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 40,
          bottom: 40,
          width: 32,
          child: CustomPaint(
            painter: DotPatternPainter(
              color: const Color(0xFF6B7280).withOpacity(0.08),
              spacing: 10.0,
              radius: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "WE ARE",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 1.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "COMING ",
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: "SOON",
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.brandGreenMain,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "We're currently live in select areas and expanding quickly. Get notified when we are near you!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _showAddressSelectionBottomSheet,
                child: CustomPaint(
                  painter: DashedUnderlinePainter(
                    color: AppTheme.brandGreenMain,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      "Change location",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandGreenMain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel(bool isCityActive) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: SizedBox(
          height: MediaQuery.of(context).size.width * 0.85,
          child: Stack(
            children: [
              PageView.builder(
                controller: _bannerPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
                itemCount: _bannerData.length,
                itemBuilder: (context, index) {
                  final data = _bannerData[index];
                  return Stack(
                    children: [
                      Image.asset(
                        data['image']!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                      ),
                      // Text Overlay
                      Positioned(
                        left: 24,
                        top: 130,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Text(
                                data['title']!,
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF4A3B2C),
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['subtitle']!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B5A49),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'BOOK NOW',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF4A3B2C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Carousel Dots
              Positioned(
                bottom: 24,
                left: 24,
                child: Row(
                  children: List.generate(_bannerData.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 4),
                      height: 6,
                      width: _currentBannerIndex == index ? 16 : 6,
                      decoration: BoxDecoration(
                        color:
                            _currentBannerIndex == index
                                ? const Color(0xFF4A3B2C)
                                : const Color(0xFF4A3B2C).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2ECE6), // Match mockup background
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _isRefreshing = true);
            final appState = Provider.of<AppStateProvider>(
              context,
              listen: false,
            );
            await appState.fetchCategories();
            if (mounted) setState(() => _isRefreshing = false);
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Consumer<AppStateProvider>(
              builder: (context, appState, _) {
                final activeBookings =
                    appState.bookings.where((b) {
                      final status = b['status'].toString().toLowerCase();
                      if (status == 'completed' || status == 'cancelled')
                        return false;
                      final date =
                          DateTime.parse(b['date'].toString()).toLocal();
                      final hours =
                          int.tryParse(b['numberOfHours']?.toString() ?? '2') ??
                          2;
                      final endTime = date.add(Duration(hours: hours));
                      if (DateTime.now().isAfter(endTime)) return false;
                      return status == 'confirmed' ||
                          status == 'pending' ||
                          status == 'arrived';
                    }).toList();

                final hasActive = activeBookings.isNotEmpty;
                final hasCategories = appState.categories.isNotEmpty;

                final locationProvider = Provider.of<LocationProvider>(context);
                final isCityActive = appState.isCityEnabledByCoordinates(
                  locationProvider.currentLatitude,
                  locationProvider.currentLongitude,
                  fallbackAddress: locationProvider.currentAddress,
                );
                final rawAddress = locationProvider.currentAddress ?? '';
                final cityName =
                    rawAddress.contains(',')
                        ? rawAddress.split(',').first.trim()
                        : rawAddress;

                return Stack(
                  children: [
                    // Top Poster Image Carousel
                    _buildBannerCarousel(isCityActive),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationHeader(isCityActive: isCityActive),
                        const SizedBox(
                          height: 190,
                        ), // Transparent space for the poster to show
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              if (!isCityActive) ...[
                                _buildComingSoonState(cityName),
                                const SizedBox(height: 24),
                                _buildReliableTrustworthySection(),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    'Refer & Earn',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      height: 1.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildReferEarnSection(),
                                const SizedBox(height: 12),
                                _buildBrandingFooter(),
                              ] else ...[
                                if (hasActive && isCityActive) ...[
                                  _buildActiveBookingList(activeBookings),
                                  const SizedBox(height: 32),
                                ],
                                if (hasCategories) ...[
                                  _buildCategoriesSection(activeBookings),
                                  const SizedBox(height: 32),
                                  _buildBookingOptionTiles(),
                                ],
                                const SizedBox(height: 32),
                                _buildReliableTrustworthySection(),
                                const SizedBox(height: 24),
                                _buildBrandingFooter(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Clean Home. Zero Stress.",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "will",
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF10B981),
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Trusted by 600k+ families",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTrustBadge(Icons.verified_user_rounded, "Verified"),
              const SizedBox(width: 16),
              _buildTrustBadge(Icons.model_training_rounded, "Trained"),
              const SizedBox(width: 16),
              _buildTrustBadge(Icons.thumb_up_rounded, "Reliable"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader({required bool isCityActive}) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final String rawAddress =
        locationProvider.currentAddress ?? 'Enable location';
    final String rawLabel = locationProvider.currentLabel ?? '';
    final String rawHouseNumber = locationProvider.currentHouseNumber ?? '';

    String displayLabel = 'Location';
    String displayAddress = rawAddress;

    if (rawHouseNumber.isNotEmpty) {
      displayLabel = rawHouseNumber;
    } else if (rawLabel.isNotEmpty &&
        ![
          'Saved Location',
          'Selected Location',
          'Current Location',
        ].contains(rawLabel)) {
      displayLabel = rawLabel;
    } else if (rawLabel == 'Saved Location') {
      displayLabel = 'Saved Location';
    } else if (rawLabel == 'Current Location') {
      displayLabel = 'Current Location';
    }

    if (rawHouseNumber.isNotEmpty &&
        displayAddress.startsWith(rawHouseNumber)) {
      displayAddress = displayAddress
          .substring(rawHouseNumber.length)
          .replaceAll(RegExp(r'^[\s,]+'), '');
    }

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 8,
        20,
        12,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Address Section
              Expanded(
                child: GestureDetector(
                  onTap: _showAddressSelectionBottomSheet,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF1E293B),
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayAddress,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Right Icons
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReferEarnScreen(),
                    ),
                  );
                },
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/images/gift_icon.png',
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            '₹100',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/default_avatar.png',
                      ), // Fallback
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingList(List<dynamic> activeBookings) {
    if (activeBookings.isEmpty) return const SizedBox.shrink();

    return Builder(
      builder: (context) {
        if (activeBookings.length == 1) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildBookingCard(activeBookings.first),
              ),
              const SizedBox(height: 20),
              _buildBookingDots(1, 0),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 80,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: activeBookings.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentActiveBookingPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildBookingCard(activeBookings[index]);
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildBookingDots(activeBookings.length, _currentActiveBookingPage),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final dynamic categoryData = booking['category'];
    final String serviceName =
        categoryData is Map
            ? (categoryData['name'] ?? 'Service')
            : (categoryData?.toString() ?? 'Service');

    String dateStr = 'Upcoming';
    if (booking['date'] != null) {
      try {
        final DateTime dt =
            DateTime.parse(booking['date'].toString()).toLocal();
        dateStr =
            "${dt.day} ${_getMonthName(dt.month)} at ${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
      } catch (_) {
        dateStr = booking['date'].toString();
      }
    }

    final cardContent = Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A9782).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Booking',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$serviceName $dateStr',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.play_arrow_rounded,
            size: 18,
            color: const Color(0xFF4A9782).withOpacity(0.8),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        final DateTime scheduledTime =
            DateTime.parse(booking['date'].toString()).toLocal();
        final now = DateTime.now();
        final difference = scheduledTime.difference(now);

        // Find the ServiceCategory object for the search screen
        final allCategories =
            Provider.of<AppStateProvider>(context, listen: false).categories;
        final categoryName =
            booking['category'] is Map
                ? (booking['category']['name'] ?? 'Service')
                : (booking['category']?.toString() ?? 'Service');

        final categoryObj = allCategories.firstWhere(
          (c) => c.name == categoryName,
          orElse:
              () => ServiceCategory(
                name: categoryName,
                icon: Icons.category,
                description: '',
                supportedModes: ['Hourly'],
                hourlyRate: 0,
                dailyRate: 0,
                minHourlyRate: 0,
                maxHourlyRate: 0,
                commissionPercentage: 0,
              ),
        );

        // 1. If worker is already assigned, go to TrackStatusScreen
        final workerData = booking['labourer'];
        if (workerData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TrackStatusScreen(bookingId: booking['_id']),
            ),
          );
          return;
        }

        // 2. If no worker assigned yet, follow timing logic
        if (difference.inHours < 12) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SearchingWorkerScreen(
                    category: categoryObj,
                    address: booking['address'] ?? '',
                    scheduledTime: scheduledTime,
                    latitude: (booking['latitude'] as num?)?.toDouble() ?? 0.0,
                    longitude:
                        (booking['longitude'] as num?)?.toDouble() ?? 0.0,
                    bookingData: booking,
                  ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BookingAcceptedScreen(
                    category: categoryObj,
                    address: booking['address'] ?? '',
                    scheduledTime: scheduledTime,
                    bookingData: booking,
                  ),
            ),
          );
        }
      },
      child: cardContent,
    );
  }

  Widget _buildBookingDots(int count, int currentIndex) {
    final displayCount = count.clamp(0, 3);
    if (displayCount == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(displayCount, (index) {
        bool isActive = index == currentIndex;
        // If more than 3 bookings, cap the active dot visual to the last dot
        if (count > 3 && index == 2 && currentIndex >= 2) {
          isActive = true;
        }
        return Padding(
          padding: EdgeInsets.only(right: index == displayCount - 1 ? 0 : 21),
          child: _buildDot(isActive),
        );
      }),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  Widget _buildDot(bool active) {
    return Container(
      width: 9,
      height: 9,
      decoration: ShapeDecoration(
        color: active ? AppTheme.primaryStatusGreen : AppTheme.grayPagination,
        shape: const OvalBorder(),
      ),
    );
  }

  Widget _buildCategoriesSection(List<dynamic> activeBookings) {
    final appState = Provider.of<AppStateProvider>(context);
    final allCategories = appState.categories;
    if (allCategories.isEmpty) return const SizedBox.shrink();

    final hasMoreThan4 = allCategories.length > 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All house help services',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              if (hasMoreThan4)
                GestureDetector(
                  onTap:
                      () => setState(
                        () => _showAllCategories = !_showAllCategories,
                      ),
                  child: Text(
                    _showAllCategories ? 'See Less' : 'See All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final categoriesToShow =
                _showAllCategories
                    ? allCategories
                    : allCategories.take(6).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75, // Taller cards
                ),
                itemCount: categoriesToShow.length,
                itemBuilder: (context, index) {
                  return _buildMockupCategoryCard(categoriesToShow[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMockupCategoryCard(ServiceCategory category) {
    // Map category name to generated image or fallback icon
    String catName = category.name.toLowerCase();
    String? imageAsset;
    IconData? fallbackIcon;
    Color? fallbackColor;

    if (catName.contains('clean')) {
      imageAsset = 'assets/images/cat_cleanup.png';
    } else if (catName.contains('plumb')) {
      imageAsset = 'assets/images/cat_plumbing.png';
    } else if (catName.contains('electric') || catName.contains('wir')) {
      imageAsset = 'assets/images/cat_electrician.png';
    } else if (catName.contains('garden')) {
      imageAsset = 'assets/images/cat_garden.png';
    } else if (catName.contains('mason')) {
      imageAsset = 'assets/images/cat_masonry.png';
    } else if (catName.contains('mov') || catName.contains('pack')) {
      imageAsset = 'assets/images/cat_moving.png';
    } else if (catName.contains('paint')) {
      imageAsset = 'assets/images/cat_painting.png';
    } else {
      imageAsset = 'assets/images/cat_general.png';
    }

    return GestureDetector(
      onTap: () => _navigateToRequest(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
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
            // Top Image Area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: imageAsset == null ? fallbackColor : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      image:
                          imageAsset != null
                              ? DecorationImage(
                                image: AssetImage(imageAsset),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        imageAsset == null
                            ? Center(
                              child: Icon(
                                fallbackIcon,
                                color: Colors.black54,
                                size: 40,
                              ),
                            )
                            : null,
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB300),
                            size: 10,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            category.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Info Area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (category.maxHourlyRate > category.hourlyRate)
                              Text(
                                '₹${category.maxHourlyRate.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  decoration: TextDecoration.lineThrough,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            Text(
                              '₹${category.hourlyRate.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF10B981),
                            size: 16,
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
      ),
    );
  }

  Widget _buildReliableTrustworthySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reliable & Trustworthy',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ensuring integrity through verified standards',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTrustItem(
                  'Verified\nProfessionals\nYou Can Trust',
                  'assets/images/trust_worker_1.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrustItem(
                  'Well Trained to\ndeliver great\nservice',
                  'assets/images/trust_worker_2.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrustItem(
                  'Safe, reliable,\nand consistent\nevery single\ntime',
                  'assets/images/trust_worker_3.png',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(String text, String imagePath) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 0.8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildReferEarnSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReferEarnScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEBF6F3), // Extra soft minty light green
                Color(0xFFF4FAF8), // Near white mint
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4A9782).withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A9782).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Beautiful subtle background circles/shapes for premium abstract aesthetic
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9782).withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9782).withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Stylized Icon Container with a beautiful glow
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4A9782,
                            ).withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Color(0xFF4A9782),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Elegant Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4A9782,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LIMITED OFFER',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2E876E),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Refer & Earn ₹100',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You and your friend both get ₹100 on their first booking.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sleek chevron / arrow to invite action
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A9782),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4A9782,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceCategory category) {
    String catName = category.name.toLowerCase();
    String imageAsset = 'assets/images/cat_general.png';

    if (catName.contains('clean')) {
      imageAsset = 'assets/images/cat_cleanup.png';
    } else if (catName.contains('elect') || catName.contains('wir')) {
      imageAsset = 'assets/images/cat_electrician.png';
    } else if (catName.contains('garden')) {
      imageAsset = 'assets/images/cat_garden.png';
    } else if (catName.contains('mason')) {
      imageAsset = 'assets/images/cat_masonry.png';
    } else if (catName.contains('mov')) {
      imageAsset = 'assets/images/cat_moving.png';
    } else if (catName.contains('paint')) {
      imageAsset = 'assets/images/cat_painting.png';
    } else if (catName.contains('plumb')) {
      imageAsset = 'assets/images/cat_plumbing.png';
    }

    return GestureDetector(
      onTap: () => _navigateToRequest(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image Area
              Container(
                height: 100,
                width: double.infinity,
                color: Colors.white,
                child: Stack(
                  children: [
                    Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB300),
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '4.9',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Info Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (category.maxHourlyRate > category.hourlyRate)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '₹${category.maxHourlyRate.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          Text(
                            '₹${category.hourlyRate.toInt()}/hr',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
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
        ),
      ),
    );
  }

  Widget _buildAllServicesGrid() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final categories = appState.categories;

        if (_isRefreshing) {
          return _buildSkeletonGrid();
        }

        if (appState.isCategoriesLoading && categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppTheme.saffron),
            ),
          );
        }

        if (categories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: AppTheme.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appState.searchQuery.isEmpty
                        ? 'No services available'
                        : 'No services found for "${appState.searchQuery}"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (appState.searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Try searching for something else',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 40),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 160,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildServiceCard(categories[index]);
            },
          ),
        );
      },
    );
  }

  void _navigateToRequest(ServiceCategory category) {
    _showBookingModeSelectionSheet(category);
  }

  Widget _buildBookingOptionTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book for Later',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your slot & stay worry-free',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBookForLaterCard(
                  title: 'Schedule\nBooking',
                  discount: 'UP TO 50% OFF',
                  imageAsset: 'assets/images/book_later_clock.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBookForLaterCard(
                  title: 'Recurring\nBooking',
                  discount: 'UP TO 25% OFF',
                  imageAsset: 'assets/images/book_later_calendar.png',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookForLaterCard({
    required String title,
    required String discount,
    required String imageAsset,
  }) {
    return GestureDetector(
      onTap: () => _showCategorySelectionSheet(false),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4), // Light mint green background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE), // Light blue pill
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        discount,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7), // Blue text
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Positioned 3D Image on bottom right
              Positioned(
                bottom: -5,
                right: -5,
                child: Image.asset(
                  imageAsset,
                  width: 75,
                  height: 75,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategorySelectionSheet(bool isInstant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final categories =
            Provider.of<AppStateProvider>(context, listen: false).categories;
        if (categories.isEmpty) return const SizedBox.shrink();

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            _selectedCategoryIndex ??= 0;
            if (_selectedCategoryIndex! >= categories.length) {
              _selectedCategoryIndex = 0;
            }
            final selectedCategory = categories[_selectedCategoryIndex!];

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 12,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isInstant ? 'Instant Help (ASAP)' : 'Schedule Help',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isInstant
                        ? 'Select a service and view description'
                        : 'Select a service to schedule for later',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Horizontal scroll view for categories
                  SizedBox(
                    height: 68,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = index == _selectedCategoryIndex;

                        IconData icon;
                        String name = category.name.toLowerCase();
                        if (name.contains('mason'))
                          icon = Icons.construction_rounded;
                        else if (name.contains('clean'))
                          icon = Icons.cleaning_services_rounded;
                        else if (name.contains('plumb'))
                          icon = Icons.plumbing_rounded;
                        else if (name.contains('elect'))
                          icon = Icons.electric_bolt_rounded;
                        else if (name.contains('paint'))
                          icon = Icons.format_paint_rounded;
                        else if (name.contains('carpent'))
                          icon = Icons.carpenter_rounded;
                        else if (name.contains('garden'))
                          icon = Icons.yard_rounded;
                        else if (name.contains('ac') || name.contains('repair'))
                          icon = Icons.handyman_rounded;
                        else
                          icon = Icons.miscellaneous_services_rounded;

                        return GestureDetector(
                          onTap: () {
                            setStateSheet(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xFFE8F3F1)
                                          : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF4A9782)
                                            : const Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      color:
                                          isSelected
                                              ? const Color(0xFF4A9782)
                                              : const Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                        color:
                                            isSelected
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFF475569),
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
                  ),
                  const SizedBox(height: 12),

                  // Description area box
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedCategory.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '₹${selectedCategory.hourlyRate.toInt()}/hr',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4A9782),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          selectedCategory.description.isNotEmpty
                              ? selectedCategory.description
                              : 'No description available for this service.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ServiceDetailScreen(
                                  category: selectedCategory,
                                  isInstant: isInstant,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9782),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isInstant ? 'Book Instant' : 'Proceed to Schedule',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingModeSelectionSheet(ServiceCategory category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            top: 12,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Booking Option',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select how you would like to book ${category.name}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ServiceDetailScreen(
                                  category: category,
                                  isInstant: true,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3F1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.brandGreenMain.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/book_later_clock.png',
                              width: 64,
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Instant',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Arriving ASAP',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ServiceDetailScreen(
                                  category: category,
                                  isInstant: false,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3F1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/book_later_calendar.png',
                              width: 64,
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Schedule',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Book for later',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 40),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 160,
        ),
        itemCount: 9, // Fill the view
        itemBuilder: (context, index) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Top Image Area Placeholder
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            // Bottom Info Placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedUnderlinePainter extends CustomPainter {
  final Color color;
  DashedUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    double max = size.width;
    double dashWidth = 3;
    double dashSpace = 2;
    double startX = 0;

    while (startX < max) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX + dashWidth, size.height),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
