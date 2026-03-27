import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/service_category.dart';
import 'service_request_screen.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.loadCategories();
      _initLocation();
    });
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          await appState.fetchCategories();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHero(),
              _buildSearchSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Text(
                  'Services we offer',
                  style: GoogleFonts.baloo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              _buildAllServicesGrid(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHero() {
    final locationProvider = Provider.of<LocationProvider>(context);
    final String displayAddress = locationProvider.currentAddress ?? 'Choose your location...';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.saffron,
            AppTheme.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _showAddressSelectionBottomSheet,
              child: Row(
                children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayAddress.split(',')[0],
                            style: GoogleFonts.baloo2(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                      Text(
                        displayAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCircularAction(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 12),
                _buildCircularAction(Icons.person_outline_rounded),
              ],
            ),
          ),
        ),
          const SizedBox(height: 32),
          // "Hire a Service Man" Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIRE A\nSERVICE MAN',
                        style: GoogleFonts.baloo2(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'BOOK NOW >',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 0,
                        child: Image.asset(
                          'assets/icons/services.png', // Fallback to icon sheet if no specific asset
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
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

  Widget _buildCircularAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildSearchSection() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          radius: 16,
          blur: 15,
          opacity: 0.7,
          borderColor: Colors.white.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const Icon(Icons.search, color: AppTheme.saffron, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search "Electrician"',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, indent: 18, endIndent: 18, color: Color(0xFFEEEEEE)),
                const SizedBox(width: 12),
                const Icon(Icons.mic_none_rounded, color: AppTheme.saffron, size: 24),
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
                          Text(
                            '₹${category.minHourlyRate.toInt() > 0 ? category.minHourlyRate.toInt() : 49}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₹${(category.maxHourlyRate.toInt() > 0 ? category.maxHourlyRate.toInt() : 150)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
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
        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
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
        builder: (context) => ServiceRequestScreen(category: category),
      ),
    );
  }
}
