import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/auth/session_cubit.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/features/change_password/presentation/bloc/change_password_cubit.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/login/presentation/widgets/auth_widgets.dart';

/// Shown right after login when the server returns `mustChangePassword`.
/// The router keeps the user here until the password is changed (then back
/// to login, since the server revokes every session).
///
/// Same look as the login screen.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  late final _fields = Listenable.merge(
    [_currentController, _newController, _confirmController],
  );

  late final ChangePasswordCubit _cubit = ChangePasswordCubit(
    authRepository: context.read<AuthRepository>(),
    sessionCubit: context.read<SessionCubit>(),
  );

  @override
  void dispose() {
    _cubit.close();
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    _cubit.submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // App-level messenger, so the success message stays visible on the
    // login page the router moves to.
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
    return BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showSnackBar(state.errorMessage!, isError: true);
        } else if (state.successMessage != null) {
          _showSnackBar(state.successMessage!);
        }
      },
      builder: (context, state) => PopScope(
        // No way back into the app before the password is changed.
        canPop: false,
        child: _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ChangePasswordState state) {
    final c = AuthColors.of(context);
    final busy = state.loading;

    return AuthScaffold(
      children: [
        const _Headline(),
        const SizedBox(height: 32),
        AuthPasswordField(
          controller: _currentController,
          label: 'Kata sandi lama',
          hint: 'Masukkan kata sandi lama',
          enabled: !busy,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.password],
        ),
        const SizedBox(height: 18),
        AuthPasswordField(
          controller: _newController,
          label: 'Kata sandi baru',
          hint: 'Masukkan kata sandi baru',
          enabled: !busy,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: 18),
        AuthPasswordField(
          controller: _confirmController,
          label: 'Konfirmasi kata sandi baru',
          hint: 'Ulangi kata sandi baru',
          enabled: !busy,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _onSubmit(),
        ),
        const SizedBox(height: 16),
        // Rules tick live while typing; the button waits for all of them.
        ListenableBuilder(
          listenable: _fields,
          builder: (context, _) {
            final current = _currentController.text;
            final next = _newController.text;
            final confirm = _confirmController.text;
            final rules = [
              (
                'Minimal ${ChangePasswordCubit.minLength} karakter',
                next.length >= ChangePasswordCubit.minLength,
              ),
              (
                'Berbeda dari kata sandi lama',
                next.isNotEmpty && current.isNotEmpty && next != current,
              ),
              (
                'Konfirmasi kata sandi sama',
                confirm.isNotEmpty && confirm == next,
              ),
            ];
            final allMet = rules.every((r) => r.$2);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RulesCard(rules: rules),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Simpan Kata Sandi',
                  loading: busy,
                  onPressed: busy || !allMet ? null : _onSubmit,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: c.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Setelah disimpan, Anda akan diminta masuk kembali.',
                textAlign: TextAlign.center,
                style: AuthText.small(weight: FontWeight.w500, color: c.grey),
              ),
            ),
          ],
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

    // Same headline layout as the forgot password page.
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: c.link.withValues(alpha: c.isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset_rounded, size: 34, color: c.link),
        ),
        const SizedBox(height: 24),
        Text(
          'Buat Kata Sandi Baru',
          textAlign: TextAlign.center,
          style: AuthText.title(color: c.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          'Demi keamanan akun, ganti kata sandi sementara Anda sebelum '
          'mulai bekerja.',
          textAlign: TextAlign.center,
          style: AuthText.small(weight: FontWeight.w500, color: c.grey)
              .copyWith(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

class _RulesCard extends StatelessWidget {
  final List<(String, bool)> rules;

  const _RulesCard({required this.rules});

  @override
  Widget build(BuildContext context) {
    final c = AuthColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Syarat kata sandi',
            style:
                AuthText.small(weight: FontWeight.w600, color: c.textPrimary),
          ),
          const SizedBox(height: 8),
          for (final (label, met) in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      met
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(met),
                      size: 16,
                      color: met ? AppColors.statusSelesai : c.placeholder,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: AuthText.small(
                        weight: FontWeight.w500,
                        color: met ? c.textPrimary : c.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
