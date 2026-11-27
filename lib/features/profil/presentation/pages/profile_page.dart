import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/constants/app_constants.dart';
import 'package:ada_tugas/core/push/push_service.dart';
import 'package:ada_tugas/core/theme/app_colors.dart';
import 'package:ada_tugas/core/theme/theme_cubit.dart';
import 'package:ada_tugas/core/utils/load_status.dart';
import 'package:ada_tugas/core/widgets/error_view.dart';
import 'package:ada_tugas/features/login/presentation/widgets/logout_dialog.dart';
import 'package:ada_tugas/features/profil/domain/entities/user_profile.dart';
import 'package:ada_tugas/features/profil/presentation/bloc/profile_cubit.dart';
import 'package:ada_tugas/features/profil/presentation/widgets/env_config_dialog.dart';

/// Profil tab: profile header card, settings (notifications, dark mode),
/// app info and logout.
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
        const _NotificationTile(),
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

/// Notifikasi switch. Hidden when push is not available on this device.
///
/// Off → the device is removed on the server and no longer registered.
/// Blocked in the phone settings → switch is off and tapping it opens the
/// app's notification settings; the status is re-read when the user comes
/// back to the app.
class _NotificationTile extends StatefulWidget {
  const _NotificationTile();

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile>
    with WidgetsBindingObserver {
  PushStatus? _status;
  bool _busy = false;

  PushService get _push => context.read<PushService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone settings: the permission may have changed.
    if (state == AppLifecycleState.resumed) _refresh(registerIfAllowed: true);
  }

  Future<void> _refresh({bool registerIfAllowed = false}) async {
    final before = _status;
    final status = await _push.status();
    if (!mounted) return;
    setState(() => _status = status);
    // Unblocked in the phone settings while on in the app: register now.
    if (registerIfAllowed &&
        before == PushStatus.blocked &&
        status == PushStatus.on) {
      await _push.registerDevice();
    }
  }

  Future<void> _onChanged(bool value) async {
    if (_status == PushStatus.blocked) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      return;
    }
    setState(() => _busy = true);
    final status = await _push.setEnabled(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = status;
    });
    if (status == PushStatus.blocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi ditolak. Aktifkan di pengaturan HP.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null || status == PushStatus.unavailable) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final blocked = status == PushStatus.blocked;
    final subtitle = switch (status) {
      PushStatus.on => 'Tugas baru, revisi, dan tugas terlambat',
      PushStatus.off => 'Notifikasi dimatikan',
      _ => 'Diblokir di pengaturan HP. Ketuk untuk membuka pengaturan.',
    };

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const _RowIcon(Icons.notifications_outlined),
          title: const Text(
            'Notifikasi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: blocked ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
          onTap: _busy ? null : () => _onChanged(status != PushStatus.on),
          trailing: _busy
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Switch(
                  value: status == PushStatus.on,
                  onChanged: _onChanged,
                ),
        ),
        Divider(height: 1, color: scheme.outline),
      ],
    );
  }
}

/// Tapping "Versi aplikasi" 3× in a row opens the hidden env form.
class _AboutCard extends StatefulWidget {
  const _AboutCard();

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  static const _tapsToOpen = 3;
  static const _maxTapGap = Duration(milliseconds: 600);

  int _taps = 0;
  DateTime _lastTap = DateTime(0);

  void _onVersionTap() {
    final now = DateTime.now();
    _taps = now.difference(_lastTap) <= _maxTapGap ? _taps + 1 : 1;
    _lastTap = now;
    if (_taps < _tapsToOpen) return;
    _taps = 0;
    showEnvConfigDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _GroupCard(
      children: [
        ListTile(
          onTap: _onVersionTap,
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
