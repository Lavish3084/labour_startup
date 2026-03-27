import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../utils/app_theme.dart';
import 'main_screen.dart';
import 'signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      print('Initiating Google Sign In...');
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        setState(() => _isLoading = false);
        return; // User canceled
      }

      print('Google Sign In successful for: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      print('ID Token generated: ${idToken != null ? "YES" : "NO (null)"}');

      if (idToken != null) {
        print('Sending Token to backend to action=login...');
        final result = await ApiService.googleLogin(idToken, 'user', action: 'login');
        print('Backend Response: $result');
        
        if (result['success']) {
          if (context.mounted) {
            await Geolocator.requestPermission();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            }
          }
        } else {
          if (context.mounted) {
            if (result['code'] == 'USER_NOT_FOUND') {
              // Auto-signup as user if account doesn't exist
              _completeGoogleSignup(idToken, 'user');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? 'Google Login failed')),
              );
            }
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to retrieve Google Identity Token.')),
          );
        }
      }
    } catch (e) {
      print('Google Auth Exception Caught: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e, action: 'Google Login failed: $e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeGoogleSignup(String idToken, String role) async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.googleLogin(idToken, role, action: 'signup');
      if (result['success']) {
        if (mounted) {
          await Geolocator.requestPermission();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        }
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Signup failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  gradient: AppTheme.profileGradient,
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 28),

              Text('Welcome back', style: AppTheme.heading1),
              const SizedBox(height: 6),
              Text(
                'Sign in to your account to continue',
                style: AppTheme.body.copyWith(color: AppTheme.textLight),
              ),

              const SizedBox(height: 36),

              // Email
              Text('Email', style: AppTheme.subtitle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                decoration: AppTheme.inputDecoration(
                  label: '',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                ),
              ),

              const SizedBox(height: 18),

              // Password
              Text('Password', style: AppTheme.subtitle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                decoration: AppTheme.inputDecoration(
                  label: '',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: AppTheme.primaryButton,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Sign in', style: AppTheme.button),
                ),
              ),

              const SizedBox(height: 24),
              
              // Google Login
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
                  ),
                  Expanded(child: Divider(color: AppTheme.border)),
                ],
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                    height: 24,
                  ),
                  label: Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: Colors.black12,
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Sign Up link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign up',
                        style: AppTheme.subtitle.copyWith(
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(email, password);

      if (result['success']) {
        if (context.mounted) {
          await Geolocator.requestPermission();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ErrorHandler.getErrorMessage(e, action: 'Login failed')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
