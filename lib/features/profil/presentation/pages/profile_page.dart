import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/constants/app_constants.dart';
import 'package:got_report/core/theme/app_colors.dart';
import 'package:got_report/core/theme/theme_cubit.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/core/widgets/error_view.dart';
import 'package:got_report/features/login/presentation/widgets/logout_dialog.dart';
import 'package:got_report/features/profil/domain/entities/user_profile.dart';
import 'package:got_report/features/profil/presentation/bloc/profile_cubit.dart';

/// Profil tab: profile header card, settings, app info and logout.
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (profile != null)
                _ProfileHeader(profile: profile)
              else if (state.status == LoadStatus.failure)
                ErrorView(
                  message: state.errorMessage ?? 'Gagal memuat profil.',
                  onRetry: cubit.load,
                )
              else
                const _HeaderPlaceholder(),
              const SizedBox(height: 24),
              const _SectionLabel('Pengaturan'),
              const _SettingsCard(),
              const SizedBox(height: 20),
              const _SectionLabel('Tentang aplikasi'),
              const _AboutCard(),
              const SizedBox(height: 28),
              const _LogoutButton(),
            ],
          ),
        );
      },
    );
  }
}

/// Navy card: initials, name, email and role badges.
class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFFC9D6E8);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.blue,
            child: Text(
              profile.initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName.isEmpty ? '-' : profile.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
                if (profile.roleNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final role in profile.roleNames) _RoleBadge(role),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.badge_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            role,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state with the same footprint as [_ProfileHeader].
class _HeaderPlaceholder extends StatelessWidget {
  const _HeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 114,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Bordered surface card used for the grouped rows.
class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }
}

/// Leading icon in a tinted rounded square.
class _RowIcon extends StatelessWidget {
  final IconData icon;

  const _RowIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GroupCard(
      children: [
        SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: const _RowIcon(Icons.dark_mode_outlined),
          title: const Text(
            'Mode gelap',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          value: isDark,
          onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _GroupCard(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          minTileHeight: 60,
          leading: const _RowIcon(Icons.info_outline),
          title: const Text(
            'Versi aplikasi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          trailing: Text(
            AppConstants.appVersion,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      onPressed: () => confirmAndLogout(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        iconColor: error,
        side: BorderSide(color: error.withValues(alpha: 0.6)),
        minimumSize: const Size.fromHeight(52),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Keluar'),
    );
  }
}
