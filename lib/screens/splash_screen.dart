import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'worker_home_screen.dart';
import 'worker_details_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    final token = await ApiService.getToken();
    final role = await ApiService.getRole();

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        ApiService.updateFcmToken();

        if (mounted) {
          await Provider.of<AppStateProvider>(context, listen: false).fetchProfile();
        }

        if (role == 'worker') {
          // Check if profile is complete
          if (mounted) {
            final appState = Provider.of<AppStateProvider>(context, listen: false);
            final labourer = appState.profileData?['labourer'];
            
            if (labourer != null && labourer['location'] == 'Not set') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WorkerDetailsScreen()),
              );
              return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerHomeScreen()),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.primary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean logo mark
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  size: 36,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Will',
                style: AppTheme.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Professional Labour Services',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.5),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
