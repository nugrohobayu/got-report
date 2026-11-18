import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Login screen sliced from Figma "Login Version 3" (node 3:16852).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    // TODO: hook up LoginBloc → POST /auth/login.
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _LoginColors.background,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // Blue header block with grid/star pattern.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _LoginLayout.headerHeight + topInset,
                child: ClipRect(
                  child: ColoredBox(
                    color: _LoginColors.headerBlue,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -7,
                          left: -1,
                          right: -1,
                          child: Image.asset(
                            'assets/images/login/header_pattern.png',
                            width: 376,
                            height: 387,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, topInset + 24, 24, 24),
                child: Column(
                  children: [
                    const _Headline(),
                    const SizedBox(height: 31),
                    _LoginCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      rememberMe: _rememberMe,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onToggleRemember: () =>
                          setState(() => _rememberMe = !_rememberMe),
                      onLogin: _onLogin,
                    ),
                  ],
                ),
              ),
            ],
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
    return Column(
      children: [
        SvgPicture.asset('assets/images/login/logo.svg', width: 28, height: 28),
        const SizedBox(height: 24),
        Text(
          'Masuk ke Akun Anda',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.64,
            color: _LoginColors.headlineText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Masukkan email dan kata sandi untuk masuk',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.12,
            color: _LoginColors.headlineText,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleRemember;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onToggleObscure,
    required this.onToggleRemember,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoogleButton(onPressed: () {}),
          const SizedBox(height: 24),
          const _OrDivider(),
          const SizedBox(height: 24),
          _LoginTextField(
            controller: emailController,
            hint: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _LoginTextField(
            controller: passwordController,
            hint: 'Kata sandi',
            obscureText: obscurePassword,
            suffix: GestureDetector(
              onTap: onToggleObscure,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: obscurePassword
                    ? SvgPicture.asset(
                        'assets/images/login/eye_off.svg',
                        width: 16,
                        height: 16,
                      )
                    : const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: _LoginColors.grey,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: onToggleRemember,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    rememberMe
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: Center(
                              child: Icon(
                                Icons.check_box_rounded,
                                size: 16,
                                color: _LoginColors.link,
                              ),
                            ),
                          )
                        : SvgPicture.asset(
                            'assets/images/login/checkbox_off.svg',
                            width: 19,
                            height: 19,
                          ),
                    const SizedBox(width: 5),
                    Text(
                      'Ingat saya',
                      style: _LoginText.small(
                        weight: FontWeight.w500,
                        color: _LoginColors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Lupa kata sandi?',
                  style: _LoginText.small(
                    weight: FontWeight.w600,
                    color: _LoginColors.link,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PrimaryButton(label: 'Masuk', onPressed: onLogin),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Belum punya akun?',
                style: _LoginText.small(
                  weight: FontWeight.w500,
                  color: _LoginColors.grey,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Daftar',
                  style: _LoginText.small(
                    weight: FontWeight.w600,
                    color: _LoginColors.link,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _LoginColors.googleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/login/google.svg',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Lanjutkan dengan Google',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.14,
                  color: _LoginColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
          child: SvgPicture.asset(
            'assets/images/login/divider_line.svg',
            height: 1,
            fit: BoxFit.fill,
          ),
        );

    return Row(
      children: [
        line(),
        const SizedBox(width: 16),
        Text(
          'Atau masuk dengan',
          style: _LoginText.small(
            weight: FontWeight.w400,
            color: _LoginColors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(width: 16),
        line(),
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

  const _LoginTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _LoginColors.stroke),
    );
    final textStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: -0.14,
      color: _LoginColors.textPrimary,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
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
          style: textStyle,
          cursorColor: _LoginColors.headerBlue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textStyle.copyWith(color: _LoginColors.placeholder),
            filled: true,
            fillColor: Colors.white,
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
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: _LoginColors.buttonRing),
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

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x7A253EA7),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(color: _LoginColors.buttonRing, spreadRadius: 1),
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
            border: Border.all(color: Colors.white),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // White 12% → 0% overlay on #1D61E7, pre-blended.
              colors: [Color(0xFF3A75EA), _LoginColors.buttonBlue],
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: -0.14,
                  color: Colors.white,
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
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: weight,
        height: height,
        letterSpacing: -0.12,
        color: color,
      );
}

class _LoginLayout {
  _LoginLayout._();

  /// Figma header height (397) minus the 44px mock status bar.
  static const double headerHeight = 397 - 44;
}

class _LoginColors {
  _LoginColors._();

  static const background = Color(0xFFF6F8FA);
  static const headerBlue = Color(0xFF2567E8);
  static const headlineText = Color(0xFFEEEEEE);
  static const textPrimary = Color(0xFF1A1C1E);
  static const grey = Color(0xFF6C7278);
  static const placeholder = Color(0xFFACB5BB);
  static const link = Color(0xFF4D81E7);
  static const stroke = Color(0xFFEDF1F3);
  static const googleBorder = Color(0xFFEFF0F6);
  static const buttonBlue = Color(0xFF1D61E7);
  static const buttonRing = Color(0xFF375DFB);
}
