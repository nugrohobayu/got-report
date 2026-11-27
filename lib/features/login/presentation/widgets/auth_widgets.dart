import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ada_tugas/core/theme/app_colors.dart';

// Building blocks shared by the auth screens (login, change password), taken
// from the Figma "Login Version 8" design.

/// Page frame of the auth screens: brand background, blue header blur,
/// orange top-right glow and
/// [children] centered vertically, still scrollable when the keyboard opens.
class AuthScaffold extends StatelessWidget {
  final List<Widget> children;

  /// Shows a back button at the top left when set.
  final VoidCallback? onBack;

  const AuthScaffold({super.key, required this.children, this.onBack});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    // Keep content clear of the back button.
    final topInset = padding.top + (onBack != null ? 48 : 0);
    final bottomInset = padding.bottom;
    final c = AuthColors.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(
          children: [
            const AuthHeaderBlur(),
            const AuthCornerGlow(),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  topInset + 8,
                  24,
                  bottomInset + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight - topInset - bottomInset - 48,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
            if (onBack != null)
              Positioned(
                top: padding.top + 4,
                left: 8,
                child: IconButton(
                  onPressed: onBack,
                  tooltip: 'Kembali',
                  icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [AuthTextField] for passwords, with a show / hide toggle.
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = AuthColors.of(context);

    return AuthTextField(
      controller: widget.controller,
      hint: widget.hint,
      label: widget.label,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      suffix: Semantics(
        button: true,
        label: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
        child: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: c.placeholder,
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative blue blur at the top of the screen (Figma node 48:5788).
///
/// flutter_svg ignores SVG `<filter>`, so the Gaussian blur from the design
/// (stdDeviation ≈ 26) is applied with [ImageFiltered] instead.
class AuthHeaderBlur extends StatelessWidget {
  const AuthHeaderBlur({super.key});

  // Figma frame is 375 wide; the blur box is offset relative to it.
  static const double _frameWidth = 375;
  static const double _boxSize = 844.46;
  static const double _boxLeft = -229.73;
  static const double _boxTop = -422.78;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final left = _boxLeft + (screenWidth - _frameWidth) / 2;

    return Positioned(
      left: left,
      top: _boxTop,
      width: _boxSize,
      height: _boxSize,
      child: IgnorePointer(
        child: Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationZ(19.24 * math.pi / 180)
              ..scale(1.0, -1.0),
            child: SizedBox(
              width: 663,
              height: 663,
              child: OverflowBox(
                maxWidth: 883.035,
                maxHeight: 767.775,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                  child: SvgPicture.asset(
                    'assets/images/login/header_blur.svg',
                    width: 883.035,
                    height: 767.775,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft orange glow in the top-right corner, layered over [AuthHeaderBlur]
/// on the in-app pages. Place it inside a [Stack].
class AuthCornerGlow extends StatelessWidget {
  const AuthCornerGlow({super.key});

  static const double _size = 360;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: -_size / 2,
      right: -_size / 2,
      width: _size,
      height: _size,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.orange.withValues(alpha: isDark ? 0.30 : 0.45),
                AppColors.orange.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  /// Optional label shown above the field.
  final String? label;

  /// Optional leading icon inside the field.
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = AuthColors.of(context);
    final radius = BorderRadius.circular(14);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: c.stroke),
    );
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: -0.15,
      color: c.textPrimary,
    );

    final field = TextField(
      controller: controller,
      obscureText: obscureText,
      obscuringCharacter: '•',
      keyboardType: keyboardType,
      enabled: enabled,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      autocorrect: false,
      style: textStyle,
      cursorColor: c.link,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: textStyle.copyWith(
          color: c.placeholder,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: c.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        prefixIcon:
            icon == null ? null : Icon(icon, size: 20, color: c.placeholder),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 24),
        suffixIcon: suffix,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 24),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: c.link, width: 1.5),
        ),
      ),
    );
    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label!,
          style: AuthText.small(weight: FontWeight.w600, color: c.grey)
              .copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

/// Flat, solid brand-blue button for the auth screens.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AuthColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final radius = BorderRadius.circular(14);
    // Dimmed when disabled; a spinner already shows it is busy.
    final disabled = onPressed == null && !loading;

    final button = Material(
      color: c.link,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          // Same height as [AuthTextField] so the form lines up.
          height: 50,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onPrimary,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.15,
                      color: onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1,
      duration: const Duration(milliseconds: 150),
      child: button,
    );
  }
}

class AuthText {
  AuthText._();

  /// Screen headline, e.g. "Masuk ke Akun Anda".
  static TextStyle title({required Color color}) => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.7,
        color: color,
      );

  static TextStyle small({
    required FontWeight weight,
    required Color color,
    double height = 1.4,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: weight,
        height: height,
        letterSpacing: -0.12,
        color: color,
      );
}

/// Login colors resolved from the app theme so the screen follows
/// light / dark mode. Light values match the Figma design.
class AuthColors {
  final bool isDark;
  final Color background;
  final Color field;
  final Color textPrimary;
  final Color grey;
  final Color placeholder;
  final Color stroke;
  final Color link;

  AuthColors._({
    required this.isDark,
    required this.background,
    required this.field,
    required this.textPrimary,
    required this.grey,
    required this.placeholder,
    required this.stroke,
    required this.link,
  });

  factory AuthColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AuthColors._(
      isDark: isDark,
      background:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFEDF1F3),
      field: isDark ? scheme.surface : Colors.white,
      textPrimary: isDark ? scheme.onSurface : const Color(0xFF1A1C1E),
      grey: isDark ? scheme.onSurfaceVariant : const Color(0xFF6C7278),
      placeholder: isDark ? AppColors.darkTextSecondary : AppColors.placeholder,
      stroke: isDark ? scheme.outline : const Color(0xFFE2E6EA),
      link: scheme.primary,
    );
  }

  /// Recolors single-color SVG icons so they stay visible in dark mode.
  /// In light mode the SVG keeps its original Figma color.
  ColorFilter? svgTint(Color color) =>
      isDark ? ColorFilter.mode(color, BlendMode.srcIn) : null;
}
