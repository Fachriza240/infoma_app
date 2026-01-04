import 'package:flutter/material.dart';

class AppColors {
  // ========================================
  // BRAND COLORS - Sesuai Logo InfoMA
  // ========================================

  // Primary - Navy Blue (dari logo InfoMA)
  static const Color primary = Color(0xFF0A1E5E); // Navy Blue
  static const Color primaryDark = Color(0xFF081647);
  static const Color primaryLight = Color(0xFF1E3A8A);

  // Secondary - Yellow Gold (dari logo InfoMA - huruf 'a' dan kaca pembesar)
  static const Color secondary = Color(0xFFFFD500); // Bright Yellow
  static const Color secondaryDark = Color(0xFFFFB800);
  static const Color secondaryLight = Color(0xFFFFE44D);

  // Accent Colors
  static const Color accent = Color(0xFF4CAF50); // Green untuk success
  static const Color accentOrange = Color(0xFFFF8A00); // Orange untuk highlight

  // ========================================
  // STATUS COLORS
  // ========================================
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ========================================
  // NEUTRAL COLORS
  // ========================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);
  static const Color greyExtraLight = Color(0xFFF5F5F5);

  // ========================================
  // BACKGROUND COLORS
  // ========================================
  static const Color background = Color(0xFFF8F9FD); // Soft blue-tinted white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ========================================
  // TEXT COLORS
  // ========================================
  static const Color textPrimary =
      Color(0xFF0A1E5E); // Navy Blue - matching primary
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on navy
  static const Color textOnSecondary = Color(0xFF0A1E5E); // Navy text on yellow

  // ========================================
  // SPECIFIC ELEMENTS
  // ========================================
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);

  // ========================================
  // GRADIENT COLORS
  // ========================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A1E5E), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFFD500), Color(0xFFFFB800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================
  // CATEGORY SPECIFIC COLORS
  // ========================================

  // Residence/Hunian
  static const Color residencePrimary = Color(0xFF0A1E5E); // Navy
  static const Color residenceAccent = Color(0xFFFFD500); // Yellow

  // Activity/Kegiatan
  static const Color activityPrimary = Color(0xFF1E3A8A); // Blue
  static const Color activityAccent = Color(0xFF4CAF50); // Green

  // Marketplace
  static const Color marketplacePrimary = Color(0xFFFF8A00); // Orange
  static const Color marketplaceAccent = Color(0xFFFFD500); // Yellow

  // ========================================
  // BOOKING STATUS COLORS
  // ========================================
  static const Color statusPending = Color(0xFFFFB800); // Yellow
  static const Color statusApproved = Color(0xFF4CAF50); // Green
  static const Color statusRejected = Color(0xFFF44336); // Red
  static const Color statusCompleted = Color(0xFF2196F3); // Blue
  static const Color statusCancelled = Color(0xFF9E9E9E); // Grey
}
