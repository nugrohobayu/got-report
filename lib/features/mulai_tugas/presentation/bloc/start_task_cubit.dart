import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/core/location/location_service.dart';
import 'package:got_report/features/mulai_tugas/domain/entities/task_start.dart';
import 'package:got_report/features/mulai_tugas/domain/repositories/start_task_repository.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';

/// Statuses started with `POST /api/v1/field/tasks/{id}/start`.
const startableStatuses = {TaskStatus.ditugaskan, TaskStatus.perluRevisi};

enum StartTaskStatus {
  loading,

  /// Detail failed to load (see [StartTaskState.error]).
  loadFailed,
  ready,
  locating,
  submitting,

  /// Started: the page closes.
  started,
}

class StartTaskState extends Equatable {
  final StartTaskStatus status;
  final TaskStartInfo? info;
  final LocationAccess? access;
  final DeviceLocation? location;

  /// Last error, shown as-is (load, GPS or start rejected).
  final String? error;

  const StartTaskState({
    this.status = StartTaskStatus.loading,
    this.info,
    this.access,
    this.location,
    this.error,
  });

  bool get busy =>
      status == StartTaskStatus.locating ||
      status == StartTaskStatus.submitting;

  /// `DITUGASKAN` (first start) and `PERLU_REVISI` (start the revision)
  /// can be started; other statuses get 409 TASK_INVALID_TRANSITION.
  bool get isStartable => startableStatuses.contains(info?.task.status);

  /// The last fix came from a mock location (fake GPS) app.
  bool get mockDetected => location?.mock ?? false;

  bool get canStart =>
      isStartable &&
      access == LocationAccess.granted &&
      !mockDetected &&
      !busy;

  /// Scan the location QR before starting when the template requires it,
  /// for the first start and for a revision (PERLU_REVISI) alike.
  bool get needsQr => info?.requireQr ?? false;

  StartTaskState copyWith({
    StartTaskStatus? status,
    TaskStartInfo? info,
    LocationAccess? access,
    DeviceLocation? location,
    String? error,
    bool clearError = false,
  }) {
    return StartTaskState(
      status: status ?? this.status,
      info: info ?? this.info,
      access: access ?? this.access,
      location: location ?? this.location,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, info, access, location, error];
}

/// "Mulai tugas": GPS in the location radius (+ location QR when the
/// template requires it) → `POST /api/v1/field/tasks/{id}/start`.
class StartTaskCubit extends Cubit<StartTaskState> {
  final StartTaskRepository repository;
  final LocationService locationService;
  final String taskId;
  final DateTime Function() _now;

  /// A fix older than this is read again before starting.
  static const maxFixAge = Duration(seconds: 30);

  StartTaskCubit({
    required this.repository,
    required this.locationService,
    required this.taskId,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const StartTaskState());

  Future<void> load() async {
    emit(const StartTaskState());
    try {
      final info = await repository.getStartInfo(taskId);
      if (isClosed) return;
      emit(state.copyWith(status: StartTaskStatus.ready, info: info));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
          state.copyWith(status: StartTaskStatus.loadFailed, error: f.message));
      return;
    }
    await checkAccess(locateIfGranted: true);
  }

  /// Re-reads the permission (e.g. back from the phone settings).
  Future<void> checkAccess({bool locateIfGranted = false}) async {
    final access = await locationService.access();
    if (isClosed) return;
    emit(state.copyWith(access: access));
    if (locateIfGranted && access == LocationAccess.granted) await locate();
  }

  /// Shows the OS prompt; reads the GPS when granted.
  Future<void> requestAccess() async {
    final access = await locationService.requestAccess();
    if (isClosed) return;
    emit(state.copyWith(access: access));
    if (access == LocationAccess.granted) await locate();
  }

  Future<void> openSettings() async {
    final access = state.access;
    if (access != null) await locationService.openSettings(access);
  }

  /// Reads a fresh GPS fix. Returns `false` on failure.
  Future<bool> locate() async {
    if (state.busy) return false;
    emit(state.copyWith(status: StartTaskStatus.locating, clearError: true));
    final ok = await _readFix();
    if (!isClosed) emit(state.copyWith(status: StartTaskStatus.ready));
    return ok;
  }

  /// Distance from the fix to the task location, for display only (the
  /// server decides).
  double? get distanceToLocationM {
    final fix = state.location;
    final loc = state.info?.task.location;
    if (fix == null || loc == null || !loc.hasCoordinates) return null;
    return locationService.distanceM(
      fix.latitude,
      fix.longitude,
      loc.latitude!,
      loc.longitude!,
    );
  }

  /// Sends the start evidence; reads the GPS again when the fix is stale.
  /// [qrCode] is required when `requireQr`.
  Future<void> start({String? qrCode}) async {
    if (!state.canStart) return;
    emit(state.copyWith(status: StartTaskStatus.submitting, clearError: true));
    final fix = state.location;
    if (fix == null || _now().difference(fix.readAt) > maxFixAge) {
      if (!await _readFix()) {
        if (!isClosed) emit(state.copyWith(status: StartTaskStatus.ready));
        return;
      }
    }
    final location = state.location!;
    // Never send evidence from a fake GPS app.
    if (location.mock) {
      emit(state.copyWith(
        status: StartTaskStatus.ready,
        error: mockLocationMessage,
      ));
      return;
    }
    try {
      final task = await repository.start(
        taskId,
        StartEvidence(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracyM: location.accuracyM,
          mock: location.mock,
          deviceTime: _now().toUtc(),
          qrCode: state.needsQr ? qrCode : null,
        ),
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: StartTaskStatus.started,
        info: TaskStartInfo(task: task, requireQr: state.info!.requireQr),
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(
        status: StartTaskStatus.ready,
        error: startErrorMessage(f),
      ));
    }
  }

  Future<bool> _readFix() async {
    try {
      final fix = await locationService.current();
      if (isClosed) return false;
      // Keep the fix so the card can show it, but reject a fake GPS.
      emit(state.copyWith(
        location: fix,
        error: fix.mock ? mockLocationMessage : null,
      ));
      return !fix.mock;
    } on LocationUnavailable catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(access: e.access, error: e.message));
      return false;
    }
  }
}

/// The backend message plus what to do, using `error.details`.
String startErrorMessage(Failure f) {
  if (f is! ServerFailure) return f.message;
  String? d(String key) => f.details[key]?.toString();
  switch (f.code) {
    case 'EVIDENCE_OUT_OF_RADIUS':
      final distance = d('distanceM');
      final radius = d('radiusM');
      if (distance != null && radius != null) {
        return 'Anda $distance m dari lokasi (maks $radius m). '
            'Mendekatlah ke lokasi lalu coba lagi.';
      }
      return f.message;
    case 'EVIDENCE_LOW_ACCURACY':
      final accuracy = d('accuracyM');
      final max = d('maxAccuracyM');
      final detail = accuracy != null && max != null
          ? ' Akurasi GPS $accuracy m (maks $max m).'
          : '';
      return '${f.message}.$detail Pindah ke tempat terbuka lalu coba lagi.'
          .replaceAll('..', '.');
    case 'EVIDENCE_QR_MISMATCH':
      return '${f.message}. Pindai QR yang tertempel di lokasi tugas ini.'
          .replaceAll('..', '.');
    case 'EVIDENCE_MOCK_LOCATION':
      return '${f.message}. Matikan aplikasi lokasi palsu lalu coba lagi.'
          .replaceAll('..', '.');
    default:
      return f.message;
  }
}
