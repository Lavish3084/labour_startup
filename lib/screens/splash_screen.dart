import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/splash_location_sequence.dart';
import '../widgets/location_map_circle.dart';
import '../widgets/location_address_labels.dart';
import '../providers/location_provider.dart';
import '../services/error_handler.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

enum _SplashPhase { brand, location, revealing }

class _ResolvedLocation {
  final String locality;
  final String fullAddress;
  final double latitude;
  final double longitude;

  const _ResolvedLocation({
    required this.locality,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _brandFadeController;
  late Animation<double> _brandFadeAnimation;
  late AnimationController _screenSlideController;
  late Animation<Offset> _screenSlideAnimation;

  _SplashPhase _phase = _SplashPhase.brand;
  bool _isFetchingLocation = false;
  _ResolvedLocation? _resolvedLocation;

  @override
  void initState() {
    super.initState();
    _brandFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _brandFadeAnimation = CurvedAnimation(
      parent: _brandFadeController,
      curve: Curves.easeIn,
    );
    _screenSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _screenSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(
      CurvedAnimation(
        parent: _screenSlideController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _brandFadeController.forward();
    _runSplashFlow();
  }

  @override
  void dispose() {
    _brandFadeController.dispose();
    _screenSlideController.dispose();
    super.dispose();
  }

  Future<void> _runSplashFlow() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final token = await ApiService.getToken();
    final isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await _navigateToAuth();
      return;
    }

    setState(() {
      _phase = _SplashPhase.location;
      _isFetchingLocation = true;
    });

    await Future.wait([
      _fetchLocation(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);

    if (!mounted) return;

    setState(() => _isFetchingLocation = false);
  }

  void _onLocationSequenceComplete() async {
    if (!mounted) return;
    ApiService.updateFcmToken();
    setState(() => _phase = _SplashPhase.revealing);
    await _screenSlideController.forward();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _navigateToAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;

    if (onboardingSeen) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _fetchLocation() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      if (locationProvider.currentAddress != null &&
          locationProvider.currentLatitude != null &&
          locationProvider.currentLongitude != null) {
        if (mounted) {
          setState(() => _resolvedLocation = _fromProvider(locationProvider));
        }
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        _applyFallback();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _applyFallback();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted || placemarks.isEmpty) {
        _applyFallback();
        return;
      }

      final place = placemarks.first;
      final resolved = _fromPlacemark(
        place,
        position.latitude,
        position.longitude,
      );

      locationProvider.updateCurrentAddress(
        address: resolved.fullAddress,
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Current Location',
      );

      if (mounted) setState(() => _resolvedLocation = resolved);
    } catch (e) {
      debugPrint(
        ErrorHandler.getErrorMessage(e, action: 'Location fetch failed'),
      );
      _applyFallback();
    }
  }

  _ResolvedLocation _fromPlacemark(Placemark place, double lat, double lng) {
    final locality =
        (place.locality?.isNotEmpty == true)
            ? place.locality!
            : (place.subAdministrativeArea?.isNotEmpty == true)
            ? place.subAdministrativeArea!
            : 'Your area';

    final parts = <String>[
      if (place.locality?.isNotEmpty == true) place.locality!,
      if (place.administrativeArea?.isNotEmpty == true)
        place.administrativeArea!,
      if (place.postalCode?.isNotEmpty == true) place.postalCode!,
    ];

    return _ResolvedLocation(
      locality: locality,
      fullAddress: parts.isNotEmpty ? parts.join(', ') : locality,
      latitude: lat,
      longitude: lng,
    );
  }

  _ResolvedLocation _fromProvider(LocationProvider provider) {
    final address = provider.currentAddress ?? 'Your area';
    final parts = address.split(',').map((e) => e.trim()).toList();
    final locality = parts.isNotEmpty ? parts.first : 'Your area';

    return _ResolvedLocation(
      locality: locality,
      fullAddress: address,
      latitude: provider.currentLatitude ?? 28.6139,
      longitude: provider.currentLongitude ?? 77.209,
    );
  }

  void _applyFallback() {
    final provider = Provider.of<LocationProvider>(context, listen: false);
    if (provider.currentAddress != null) {
      if (mounted) setState(() => _resolvedLocation = _fromProvider(provider));
      return;
    }

    if (mounted) {
      setState(() {
        _resolvedLocation = const _ResolvedLocation(
          locality: 'Your area',
          fullAddress: 'Finding services near you',
          latitude: 28.6139,
          longitude: 77.209,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _SplashPhase.revealing) {
      return _buildRevealStack();
    }

    if (_phase == _SplashPhase.location) {
      return _buildLocationStack();
    }

    return _buildBrandView();
  }

  Widget _buildRevealStack() {
    final loc = _resolvedLocation!;
    return Stack(
      fit: StackFit.expand,
      children: [
        const MainScreen(),
        SlideTransition(
          position: _screenSlideAnimation,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -52),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LocationMapCircle(
                        latitude: loc.latitude,
                        longitude: loc.longitude,
                      ),
                      const SizedBox(height: 8),
                      LocationAddressLabels(
                        locality: loc.locality,
                        fullAddress: loc.fullAddress,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStack() {
    final loc = _resolvedLocation;

    return Stack(
      fit: StackFit.expand,
      children: [
        const MainScreen(),
        Material(
          color: Colors.white,
          child: SafeArea(
            child: SplashLocationSequence(
              isFetching: _isFetchingLocation,
              locality: loc?.locality,
              fullAddress: loc?.fullAddress,
              latitude: loc?.latitude,
              longitude: loc?.longitude,
              onSequenceComplete: _onLocationSequenceComplete,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandView() {
    return Scaffold(
      backgroundColor: AppTheme.brandGreenMain,
      body: FadeTransition(
        opacity: _brandFadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Will',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Get professional house help in minutes!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
