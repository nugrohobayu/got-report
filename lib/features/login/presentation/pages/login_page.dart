import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/login/presentation/bloc/login_cubit.dart';
import 'package:got_report/features/login/presentation/widgets/auth_widgets.dart';

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
    final c = AuthColors.of(context);
    final busy = state.isLoading || state.forgotLoading;

    return AuthScaffold(
      children: [
        const _Headline(),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _emailController,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          enabled: !busy,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 8),
        AuthPasswordField(
          controller: _passwordController,
          hint: 'Kata sandi',
          enabled: !busy,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _onLogin(),
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
                    style: AuthText.small(
                      weight: FontWeight.w600,
                      color: c.link,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Masuk',
          loading: state.isLoading,
          onPressed: busy ? null : _onLogin,
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final c = AuthColors.of(context);

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
          style: AuthText.title(color: c.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'Masukkan email dan kata sandi untuk masuk',
          style: AuthText.small(weight: FontWeight.w500, color: c.grey),
        ),
      ],
    );
  }
}
