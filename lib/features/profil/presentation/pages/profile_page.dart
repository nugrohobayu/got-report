import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/theme/theme_cubit.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/login/presentation/widgets/logout_dialog.dart';
import 'package:got_report/features/profil/domain/entities/user_profile.dart';
import 'package:got_report/features/profil/presentation/bloc/profile_cubit.dart';

/// Profil tab: who is logged in, dark mode switch, and logout.
///
/// Reads the [ProfileCubit] provided (and loaded) by HomePage, which also
/// uses it for the Beranda greeting.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final cubit = context.read<ProfileCubit>();
        final profile = state.profile;
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              if (profile != null)
                _ProfileHeader(profile: profile)
              else if (state.status == LoadStatus.failure)
                ErrorView(
                  message: state.errorMessage ?? 'Gagal memuat profil.',
                  onRetry: cubit.load,
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 24),
              const _SettingsCard(),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: scheme.primary,
          child: Text(
            profile.initials,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.fullName.isEmpty ? '-' : profile.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        if (profile.roleNames.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final role in profile.roleNames)
                Chip(
                  label: Text(role),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode gelap'),
            value: isDark,
            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
          ),
          Divider(height: 1, color: scheme.outline),
          ListTile(
            minTileHeight: 56,
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text(
              'Keluar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: scheme.error,
              ),
            ),
            onTap: () => confirmAndLogout(context),
          ),
        ],
      ),
    );
  }
}
