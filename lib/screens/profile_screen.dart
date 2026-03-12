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
import 'login_screen.dart';
import 'saved_addresses_screen.dart';
import 'worker_details_screen.dart';

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
    // Fetch profile data when screen initializes to ensure fresh data
    Future.microtask(
      () =>
          Provider.of<AppStateProvider>(context, listen: false).fetchProfile(),
    );
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
      body:
          isLoading && profileData == null
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 40,
                            ), // Spacer for back button
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
                                        image:
                                            profileData?['user'] != null &&
                                                    profileData!['user']['profilePicture'] !=
                                                        null &&
                                                    profileData['user']['profilePicture']
                                                        .toString()
                                                        .isNotEmpty
                                                ? DecorationImage(
                                                  image:
                                                      profileData['user']['profilePicture']
                                                              .toString()
                                                              .startsWith(
                                                                'http',
                                                              )
                                                          ? NetworkImage(
                                                            profileData['user']['profilePicture'],
                                                          )
                                                          : MemoryImage(
                                                                base64Decode(
                                                                  profileData['user']['profilePicture']
                                                                      .toString()
                                                                      .split(
                                                                        ',',
                                                                      )
                                                                      .last,
                                                                ),
                                                              )
                                                              as ImageProvider,
                                                  fit: BoxFit.cover,
                                                )
                                                : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child:
                                          profileData?['user']?['profilePicture'] ==
                                                      null ||
                                                  profileData!['user']['profilePicture']
                                                      .toString()
                                                      .isEmpty
                                              ? const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey,
                                              )
                                              : null,
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
                              (profileData?['user']['role'] ?? 'user')
                                  .toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 30),

                            const SizedBox(height: 30),
                            // Professional Info Card (Worker Only)
                            if (profileData?['labourer'] != null) ...[
                              _buildProfessionalCard(profileData!['labourer']),
                              const SizedBox(height: 20),
                            ],

                            // Settings Sections
                            const SizedBox(height: 10),
                            if (profileData?['user']?['role'] != 'worker') ...[
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
                            ],

                            const SizedBox(height: 20),

                            // Hide Saved Addresses for workers
                            if (profileData?['user']?['role'] != 'worker')
                              _buildProfileOption(
                                Icons.location_on_outlined,
                                'Saved Addresses',
                                'Manage locations',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const SavedAddressesScreen(),
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 10),
                            _buildSectionHeader('About & Policies'),
                            const SizedBox(height: 10),
                            _buildProfileOption(
                              Icons.privacy_tip_outlined,
                              'Privacy Policy',
                              'Read our privacy policy',
                              onTap: () {
                                _launchURL('https://labour-dashboard.onrender.com/privacy-policy');
                              },
                            ),
                            _buildProfileOption(
                              Icons.description_outlined,
                              'Terms of Service',
                              'Read our terms and conditions',
                              onTap: () {
                                _launchURL('https://labour-dashboard.onrender.com/terms');
                              },
                            ),

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final stateProvider =
                                      Provider.of<AppStateProvider>(
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
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
                      // Custom Back Button
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black87,
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

  Widget _buildProfessionalCard(Map<String, dynamic> labourer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Professional Details',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      labourer['category'] ?? 'Worker',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerDetailsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Location',
            labourer['location'] ?? '',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.payments_outlined,
            'Hourly Rate',
            '₹${labourer['hourlyRate'] ?? '0'}/hr',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.history_outlined,
            'Experience',
            '${labourer['experienceYears'] ?? '0'} Years',
          ),
          const SizedBox(height: 20),
          Text(
            'Skills',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          if (labourer['skills'] != null &&
              (labourer['skills'] as List).isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (labourer['skills'] as List).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        skill.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            )
          else
            Text(
              'No skills listed',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
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

  Future<void> _launchURL(String urlString) async {
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
