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
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPickingImage = false;
  AppStateProvider? _appState;
  String? _lastProfileError;

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
    final currentError = _appState!.profileError;
    if (currentError != null && currentError != _lastProfileError) {
      _lastProfileError = currentError;
      if (currentError.contains('Unauthorized')) {
        _handleLogout();
        return;
      }
      if (_appState!.selectedTab == 3) {
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
      _lastProfileError = null;
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

  Future<void> _openUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await url_launcher.canLaunchUrl(url)) {
        await url_launcher.launchUrl(
          url,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open $urlString')));
        }
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  void _showSupportDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Help & Support',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help you today?',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          hintText: 'Subject',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Describe your issue...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isSubmitting
                              ? null
                              : () async {
                                final subject = subjectController.text.trim();
                                final msg = messageController.text.trim();

                                if (subject.isEmpty || msg.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fill out all fields',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isSubmitting = true);

                                try {
                                  final res =
                                      await ApiService.submitHelpRequest(
                                        subject,
                                        msg,
                                      );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          res['message'] ??
                                              'Help request submitted!',
                                        ),
                                        backgroundColor:
                                            res['success'] == true
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Submission failed: ${ErrorHandler.getErrorMessage(e)}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  setDialogState(() => isSubmitting = false);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9782),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child:
                          isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Submit',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
                  ],
                ),
          ),
    );
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
    final name = user?['name'] ?? 'Guest User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF143B2E,
        ), // Deep elegant green matching image
        elevation: 0,
        automaticallyImplyLeading: false,
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF4A9782),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header user details inside dark green card block
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF143B2E),
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 32,
                      top: 8,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _updateProfilePicture,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              image: _getProfileImage(user),
                            ),
                            child:
                                user?['profilePicture'] == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 42,
                                      color: Colors.white,
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
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?['phoneNumber'] ??
                                    user?['email'] ??
                                    'No number set',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const ManageProfileScreen(),
                                      ),
                                    ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Edit profile',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(
                                          0xFF8CD8B4,
                                        ), // light mint green
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 14,
                                      color: Color(0xFF8CD8B4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Grid of 3 side-by-side cards
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        _buildGridCard(
                          icon: Icons.assignment_outlined,
                          title: 'My bookings',
                          onTap: () {
                            Provider.of<AppStateProvider>(
                              context,
                              listen: false,
                            ).setTab(1);
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildGridCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Will Wallet',
                          badgeText: '₹${appState.walletBalance.toInt()}',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WalletScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildGridCard(
                          icon: Icons.headset_mic_outlined,
                          title: 'Help & Support',
                          onTap: _showSupportDialog,
                        ),
                      ],
                    ),
                  ),

                  // 3. Refer & earn pill card
                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReferEarnScreen(),
                          ),
                        ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard_rounded,
                            color: Color(0xFFD97706),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Refer & earn',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Upto ₹100',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Large options card list
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                        _buildListItem(
                          icon: Icons.menu_book_rounded,
                          title: 'Saved addresses',
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const SavedAddressesScreen(),
                                ),
                              ),
                        ),
                        _buildListDivider(),
                        _buildListItem(
                          icon: Icons.info_outline_rounded,
                          title: 'About us',
                          onTap:
                              () =>
                                  _openUrl('https://justlavish.tech/about-us'),
                        ),
                        _buildListDivider(),
                        _buildListItem(
                          icon: Icons.assignment_outlined,
                          title: 'Terms of services',
                          onTap:
                              () => _openUrl('https://justlavish.tech/terms'),
                        ),
                        _buildListDivider(),
                        _buildListItem(
                          icon: Icons.shield_outlined,
                          title: 'Privacy policy',
                          onTap:
                              () => _openUrl(
                                'https://justlavish.tech/privacy-policy',
                              ),
                        ),
                        _buildListDivider(),
                        _buildListItem(
                          icon: Icons.assignment_late_outlined,
                          title: 'Request account deletion',
                          onTap: _handleDeleteAccount,
                        ),
                        _buildListDivider(),
                        _buildListItem(
                          icon: Icons.logout_rounded,
                          title: 'Log out',
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(), // Pushes the app version to the bottom of the remaining space
                  // 5. App version
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom:
                          110, // Fixed bottom padding to accommodate bottom nav bar
                    ),
                    child: Center(
                      child: Text(
                        'APP VERSION: 1.4.6 (22a5)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required String title,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: const Color(0xFF475569), size: 26),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A9782),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF475569), size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey[400],
        size: 20,
      ),
    );
  }

  Widget _buildListDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Account?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'This will permanently delete your account, profile information, saved addresses, and all associated data. This action cannot be undone.',
              style: GoogleFonts.inter(
                color: const Color(0xFF555555),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
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
        final stateProvider = Provider.of<AppStateProvider>(
          context,
          listen: false,
        );
        final locationProvider = Provider.of<LocationProvider>(
          context,
          listen: false,
        );
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
