import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_category.dart';

class ServiceCategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const ServiceCategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.02),
          //     blurRadius: 5,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: const Color(0xFF2C3E50), size: 32),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
