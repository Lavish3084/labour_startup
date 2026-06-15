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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
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

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationHeader(isCityActive: isCityActive),
                    if (hasActive && isCityActive) ...[
                      const SizedBox(height: 32),
                      _buildActiveBookingList(activeBookings),
                    ],
                    if (!isCityActive) ...[
                      _buildComingSoonState(cityName),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Top Reasons to Choose',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTrustBanner(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      if (hasCategories) ...[
                        const SizedBox(height: 32),
                        _buildBookingOptionTiles(),
                        const SizedBox(height: 32),
                        _buildCategoriesSection(activeBookings),
                      ],
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Top Reasons to Choose',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTrustBanner(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    ],
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
      color: AppTheme.scaffoldBg, // Same as rest of the screen (light theme)
      padding: const EdgeInsets.fromLTRB(
        24,
        12,
        24,
        120,
      ), // 120 bottom padding to clear navigation bar
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align all items to the left!
        children: [
          Text(
            "India's premium local workforce app ❤️",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B), // Premium dark slate color
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "will",
            style: GoogleFonts.inter(
              fontSize: 84, // Stretched extremely large ("extend a lot")
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.045), // Subtle gray watermark
              letterSpacing: -2.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Will – Your Ultimate Marketplace for Skilled Labor!",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155), // Premium slate-700
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            """Built for every job, big or small — Will connects trusted skilled workers with people who need reliable help, anytime and anywhere.""",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B), // Soft slate-500
              height: 1.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
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

    // Determine custom name/description to display at the top line
    if (rawHouseNumber.isNotEmpty) {
      displayLabel = rawHouseNumber;
    } else if (rawLabel.isNotEmpty &&
        rawLabel != 'Saved Location' &&
        rawLabel != 'Selected Location' &&
        rawLabel != 'Current Location') {
      displayLabel = rawLabel;
    } else if (rawLabel == 'Saved Location') {
      displayLabel = 'Saved Location';
    } else if (rawLabel == 'Current Location') {
      displayLabel = 'Current Location';
    } else {
      displayLabel = 'Location';
    }

    // Clean up address to avoid duplicating the house number description
    if (rawHouseNumber.isNotEmpty &&
        displayAddress.startsWith(rawHouseNumber)) {
      displayAddress = displayAddress
          .substring(rawHouseNumber.length)
          .replaceAll(RegExp(r'^[\s,]+'), '');
    }

    if (!isCityActive) {
      // White location header
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 8,
          20,
          12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showAddressSelectionBottomSheet,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.brandGreenMain, // Brand Green
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayLabel,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B), // Slate-800
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF1E293B),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.52,
                        child: Text(
                          displayAddress,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B), // Slate-500
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletScreen(),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF1E293B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.settings_outlined,
                color: const Color(0xFF1E293B),
                size: 24,
              ),
            ),
          ],
        ),
      );
    }

    // Default green header (unchanged, with search bar)
    return Container(
      width: double.infinity,
      height: 265,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradientGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.zero, // Padding handled inside Stack
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(
                color: Colors.white.withOpacity(0.08),
                spacing: 18.0,
                radius: 2.0,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 8,
              20,
              24,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showAddressSelectionBottomSheet,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.brandYellow,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.52,
                                child: Text(
                                  displayAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletScreen(),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 74),
                Container(
                  height: 56, // Matching Figma
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged:
                              (value) => Provider.of<AppStateProvider>(
                                context,
                                listen: false,
                              ).setSearchQuery(value),
                          decoration: InputDecoration(
                            hintText: 'Explore Services',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF49454F),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Icon(Icons.search, color: Color(0xFF49454F)),
                    ],
                  ),
                ),
              ],
            ),
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
                'Categories',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  letterSpacing: 0.5,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.activeCardBorder,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Builder(
          builder: (context) {
            final categoriesToShow =
                _showAllCategories
                    ? allCategories
                    : allCategories.take(4).toList();

            if (_showAllCategories) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  runSpacing: 20,
                  spacing: 0,
                  children:
                      categoriesToShow.map((cat) {
                        return SizedBox(
                          width: (MediaQuery.of(context).size.width - 20) / 4,
                          child: _buildCategoryItem(cat),
                        );
                      }).toList(),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    categoriesToShow
                        .map((cat) => _buildCategoryItem(cat))
                        .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryItem(ServiceCategory category) {
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
      onTap: () => _navigateToRequest(category),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const ShapeDecoration(
              color: AppTheme.graySurface,
              shape: OvalBorder(),
            ),
            child: Icon(icon, color: AppTheme.figmaHeaderEnd, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            category.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              letterSpacing: 0.4,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 135,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Transform.scale(
            scale: 1.05, // Slight zoom to crop out edge artifacts
            child: Image.asset(
              'assets/images/branding_banner.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
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
    // Mapping generated icons from services.png
    Offset iconOffset = const Offset(0, 0);
    String catName = category.name.toLowerCase();

    if (catName.contains('clean')) {
      iconOffset = const Offset(0, 0);
    } else if (catName.contains('repair')) {
      iconOffset = const Offset(1, 0);
    } else if (catName.contains('paint')) {
      iconOffset = const Offset(2, 0);
    } else if (catName.contains('plumb')) {
      iconOffset = const Offset(0, 1);
    } else if (catName.contains('mov')) {
      iconOffset = const Offset(1, 1);
    } else if (catName.contains('elect') || catName.contains('wir')) {
      iconOffset = const Offset(2, 1);
    } else {
      iconOffset = const Offset(0, 0);
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
                color: AppTheme.paleSaffron.withValues(alpha: 0.6),
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: ClipRRect(
                          child: FractionallySizedBox(
                            widthFactor: 3.0,
                            heightFactor: 2.0,
                            alignment: Alignment(
                              -1.0 + (iconOffset.dx * 1.0),
                              -1.0 + (iconOffset.dy * 2.0),
                            ),
                            child: Image.asset(
                              'assets/icons/services.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
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
      padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Card: Schedule
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () => _showCategorySelectionSheet(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.04),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F3F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.brandGreenMain,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Schedule',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick your time',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right Card: Instant
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () => _showCategorySelectionSheet(true),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Layer 1: Solid Card Shell background (fills the entire stack area dynamically)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.04),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Layer 2: Worker Image Cutout (positioned entirely inside the card on the right, clipped to card rounded corners)
                  Positioned(
                    bottom: 1.5,
                    right: 1.5,
                    top: 1.5,
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(22.5),
                          bottomRight: Radius.circular(22.5),
                        ),
                        child: SizedBox(
                          width: 100, // Constrain image width so it occupies only the right portion of the card
                          child: Image.asset(
                            'assets/images/worker_namaste.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Layer 3: Card Content (Non-positioned child, determines Stack size. Solid transparent layout)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flash_on_rounded,
                            color: AppTheme.brandGreenMain,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(right: 28),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Instant',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade400,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 28),
                          child: Text(
                            'Get help now',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
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
      ),
    );
  }

  void _showCategorySelectionSheet(bool isInstant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final categories = Provider.of<AppStateProvider>(context, listen: false).categories;
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFFE8F3F1) 
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected 
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
                                      color: isSelected 
                                          ? const Color(0xFF4A9782) 
                                          : const Color(0xFF64748B), 
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
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
                            builder: (context) => ServiceDetailScreen(
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
                            builder: (context) => ServiceDetailScreen(
                              category: category,
                              isInstant: true,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flash_on_rounded,
                                color: AppTheme.brandGreenMain,
                                size: 24,
                              ),
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
                            builder: (context) => ServiceDetailScreen(
                              category: category,
                              isInstant: false,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: AppTheme.brandGreenMain,
                                size: 24,
                              ),
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
