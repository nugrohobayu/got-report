import 'package:flutter/material.dart';

/// Brand palette and status colors shared across the app.
class AppColors {
  AppColors._();

  // Brand
  static const Color navy = Color(0xFF12305A);
  static const Color orange = Color(0xFFE8611A);
  static const Color blue = Color(0xFF2F7CC4);

  // Neutrals
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF14213D);
  static const Color textSecondary = Color(0xFF5B6B7F);
  static const Color border = Color(0xFFDCE3EC);
  static const Color placeholder = Color(0xFFACB5BB);
  static const Color blueTint = Color(0xFFDCEAF7);

  // Dark mode neutrals
  static const Color darkBackground = Color(0xFF0B1A30);
  static const Color darkSurface = Color(0xFF12253F);
  static const Color darkSurfaceHigh = Color(0xFF1A3150);
  static const Color darkTextSecondary = Color(0xFFB4C0D0);
  static const Color darkBorder = Color(0xFF2C4262);

  // Status tugas (same as web): Belum abu, Berjalan biru, Selesai hijau,
  // Terlambat merah.
  static const Color statusBelum = Color(0xFF8A94A6);
  static const Color statusBerjalan = blue;
  static const Color statusSelesai = Color(0xFF2E9E5B);
  static const Color statusTerlambat = Color(0xFFD93A3A);

  static Color forStatus(String status) {
    switch (status.toUpperCase()) {
      case 'BERJALAN':
        return statusBerjalan;
      case 'SELESAI':
        return statusSelesai;
      case 'TERLAMBAT':
        return statusTerlambat;
      case 'BELUM':
      default:
        return statusBelum;
    }
  }
}
