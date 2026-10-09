import 'package:flutter/material.dart';

/// ألوان التطبيق الرئيسية
/// اللون الأساسي: تدرج أخضر/فيروزي يعكس هوية اليمن
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF00897B);       // Teal Green
  static const Color primaryDark = Color(0xFF005B4F);
  static const Color primaryLight = Color(0xFF4EBAAA);

  // Accent
  static const Color accent = Color(0xFFFFA000);        // Amber
  static const Color accentLight = Color(0xFFFFD740);

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1C2230);

  // Text
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Category Colors (for section icons)
  static const Color healthColor = Color(0xFFEF4444);
  static const Color educationColor = Color(0xFF3B82F6);
  static const Color safetyColor = Color(0xFFF59E0B);
  static const Color governmentColor = Color(0xFF8B5CF6);
  static const Color tourismColor = Color(0xFF10B981);
  static const Color hospitalityColor = Color(0xFFEC4899);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF1C2230)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Divider & Border
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Shadow
  static Color shadow = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.25);
}
