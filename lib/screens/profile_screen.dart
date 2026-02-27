import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/location_provider.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'saved_addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
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
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final profileData = appState.profileData;
    final isLoading = appState.isProfileLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading && profileData == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Picture
                      Center(
                        child: GestureDetector(
                          onTap: _updateProfilePicture,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  image: DecorationImage(
                                    image:
                                        profileData?['user'] != null &&
                                                profileData!['user']['profilePicture'] !=
                                                    null &&
                                                profileData['user']['profilePicture']
                                                    .toString()
                                                    .isNotEmpty
                                            ? (profileData['user']['profilePicture']
                                                        .toString()
                                                        .startsWith('http')
                                                    ? NetworkImage(
                                                      profileData['user']['profilePicture'],
                                                    )
                                                    : MemoryImage(
                                                      base64Decode(
                                                        profileData['user']['profilePicture']
                                                            .toString()
                                                            .split(',')
                                                            .last,
                                                      ),
                                                    ))
                                                as ImageProvider
                                            : const NetworkImage(
                                              'https://randomuser.me/api/portraits/men/1.jpg',
                                            ),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name and Role
                      Text(
                        profileData?['user']['name'] ?? 'User',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (profileData?['user']['role'] ?? 'user').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Settings Sections
                      _buildSectionHeader('Account Information'),
                      const SizedBox(height: 10),
                      _buildProfileOption(
                        Icons.person_outline,
                        'Full Name',
                        profileData?['user']['name'] ?? '',
                      ),
                      _buildProfileOption(
                        Icons.email_outlined,
                        'Email',
                        profileData?['user']['email'] ?? '',
                      ),
                      if (profileData?['labourer'] != null) ...[
                        _buildProfileOption(
                          Icons.work_outline,
                          'Category',
                          profileData?['labourer']['category'] ?? '',
                        ),
                        _buildProfileOption(
                          Icons.location_on_outlined,
                          'Location',
                          profileData?['labourer']['location'] ?? '',
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildSectionHeader('Settings'),
                      const SizedBox(height: 10),
                      _buildProfileOption(
                        Icons.location_on_outlined,
                        'Saved Addresses',
                        'Manage locations',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const SavedAddressesScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final stateProvider = Provider.of<AppStateProvider>(
                              context,
                              listen: false,
                            );
                            final locationProvider =
                                Provider.of<LocationProvider>(
                                  context,
                                  listen: false,
                                );

                            stateProvider.clearData();
                            locationProvider.clearData();

                            await ApiService.logout();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Log Out',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle:
            subtitle.isNotEmpty
                ? Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                )
                : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
