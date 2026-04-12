import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/location_provider.dart';

import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'saved_addresses_screen.dart';
import 'splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPickingImage = false;
  AppStateProvider? _appState;

  @override
  void initState() {
    super.initState();
    // Fetch profile data when screen initializes to ensure fresh data
    Future.microtask(() {
      if (!mounted) return;
      _appState = Provider.of<AppStateProvider>(context, listen: false);
      _appState?.fetchProfile();
      
      // Listen for profile errors
      _appState?.addListener(_errorListener);
    });
  }

  void _errorListener() {
    if (!mounted || _appState == null) return;
    if (_appState!.profileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_appState!.profileError!),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Safely remove listener
    _appState?.removeListener(_errorListener);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await Provider.of<AppStateProvider>(context, listen: false).fetchProfile();
  }

  Future<void> _updateProfilePicture() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        try {
          final success = await ApiService.updateProfilePicture(base64Image);
          if (success) {
            if (mounted) {
              await Provider.of<AppStateProvider>(
                context,
                listen: false,
              ).fetchProfile();
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to update image')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Update failed'))));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Error picking image'))));
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _showEditNameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Full Name',
          style: GoogleFonts.baloo2(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: GoogleFonts.inter(color: AppTheme.textMuted),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.saffron),
            ),
          ),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.saffron,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final newName = controller.text.trim();
      if (newName == currentName) return;

      try {
        final success = await ApiService.updateProfileName(newName);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name updated successfully!')),
            );
            await Provider.of<AppStateProvider>(context, listen: false).fetchProfile();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update name')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
          );
        }
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be permanently removed.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final success = await ApiService.deleteAccount();
        if (!context.mounted) return;
        Navigator.pop(context); // Close loading

        if (success) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete account. Please try again.'),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Delete failed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final profileData = appState.profileData;
    final isLoading = appState.isProfileLoading;

    if (isLoading && profileData == null) {
      return const Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final user = profileData?['user'];
    final labourer = profileData?['labourer'];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        edgeOffset: 120, // Offset to start below the hero
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(user, labourer),
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildUserInfoSection(user),
                      _buildAccountSettings(user),
                      const SizedBox(height: 12),
                      _buildLogoutButton(),
                      const SizedBox(height: 80),
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

  Widget _buildHeroSection(dynamic user, dynamic labourer) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 48),
      child: Column(
        children: [
          Row(
            children: [
              _buildGhostBackButton(),
            ],
          ),
          const SizedBox(height: 24),
          // Avatar with premium border
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.saffron, width: 3),
                      image: _getProfileImage(user),
                    ),
                    child: user?['profilePicture'] == null || user['profilePicture'].toString().isEmpty
                        ? const Icon(Icons.person_rounded, size: 54, color: Colors.white70)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _updateProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user?['name'] ?? (labourer != null ? 'Worker' : 'Guest'),
            style: GoogleFonts.baloo2(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textPrimary.withValues(alpha: 0.7), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.edit_rounded, color: AppTheme.saffron.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 24, color: Colors.black.withValues(alpha: 0.05));
  }

  Widget _buildGhostBackButton() {
    if (!Navigator.canPop(context)) return const SizedBox(width: 36, height: 36);
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildUserInfoSection(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal information',
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            Icons.person_outline_rounded,
            'FULL NAME',
            user?['name'] ?? 'Guest User',
            onTap: user != null ? () => _showEditNameDialog(user['name'] ?? '') : null,
          ),
          _buildDivider(),
          _buildDetailRow(
            Icons.email_outlined,
            'EMAIL ADDRESS',
            user?['email'] ?? 'No email set',
          ),
          _buildDivider(),
          _buildDetailRow(
            Icons.location_on_outlined,
            'SAVED ADDRESSES',
            'Manage your locations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legal & Account',
            style: GoogleFonts.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () => _launchURL('https://justlavish.tech/privacy-policy')),
          _buildDivider(),
          _buildSettingItem(Icons.description_outlined, 'Terms of Service', onTap: () => _launchURL('https://justlavish.tech/terms')),
          _buildDivider(),
          _buildSettingItem(Icons.delete_outline_rounded, 'Delete Account', isDestructive: true, onTap: () => _showDeleteAccountDialog(context)),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {VoidCallback? onTap, bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppTheme.error : AppTheme.textPrimary.withValues(alpha: 0.7), size: 22),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppTheme.divider, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: () async {
          final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
          final locationProvider = Provider.of<LocationProvider>(context, listen: false);

          stateProvider.clearData();
          locationProvider.clearData();

          await ApiService.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error.withValues(alpha: 0.1),
          foregroundColor: AppTheme.error,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(
          'LOG OUT',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  DecorationImage? _getProfileImage(dynamic user) {
    if (user?['profilePicture'] == null || user!['profilePicture'].toString().isEmpty) {
      return null;
    }
    final String pic = user['profilePicture'].toString();
    if (pic.startsWith('http')) {
      return DecorationImage(image: NetworkImage(pic), fit: BoxFit.cover);
    } else {
      try {
        return DecorationImage(
          image: MemoryImage(base64Decode(pic.split(',').last)),
          fit: BoxFit.cover,
        );
      } catch (e) {
        return null;
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (await url_launcher.canLaunchUrl(url)) {
        await url_launcher.launchUrl(url, mode: url_launcher.LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e, action: 'Launch failed'))),
        );
      }
    }
  }
}
