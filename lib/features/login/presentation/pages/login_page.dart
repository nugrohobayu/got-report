import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/login/presentation/bloc/login_cubit.dart';

/// Login screen based on Figma "Login Version 8" (node 44:5551), adapted to
/// the brand: app icon as logo, brand blue, no social login / remember me /
/// sign up.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final LoginCubit _cubit = LoginCubit(
    authRepository: context.read<AuthRepository>(),
    sessionCubit: context.read<SessionCubit>(),
  );

  @override
  void dispose() {
    _cubit.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // On success SessionCubit flips to authenticated and the router redirects.
  void _onLogin() {
    FocusScope.of(context).unfocus();
    _cubit.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _onForgotPassword() {
    FocusScope.of(context).unfocus();
    _cubit.forgotPassword(email: _emailController.text);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showSnackBar(state.errorMessage!, isError: true);
        } else if (state.infoMessage != null) {
          _showSnackBar(state.infoMessage!);
        }
      },
      builder: (context, state) => _buildContent(context, state),
    );
  }

  Widget _buildContent(BuildContext context, LoginState state) {
    final padding = MediaQuery.paddingOf(context);
    final topInset = padding.top;
    final bottomInset = padding.bottom;
    final c = _LoginColors.of(context);
    final busy = state.isLoading || state.forgotLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(
          children: [
            const _HeaderBlur(),
            // Centered vertically; still scrolls when the keyboard is open.
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
                    children: [
                      const _Headline(),
                      const SizedBox(height: 16),
                      _LoginTextField(
                        controller: _emailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 8),
                      _LoginTextField(
                        controller: _passwordController,
                        hint: 'Kata sandi',
                        obscureText: _obscurePassword,
                        enabled: !busy,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _onLogin(),
                        suffix: GestureDetector(
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _obscurePassword
                                ? SvgPicture.asset(
                                    'assets/images/login/eye_off.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: c.svgTint(c.placeholder),
                                  )
                                : Icon(
                                    Icons.visibility_outlined,
                                    size: 16,
                                    color: c.grey,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: busy ? null : _onForgotPassword,
                          child: state.forgotLoading
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.link,
                                  ),
                                )
                              : Text(
                                  'Lupa kata sandi?',
                                  style: _LoginText.small(
                                    weight: FontWeight.w600,
                                    color: c.link,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PrimaryButton(
                        label: 'Masuk',
                        loading: state.isLoading,
                        onPressed: busy ? null : _onLogin,
                      ),
                    ],
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

/// Decorative blue blur at the top of the screen (Figma node 48:5788).
///
/// flutter_svg ignores SVG `<filter>`, so the Gaussian blur from the design
/// (stdDeviation ≈ 26) is applied with [ImageFiltered] instead.
class _HeaderBlur extends StatelessWidget {
  const _HeaderBlur();

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

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final c = _LoginColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 44,
              height: 44,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Masuk ke Akun Anda',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: -0.64,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Masukkan email dan kata sandi untuk masuk',
          style: _LoginText.small(weight: FontWeight.w500, color: c.grey),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const _LoginTextField({
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
    final c = _LoginColors.of(context);
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = _LoginColors.of(context);
    final radius = BorderRadius.circular(10);

    return DecoratedBox(
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
  }
}

class _LoginText {
  _LoginText._();

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
class _LoginColors {
  final bool isDark;
  final Color background;
  final Color field;
  final Color textPrimary;
  final Color grey;
  final Color placeholder;
  final Color stroke;
  final Color link;
  final Color buttonInnerBorder;

  _LoginColors._({
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

  factory _LoginColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return _LoginColors._(
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
