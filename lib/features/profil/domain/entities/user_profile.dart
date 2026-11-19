import 'package:equatable/equatable.dart';

/// The logged-in staff member (`data` of `GET /api/v1/me`).
class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;

  /// Role display names, e.g. `Petugas`. Labels only; never gate on them.
  final List<String> roleNames;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.roleNames = const [],
  });

  /// Up to two initials for the avatar, e.g. `Teknisi A` → `TA`.
  String get initials {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  List<Object?> get props => [id, fullName, email, roleNames];
}
