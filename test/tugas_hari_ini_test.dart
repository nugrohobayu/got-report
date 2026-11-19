import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/core/error/exceptions.dart';
import 'package:got_report/core/error/failures.dart';
import 'package:got_report/core/utils/load_status.dart';
import 'package:got_report/features/home/presentation/pages/home_page.dart';
import 'package:got_report/features/kalender_tugas/presentation/bloc/task_calendar_cubit.dart';
import 'package:got_report/features/login/domain/repositories/auth_repository.dart';
import 'package:got_report/features/tugas_hari_ini/data/models/task_summary_model.dart';
import 'package:got_report/features/tugas_hari_ini/domain/entities/task_summary.dart';
import 'package:got_report/features/tugas_hari_ini/domain/repositories/task_repository.dart';
import 'package:got_report/features/tugas_hari_ini/presentation/bloc/today_tasks_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Item copied from the "Contoh response" of GET /api/v1/field/tasks.
const _apiItem = {
  'id': '01a1ed87-f2b4-74a3-885e-627da3b5bf58',
  'title': 'Instalasi mesin antrean cabang Asia Afrika',
  'mode': 'TEAM',
  'status': 'DITUGASKAN',
  'overdue': false,
  'myRole': 'LEADER',
  'location': {
    'id': '01a1ed87-ea30-7a50-8212-9e1a102a3283',
    'name': 'Bank X Bandung 598c61',
    'address': 'Jl. Asia Afrika No. 1, Bandung',
    'latitude': -6.914744,
    'longitude': 107.60981,
    'radiusM': 150,
    'hasQr': true,
    'archived': false,
  },
  'template': {
    'templateId': '01a1ed87-f03e-75cf-8cad-a800a690302d',
    'templateVersionId': '01a1ed87-f0c1-76a2-865d-4f95972549a5',
    'name': 'Instalasi mesin antrean 598c61',
    'version': 1,
    'requireQr': null,
    'requireSignature': null,
    'schema': null,
  },
  'team': null,
  'dueAt': '2026-11-18T12:21:12Z',
  'startedAt': null,
  'revisionCount': 0,
  'lastRevisionNote': null,
};

TaskSummary _task(String id, String status, DateTime? due,
        {bool overdue = false}) =>
    TaskSummary(
      id: id,
      title: 'Tugas $id',
      status: status,
      dueAt: due,
      overdue: overdue,
      location: const TaskLocation(id: 'l1', name: 'Lokasi A'),
    );

class _FakeTaskRepository implements TaskRepository {
  List<TaskSummary> tasks;
  Failure? failure;
  final calls = <(DateTime, DateTime)>[];

  _FakeTaskRepository([this.tasks = const []]);

  @override
  Future<List<TaskSummary>> getMyTasks({
    required DateTime from,
    required DateTime to,
  }) async {
    calls.add((from, to));
    if (failure != null) throw failure!;
    return tasks;
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('TaskSummaryModel', () {
    test('parses the API example and converts dueAt to local time', () {
      final t = TaskSummaryModel.fromJson(_apiItem);
      expect(t.title, 'Instalasi mesin antrean cabang Asia Afrika');
      expect(t.status, TaskStatus.ditugaskan);
      expect(t.myRole, 'LEADER');
      expect(t.location!.name, 'Bank X Bandung 598c61');
      expect(t.location!.latitude, -6.914744);
      expect(t.templateName, 'Instalasi mesin antrean 598c61');
      expect(t.dueAt, DateTime.utc(2026, 11, 18, 12, 21, 12).toLocal());
      expect(t.dueAt!.isUtc, isFalse);
    });

    test('rejects a non-list body', () {
      expect(
        () => TaskSummaryModel.listFromJson({'id': 'x'}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('nearestTask', () {
    test('picks the unfinished task with the earliest deadline', () {
      final tasks = [
        _task('done', TaskStatus.selesai, DateTime(2026, 11, 18, 8)),
        _task('later', TaskStatus.ditugaskan, DateTime(2026, 11, 18, 15)),
        _task('soon', TaskStatus.dikerjakan, DateTime(2026, 11, 18, 10)),
        _task('nodue', TaskStatus.ditugaskan, null),
      ];
      expect(nearestTask(tasks)!.id, 'soon');
    });

    test('is null when every task is done', () {
      expect(
        nearestTask([_task('a', TaskStatus.selesai, DateTime(2026))]),
        isNull,
      );
    });
  });

  group('TodayTasksCubit', () {
    test('asks for the local day [00:00, next 00:00)', () async {
      final repo = _FakeTaskRepository();
      final cubit = TodayTasksCubit(
        repo,
        now: () => DateTime(2026, 11, 18, 9, 30),
      );
      await cubit.load();
      expect(
          repo.calls.single, (DateTime(2026, 11, 18), DateTime(2026, 11, 19)));
      expect(cubit.state.status, LoadStatus.loaded);
      await cubit.close();
    });

    test('keeps old tasks and shows the backend message on failure', () async {
      final repo = _FakeTaskRepository([
        _task('a', TaskStatus.ditugaskan, DateTime(2026, 11, 18, 10)),
      ]);
      final cubit = TodayTasksCubit(repo);
      await cubit.load();
      repo.failure = const ServerFailure('Sesi berakhir', code: 'UNAUTHORIZED');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, 'Sesi berakhir');
      expect(cubit.state.tasks, hasLength(1));
      await cubit.close();
    });
  });

  group('TaskCalendarCubit', () {
    test('loads the whole month and groups tasks by day', () async {
      final repo = _FakeTaskRepository([
        _task('a', TaskStatus.ditugaskan, DateTime(2026, 11, 18, 10)),
        _task('b', TaskStatus.selesai, DateTime(2026, 11, 18, 14)),
        _task('c', TaskStatus.ditugaskan, DateTime(2026, 11, 20, 9)),
      ]);
      final cubit = TaskCalendarCubit(repo, today: DateTime(2026, 11, 18, 9));
      await cubit.load();

      expect(repo.calls.single, (DateTime(2026, 11), DateTime(2026, 12)));
      expect(cubit.state.selectedTasks.map((t) => t.id), ['a', 'b']);
      expect(cubit.state.tasksOn(DateTime(2026, 11, 20, 23)), hasLength(1));
      expect(cubit.state.tasksOn(DateTime(2026, 11, 19)), isEmpty);
      await cubit.close();
    });

    test('changing month loads that month', () async {
      final repo = _FakeTaskRepository();
      final cubit = TaskCalendarCubit(repo, today: DateTime(2026, 11, 18));
      await cubit.load();
      cubit.changeMonth(DateTime(2026, 12, 1));
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls.last, (DateTime(2026, 12), DateTime(2027, 1)));
      expect(cubit.state.focusedMonth, DateTime(2026, 12));
      await cubit.close();
    });
  });

  testWidgets('home shows the nearest task and the other tasks of today',
      (tester) async {
    // Tall phone screen so the whole (lazy) list is built.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final repo = _FakeTaskRepository([
      _task('A', TaskStatus.selesai, today.add(const Duration(hours: 8))),
      _task('B', TaskStatus.ditugaskan, today.add(const Duration(hours: 10))),
      _task('C', TaskStatus.ditugaskan, today.add(const Duration(hours: 15))),
    ]);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TaskRepository>.value(value: repo),
          RepositoryProvider<AuthRepository>.value(
            value: _NoopAuthRepository(),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 dari 3 tugas selesai'), findsOneWidget);
    expect(find.text('Tugas terdekat'), findsOneWidget);
    expect(find.text('Navigasi'), findsOneWidget);
    expect(find.text('Kalender tugas'), findsOneWidget);
    // B is the nearest (highlighted), A and C are listed below it.
    for (final id in ['A', 'B', 'C']) {
      expect(find.text('Tugas $id'), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.text('Tugas B')).dy,
      lessThan(tester.getTopLeft(find.text('Tugas A')).dy),
    );
  });
}
