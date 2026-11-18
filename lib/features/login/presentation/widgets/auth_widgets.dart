import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:got_report/core/theme/app_colors.dart';

// Building blocks shared by the auth screens (login, change password), taken
// from the Figma "Login Version 8" design.

/// Page frame of the auth screens: brand background, blue header blur and
/// [children] centered vertically, still scrollable when the keyboard opens.
class AuthScaffold extends StatelessWidget {
  final List<Widget> children;

  const AuthScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final topInset = padding.top;
    final bottomInset = padding.bottom;
    final c = AuthColors.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(
          children: [
            const AuthHeaderBlur(),
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
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.hint,
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
            padding: const EdgeInsets.all(4),
            child: _obscure
                ? SvgPicture.asset(
                    'assets/images/login/eye_off.svg',
                    width: 16,
                    height: 16,
                    colorFilter: c.svgTint(c.placeholder),
                  )
                : Icon(Icons.visibility_outlined, size: 16, color: c.grey),
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

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.stroke),
    );
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: -0.14,
      color: c.textPrimary,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: c.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x3DE4E5E7),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
      ),
      child: SizedBox(
        height: 46,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          obscuringCharacter: '*',
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
            hintStyle: textStyle.copyWith(color: c.placeholder),
            filled: true,
            fillColor: c.field,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            suffixIcon: suffix,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 38, minHeight: 24),
            border: border,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: c.link),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final radius = BorderRadius.circular(10);
    // Dimmed when disabled; a spinner already shows it is busy.
    final disabled = onPressed == null && !loading;

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          const BoxShadow(
            color: Color(0x7A12305A),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(color: c.link, spreadRadius: 1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: c.buttonInnerBorder),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // White 12% → 0% overlay on brand blue #2F7CC4, pre-blended.
              colors: [const Color(0xFF4A8DCC), c.link],
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.14,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
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
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.64,
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
  final Color buttonInnerBorder;

  AuthColors._({
    required this.isDark,
    required this.background,
    required this.field,
    required this.textPrimary,
    required this.grey,
    required this.placeholder,
    required this.stroke,
    required this.link,
    required this.buttonInnerBorder,
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
      stroke: isDark ? scheme.outline : const Color(0xFFEDF1F3),
      link: scheme.primary,
      buttonInnerBorder: isDark ? scheme.primary : Colors.white,
    );
  }

  /// Recolors single-color SVG icons so they stay visible in dark mode.
  /// In light mode the SVG keeps its original Figma color.
  ColorFilter? svgTint(Color color) =>
      isDark ? ColorFilter.mode(color, BlendMode.srcIn) : null;
}
