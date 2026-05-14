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
import 'manage_profile_screen.dart';
import 'refer_earn_screen.dart';

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
    Future.microtask(() {
      if (!mounted) return;
      _appState = Provider.of<AppStateProvider>(context, listen: false);
      _appState?.fetchProfile();
      _appState?.addListener(_errorListener);
    });
  }

  void _errorListener() {
    if (!mounted || _appState == null) return;
    if (_appState!.profileError != null) {
      if (_appState!.profileError!.contains('Unauthorized')) {
        _handleLogout();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_appState!.profileError!),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
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

        final success = await ApiService.updateProfilePicture(base64Image);
        if (success && mounted) {
          await Provider.of<AppStateProvider>(
            context,
            listen: false,
          ).fetchProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorHandler.getErrorMessage(e, action: 'Image update failed'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final profileData = appState.profileData;
    final isLoading = appState.isProfileLoading;

    if (isLoading && profileData == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A9782)),
        ),
      );
    }

    final user = profileData?['user'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1B20),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF4A9782),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ), // ADJUST SPACING: Gap between AppBar and User Card (Original: 24)
              _buildUserCard(user),
              const SizedBox(
                height: 36,
              ), // ADJUST SPACING: Gap between User Card and 'Accounts' section (Original: 32)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Accounts',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF595959),
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              const SizedBox(
                height: 22,
              ), // ADJUST SPACING: Gap between header and list (Original: 16)
              _buildAccountsList(user),
              const SizedBox(
                height: 40,
              ), // ADJUST SPACING: Bottom clearance (Original: 40)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final name = user?['name'] ?? 'Guest User';
    final email = user?['email'] ?? 'No email set';
    final rating = user?['rating']?.toString() ?? '4.5';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(
        20,
      ), // ADJUST SPACING: Inner padding of the profile card (Original: 24)
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _updateProfilePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: _getProfileImage(user),
                    color: const Color(0xFFF2F2F2),
                  ),
                  child:
                      user?['profilePicture'] == null
                          ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D1B20),
                        height: 1.27,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF49454F),
                        height: 1.43,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(dynamic user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Manage Profile',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageProfileScreen(),
                  ),
                ),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Password & Security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password settings coming soon')),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedAddressesScreen(),
                  ),
                ),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.share_outlined,
            title: 'Refer & Earn',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReferEarnScreen(),
                  ),
                ),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            isDestructive: true,
            onTap: _handleLogout,
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            isDestructive: true,
            onTap: _handleDeleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 5,
      ), // ADJUST SPACING: Vertical padding of list items
      dense: true, // Set to false for more vertical height
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF1D1B20),
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : const Color(0xFF1D1B20),
          letterSpacing: 0.15,
          height: 1.5,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFBBBBBB),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFDBDBDB)),
    );
  }

  Future<void> _handleLogout() async {
    final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    stateProvider.clearData();
    locationProvider.clearData();

    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account?',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete your account, profile information, saved addresses, and all associated data. This action cannot be undone.',
          style: GoogleFonts.roboto(
            color: const Color(0xFF555555),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ApiService.deleteAccount();
      if (success && mounted) {
        final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        stateProvider.clearData();
        locationProvider.clearData();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  DecorationImage? _getProfileImage(dynamic user) {
    if (user?['profilePicture'] == null ||
        user!['profilePicture'].toString().isEmpty) {
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
}
