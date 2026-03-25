import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../utils/app_theme.dart';
import 'main_screen.dart';
import 'worker_details_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'user';
  File? _imageFile;
  final _picker = ImagePicker();

  bool _isPickingImage = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? profilePicture;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        profilePicture = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final result = await ApiService.signup(
        name, email, password, _selectedRole, profilePicture,
      );

      if (result['success']) {
        if (context.mounted) {
          await Geolocator.requestPermission();
          if (context.mounted) {
            if (_selectedRole == 'worker') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WorkerDetailsScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            }
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Create account', style: AppTheme.heading1),
            const SizedBox(height: 6),
            Text(
              'Set up your profile to get started',
              style: AppTheme.body.copyWith(color: AppTheme.textLight),
            ),

            const SizedBox(height: 28),

            // Profile Picture
            Center(
              child: GestureDetector(
                onTap: _isPickingImage || _isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryLight,
                        border: Border.all(color: AppTheme.divider, width: 1),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
                          ? const Icon(Icons.person_rounded, size: 36, color: AppTheme.textMuted)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Role Selection
            Text('I want to', style: AppTheme.subtitle),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRoleOption('user', 'Hire workers', Icons.search_rounded),
                const SizedBox(width: 12),
                _buildRoleOption('worker', 'Find work', Icons.construction_rounded),
              ],
            ),

            const SizedBox(height: 20),

            // Form fields
            _buildField('Full name', _nameController, Icons.person_outline_rounded, 'John Doe'),
            const SizedBox(height: 14),
            _buildField('Email', _emailController, Icons.mail_outline_rounded, 'you@example.com',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _buildPasswordField('Password', _passwordController, _obscurePassword,
                () => setState(() => _obscurePassword = !_obscurePassword)),
            const SizedBox(height: 14),
            _buildPasswordField('Confirm password', _confirmPasswordController, _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm)),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: AppTheme.primaryButton,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Create account', style: AppTheme.button),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, String hint,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.subtitle),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          keyboardType: keyboardType,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: AppTheme.inputDecoration(label: '', hint: hint, prefixIcon: icon),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      String label, TextEditingController controller, bool obscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.subtitle),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          enabled: !_isLoading,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: AppTheme.inputDecoration(
            label: '',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            suffix: GestureDetector(
              onTap: toggle,
              child: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppTheme.primary : AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
