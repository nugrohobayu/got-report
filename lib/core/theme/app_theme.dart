import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:got_report/core/theme/app_colors.dart';

/// App theme: Plus Jakarta Sans, brand navy / orange / blue.
///
/// - primary (blue)    → main action button, links, active states
/// - secondary (navy)  → app bar, headers, strong text
/// - tertiary (orange) → accents / highlights (use sparingly)
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      secondary: AppColors.navy,
      onSecondary: Colors.white,
      tertiary: AppColors.orange,
      onTertiary: Colors.white,
      error: AppColors.statusTerlambat,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? Colors.white : AppColors.textPrimary,
      onSurfaceVariant:
          isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      outline: isDark ? AppColors.darkBorder : AppColors.border,
      outlineVariant: isDark ? AppColors.darkBorder : AppColors.border,
      primaryContainer: isDark ? AppColors.navy : AppColors.blueTint,
      onPrimaryContainer: isDark ? Colors.white : AppColors.navy,
      // Material 3 widgets (NavigationBar, chips, menus) default to these
      // seed-derived surfaces; pin them to the brand neutrals.
      surfaceContainerLowest: isDark ? AppColors.darkBackground : Colors.white,
      surfaceContainerLow: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceContainer: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceContainerHigh:
          isDark ? AppColors.darkSurfaceHigh : AppColors.background,
      surfaceContainerHighest:
          isDark ? AppColors.darkSurfaceHigh : AppColors.background,
      secondaryContainer:
          isDark ? AppColors.darkSurfaceHigh : AppColors.blueTint,
      onSecondaryContainer: isDark ? Colors.white : AppColors.navy,
      surfaceTint: Colors.transparent,
    );

    final baseText =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseText).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    // Big touch targets for field use.
    const buttonSize = Size(64, 52);
    final buttonText = GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        // Navy app bar in both modes → always light status bar icons.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.placeholder,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : AppColors.navy,
          minimumSize: buttonSize,
          side: BorderSide(color: isDark ? Colors.white54 : AppColors.navy),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: colorScheme.outline,
        refreshBackgroundColor: colorScheme.surface,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.blue,
        selectionColor: AppColors.blue.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.blue,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.blue : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.blue : null,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.blue : null,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: isDark ? AppColors.darkSurfaceHigh : AppColors.blueTint,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (isDark ? Colors.white : AppColors.blue)
                : colorScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? (isDark ? Colors.white : AppColors.blue)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
