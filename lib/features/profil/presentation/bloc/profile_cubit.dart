import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/core/utils/load_status.dart';
import 'package:ada_tugas/features/profil/domain/entities/user_profile.dart';
import 'package:ada_tugas/features/profil/domain/repositories/profile_repository.dart';

class ProfileState extends Equatable {
  final LoadStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = LoadStatus.initial,
    this.profile,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit(this.repository) : super(const ProfileState());

  Future<void> load() async {
    emit(ProfileState(status: LoadStatus.loading, profile: state.profile));
    try {
      final profile = await repository.getMe();
      if (isClosed) return;
      emit(ProfileState(status: LoadStatus.loaded, profile: profile));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ProfileState(
        status: LoadStatus.failure,
        profile: state.profile,
        errorMessage: f.message,
      ));
    }
  }
}
