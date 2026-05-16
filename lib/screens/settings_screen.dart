import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1D1B20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Settings',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(width: 36), // Spacer balancing the circle button on left
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preferences Section
                    Text(
                      'Preferences',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF595959),
                        letterSpacing: 0.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTile(
                            icon: Icons.contrast_rounded,
                            title: 'Theme',
                            onTap: () => _showComingSoon(context),
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.notifications_rounded,
                            title: 'Notification & reminders',
                            onTap: () => _showComingSoon(context),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Info Section
                    Text(
                      'Info',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF595959),
                        letterSpacing: 0.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTile(
                            icon: Icons.sticky_note_2_outlined,
                            title: 'Terms of Service',
                            onTap: () => _launchURL(context, 'https://justlavish.tech/terms'),
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () => _launchURL(context, 'https://justlavish.tech/privacy-policy'),
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.help_rounded,
                            title: 'Help Center',
                            onTap: () => _showHelpSupportSheet(context),
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.info_rounded,
                            title: 'About Us',
                            onTap: () => _showComingSoon(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1D1B20),
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D1B20),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF757575),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: const Color(0xFFEAEAEA),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Using LaunchMode.externalApplication to guarantee opening in external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch the link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showHelpSupportSheet(BuildContext context) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;
    bool isSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isSuccess) ...[
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1B20).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF1D1B20),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ticket Submitted!',
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D1B20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We have received your help request. Our team will review it and resolve it shortly.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D1B20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Help & Support',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Have an issue or query? Describe it here and our admin support will get back to you.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.roboto(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Subject / Topic',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Payment issue, Service booking help',
                      hintStyle: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1D1B20), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.roboto(fontSize: 15),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Message / Description',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Write full details here...',
                      hintStyle: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1D1B20), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.roboto(fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final sub = subjectController.text.trim();
                              final msg = messageController.text.trim();
                              if (sub.isEmpty || msg.isEmpty) {
                                setModalState(() {
                                  errorMessage = 'Please fill out all fields.';
                                });
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                errorMessage = null;
                              });

                              final res = await ApiService.submitHelpRequest(sub, msg);

                              if (res['success'] == true) {
                                setModalState(() {
                                  isSuccess = true;
                                  isSubmitting = false;
                                });
                              } else {
                                setModalState(() {
                                  errorMessage = res['message'] ?? 'Failed to submit help request.';
                                  isSubmitting = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D1B20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Submit Support Ticket',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
