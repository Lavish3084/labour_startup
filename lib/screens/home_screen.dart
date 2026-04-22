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
    if (_appState!.categoriesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_appState!.categoriesError!),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
  //ejfs

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
          );
        }
      }
    } catch (e) {
      debugPrint(ErrorHandler.getErrorMessage(e, action: 'Location fetch failed'));
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
            final appState = Provider.of<AppStateProvider>(context, listen: false);
            await appState.fetchCategories();
            if (mounted) setState(() => _isRefreshing = false);
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreenHeader(),
                const SizedBox(height: 32),
                _buildActiveBookingSection(),
                const SizedBox(height: 32),
                _buildCategoriesSection(),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Top Reasons to Choose',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.5, // 24px line-height
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTrustBanner(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreenHeader() {
    final locationProvider = Provider.of<LocationProvider>(context);
    final String displayAddress = locationProvider.currentAddress ?? 'Enable location';

    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradientGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showAddressSelectionBottomSheet,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppTheme.brandYellow, size: 24),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        displayAddress,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 32),
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
                    onChanged: (value) => Provider.of<AppStateProvider>(context, listen: false).setSearchQuery(value),
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
    );
  }

  Widget _buildActiveBookingSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final activeBookings = appState.bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'pending' || b['status'] == 'arrived').toList();
        
        if (activeBookings.isEmpty) return const SizedBox.shrink();

        if (activeBookings.length == 1) {
          return Column(
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
          children: [
            SizedBox(
              height: 110,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: activeBookings.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentActiveBookingPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildBookingCard(activeBookings[index]),
                  );
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
    final String serviceName = categoryData is Map ? (categoryData['name'] ?? 'Service') : (categoryData?.toString() ?? 'Service');
    
    String dateStr = 'Upcoming';
    if (booking['date'] != null) {
      try {
        final DateTime dt = DateTime.parse(booking['date'].toString()).toLocal();
        dateStr = "${dt.day} ${_getMonthName(dt.month)} at ${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
      } catch (_) {
        dateStr = booking['date'].toString();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.activeCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.activeCardBorder, width: 1),
        boxShadow: AppTheme.figmaCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Scheduled Arrival :\n',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: '$serviceName - $dateStr',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.activeCardBorder),
        ],
      ),
    );
  }

  Widget _buildBookingDots(int count, int currentIndex) {
    if (count <= 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDot(true),
          const SizedBox(width: 21),
          _buildDot(false),
          const SizedBox(width: 21),
          _buildDot(false),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == count - 1 ? 0 : 21),
          child: _buildDot(index == currentIndex),
        );
      }),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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

  Widget _buildCategoriesSection() {
    return Column(
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
              GestureDetector(
                onTap: () => setState(() => _showAllCategories = !_showAllCategories),
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
        Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            final activeBookings = appState.bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'pending' || b['status'] == 'arrived').toList();
            final hasActiveBookings = activeBookings.isNotEmpty;
            final allCategories = appState.categories;
            if (allCategories.isEmpty) return const SizedBox.shrink();

            final categoriesToShow = _showAllCategories 
                ? allCategories 
                : (hasActiveBookings ? allCategories.take(4).toList() : allCategories.take(8).toList());

            if (_showAllCategories || !hasActiveBookings) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categoriesToShow.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 0,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) => _buildCategoryItem(categoriesToShow[index]),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: categoriesToShow.map((cat) => _buildCategoryItem(cat)).toList(),
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
    if (name.contains('mason')) icon = Icons.construction_rounded;
    else if (name.contains('clean')) icon = Icons.cleaning_services_rounded;
    else if (name.contains('plumb')) icon = Icons.plumbing_rounded;
    else if (name.contains('elect')) icon = Icons.electric_bolt_rounded;
    else if (name.contains('paint')) icon = Icons.format_paint_rounded;
    else if (name.contains('carpent')) icon = Icons.carpenter_rounded;
    else if (name.contains('garden')) icon = Icons.yard_rounded;
    else if (name.contains('ac') || name.contains('repair')) icon = Icons.handyman_rounded;
    else icon = Icons.miscellaneous_services_rounded;

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
                    child: Icon(Icons.broken_image_rounded, color: AppTheme.primaryGreen),
                  ),
                );
              },
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '4.9',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(category: category),
      ),
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
