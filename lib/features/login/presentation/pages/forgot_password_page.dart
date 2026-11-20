import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/login/presentation/bloc/forgot_password_cubit.dart';
import 'package:got_report/features/login/presentation/widgets/auth_widgets.dart';

/// "Lupa kata sandi": the worker enters their email and the backend sends a
/// reset link. Same look as the login screen.
class ForgotPasswordPage extends StatefulWidget {
  /// Email already typed on the login screen, if any.
  final String? initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final _emailController =
      TextEditingController(text: widget.initialEmail?.trim() ?? '');

  late final ForgotPasswordCubit _cubit = ForgotPasswordCubit(
    authRepository: context.read<AuthRepository>(),
  );

  @override
  void dispose() {
    _cubit.close();
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    _cubit.submit(email: _emailController.text);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state.errorMessage == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      },
      builder: (context, state) => AuthScaffold(
        onBack: _back,
        children: state.sent
            ? _sentContent(context, state.sentTo!)
            : _formContent(context, state),
      ),
    );
  }

  List<Widget> _formContent(BuildContext context, ForgotPasswordState state) {
    return [
      const _Headline(
        icon: Icons.lock_reset_rounded,
        title: 'Lupa Kata Sandi',
        subtitle: 'Masukkan email akun Anda. Kami akan mengirim link untuk '
            'mengatur ulang kata sandi.',
      ),
      const SizedBox(height: 32),
      AuthTextField(
        controller: _emailController,
        label: 'Email',
        hint: 'nama@perusahaan.com',
        icon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        enabled: !state.loading,
        textInputAction: TextInputAction.send,
        autofillHints: const [AutofillHints.email],
        onSubmitted: (_) => _onSubmit(),
      ),
      const SizedBox(height: 24),
      AuthPrimaryButton(
        label: 'Kirim Link',
        loading: state.loading,
        onPressed: state.loading ? null : _onSubmit,
      ),
    ];
  }

  List<Widget> _sentContent(BuildContext context, String email) {
    final c = AuthColors.of(context);
    return [
      const _Headline(
        icon: Icons.mark_email_read_outlined,
        title: 'Periksa Email Anda',
        subtitle: 'Jika email terdaftar, link atur ulang kata sandi sudah '
            'dikirim ke:',
      ),
      const SizedBox(height: 8),
      Text(
        email,
        textAlign: TextAlign.center,
        style: AuthText.small(weight: FontWeight.w700, color: c.textPrimary)
            .copyWith(fontSize: 14),
      ),
      const SizedBox(height: 32),
      AuthPrimaryButton(label: 'Kembali ke Halaman Masuk', onPressed: _back),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: _cubit.reset,
          style: TextButton.styleFrom(foregroundColor: c.link),
          child: Text(
            'Kirim ke email lain',
            style: AuthText.small(weight: FontWeight.w600, color: c.link)
                .copyWith(fontSize: 13),
          ),
        ),
      ),
    ];
  }
}

/// Round icon, title and short explanation, centered.
class _Headline extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Headline({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = AuthColors.of(context);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: c.link.withValues(alpha: c.isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: c.link),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AuthText.title(color: c.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AuthText.small(weight: FontWeight.w500, color: c.grey)
              .copyWith(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}
