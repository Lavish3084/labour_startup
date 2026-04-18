import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional design system for the Labour app.
/// Clean, enterprise-grade — no funky colors.
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ─────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B00);        // Saffron primary
  static const Color primaryDark = Color(0xFFE65100);
  static const Color primaryLight = Color(0xFFFFF4EB);
  static const Color primaryStatusGreen = Color(0xFF2E876E);
  static const Color brandGreenMain = Color(0xFF4A9782);
  static const Color brandYellow = Color(0xFFFCD541);
  static const Color grayBgSubtle = Color(0xFFF7F7F7);
  static const Color graySurface = Color(0xFFF0F0F0);
  static const Color grayLightest = Color(0xFFE8E8E8);
  static const Color grayPagination = Color(0xFFD9D9D9);
  static const Color grayBorder = Color(0xFFCFCFCF);
  static const Color black = Colors.black;
  static const Color white = Colors.white;

  static const Color accent = Color(0xFF2952CC);          // Vibrant blue
  static const Color accentLight = Color(0xFFEEF2FF);
  static const Color scaffoldBg = Color(0xFFF8F9FA); // Slightly cooler white
  static const Color surfaceLight = Color(0xFFF3F4F6);
  static const Color primaryGreen = Color(0xFF006D44); // Dark Green for Header
  static const Color saffron = Color(0xFFFF6B00);
  static const Color paleSaffron = Color(0xFFFFF5EE);
  static const Color successGreen = Color(0xFF10B981);
  static const Color offWhite = Color(0xFFFFFAF5);

  static const Color highlight = Color(0xFF0D9488);       // Teal — actions/CTAs
  
  // ─── Figma / Refined UI Colors ───────────────────────────────
  static const Color figmaHeaderStart = Color(0xFF06644A);
  static const Color figmaHeaderEnd = Color(0xFF4A9782);
  static const Color surfaceContainerHigh = Color(0xFFECE6F0);
  static const Color activeCardBg = Color(0xFFF7F7F7);
  static const Color activeCardBorder = Color(0xFF4A9782);

  // ─── Neutral / Surface ────────────────────────────────────────
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
    colors: [Color(0xFFFF6B00), Color(0xFFFF9100)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF2D1A0E)],
  );

  static const LinearGradient profileGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xDA2D2116)],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF1E6), Color(0xFFFFFAF5)],
  );

  static const LinearGradient headerGradientGreen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [figmaHeaderStart, figmaHeaderEnd],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF), // 20% White
      Color(0x0AFFFFFF), // 4% White
    ],
  );

  static BoxDecoration glassDecoration({
    double radius = 16,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.2),
        width: 1.5,
      ),
    );
  }

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

  static List<BoxShadow> get figmaCardShadow => [
    BoxShadow(
      color: const Color(0x14000000),
      blurRadius: 16,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get saffronGlow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
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

  static TextStyle get islandHeading => GoogleFonts.baloo2(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
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
