import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ada_tugas/core/error/failures.dart';
import 'package:ada_tugas/core/location/location_service.dart';
import 'package:ada_tugas/features/mulai_tugas/domain/entities/task_start.dart';
import 'package:ada_tugas/features/mulai_tugas/domain/repositories/start_task_repository.dart';
import 'package:ada_tugas/features/mulai_tugas/presentation/start_revision.dart';
import 'package:ada_tugas/features/tugas_hari_ini/domain/entities/task_summary.dart';

import 'helpers/fake_location_service.dart';

class _Repo implements StartTaskRepository {
  bool requireQr = true;
  StartEvidence? sent;
  Failure? error;

  @override
  Future<TaskStartInfo> getStartInfo(String taskId) async => TaskStartInfo(
        task: TaskSummary(
          id: taskId,
          title: 't',
          status: TaskStatus.perluRevisi,
        ),
        requireQr: requireQr,
      );

  @override
  Future<TaskSummary> start(String taskId, StartEvidence evidence) async {
    sent = evidence;
    final e = error;
    if (e != null) throw e;
    return TaskSummary(id: taskId, title: 't', status: TaskStatus.dikerjakan);
  }
}

void main() {
  late _Repo repo;
  late FakeLocationService location;
  late int started;
  late int scans;
  late String? scanResult;
  late List<String> visited;

  setUp(() {
    repo = _Repo();
    location = FakeLocationService();
    started = 0;
    scans = 0;
    scanResult = 'GRL-7Pg0PLxjtQArreow';
    visited = [];
  });

  Future<void> tapStart(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => startRevision(
                context,
                'task-1',
                onStarted: () => started++,
                scanQr: (_) async {
                  scans++;
                  return scanResult;
                },
              ),
              child: const Text('Mulai revisi'),
            ),
          ),
        ),
        GoRoute(
          path: '/tasks/:id/start',
          name: 'startTask',
          builder: (_, state) {
            visited.add(state.uri.path);
            return const Scaffold(body: Text('Halaman mulai'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<StartTaskRepository>.value(value: repo),
          RepositoryProvider<LocationService>.value(value: location),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Mulai revisi'));
    await tester.pumpAndSettle();
  }

  testWidgets('QR template: scans the QR, starts, opens the form',
      (tester) async {
    await tapStart(tester);
    expect(scans, 1);
    expect(repo.sent!.qrCode, 'GRL-7Pg0PLxjtQArreow');
    expect(started, 1);
    expect(visited, isEmpty); // no start screen
  });

  testWidgets('template without QR: starts with GPS only', (tester) async {
    repo.requireQr = false;
    await tapStart(tester);
    expect(scans, 0);
    expect(repo.sent!.qrCode, isNull);
    expect(started, 1);
  });

  testWidgets('scanner closed: nothing is sent', (tester) async {
    scanResult = null;
    await tapStart(tester);
    expect(repo.sent, isNull);
    expect(started, 0);
  });

  testWidgets('rejected: shows the reason and stays', (tester) async {
    repo.error = const ServerFailure(
      'QR lokasi tidak cocok',
      code: 'EVIDENCE_QR_MISMATCH',
    );
    await tapStart(tester);
    expect(find.text('Revisi belum bisa dimulai'), findsOneWidget);
    expect(find.textContaining('QR lokasi tidak cocok'), findsOneWidget);
    expect(started, 0);
  });

  testWidgets('location blocked: falls back to the start screen',
      (tester) async {
    location.accessState = LocationAccess.deniedForever;
    await tapStart(tester);
    expect(repo.sent, isNull);
    expect(visited, ['/tasks/task-1/start']);
  });
}
