import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional design system for the Labour app.
/// Clean, enterprise-grade — no funky colors.
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ─────────────────────────────────────────────
  static const Color primary = Color(0xFF1E3A5F);        // Deep steel blue
  static const Color primaryDark = Color(0xFF152E4D);
  static const Color primaryLight = Color(0xFFE8EEF4);

  static const Color accent = Color(0xFF2563EB);          // Professional blue
  static const Color accentLight = Color(0xFFEFF6FF);

  static const Color highlight = Color(0xFF0D9488);       // Teal — actions/CTAs

  // ─── Neutral / Surface ────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFFF6F7F9);     // Cool off-white
  static const Color cardBg = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);     // Near-black
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFF6B7280);

  // ─── Status Colors ────────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
  );

  // ─── Border Radius ────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 100.0;

  // ─── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: const Color(0xFF111827).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: const Color(0xFF111827).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: const Color(0xFF111827).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Text Styles ──────────────────────────────────────────────
  static TextStyle get heading1 => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get heading3 => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textMuted,
    letterSpacing: 0.6,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ─── Input Decoration ─────────────────────────────────────────
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(
        color: textLight,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: textMuted, size: 20)
          : null,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: error, width: 1),
      ),
    );
  }

  // ─── Button Styles ────────────────────────────────────────────
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusSm),
    ),
    textStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusSm),
    ),
    textStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle get outlineButton => OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    side: const BorderSide(color: border),
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusSm),
    ),
    textStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFEF2F2),
    foregroundColor: error,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusSm),
    ),
    textStyle: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  // ─── Card Decoration ──────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: divider),
  );

  // ─── Status Badge Helper ──────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return success;
      case 'pending':
        return warning;
      case 'cancelled':
        return error;
      case 'completed':
        return info;
      default:
        return textMuted;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFECFDF5);
      case 'pending':
        return const Color(0xFFFFFBEB);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      case 'completed':
        return const Color(0xFFEFF6FF);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  // ─── Category Colors (muted, professional) ────────────────────
  static final List<Color> categoryColors = [
    const Color(0xFF1E3A5F), // Steel blue
    const Color(0xFF059669), // Emerald
    const Color(0xFF7C3AED), // Violet
    const Color(0xFF2563EB), // Blue
    const Color(0xFF0891B2), // Cyan
    const Color(0xFF9333EA), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFF4F46E5), // Indigo
  ];

  static Color categoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  // ─── ThemeData ────────────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    scaffoldBackgroundColor: scaffoldBg,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: scaffoldBg,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: heading3,
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    textTheme: GoogleFonts.interTextTheme(),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 1,
    ),
  );
}
