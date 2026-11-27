import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ada_tugas/core/location/location_prompt.dart';
import 'package:ada_tugas/core/location/location_service.dart';

import 'helpers/fake_location_service.dart';

void main() {
  late FakeLocationService location;

  setUp(resetLocationPrompt);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<LocationService>.value(
        value: location,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => askLocationPermissionOnStart(context),
              );
              return const Scaffold();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('not asked yet: explains, then shows the OS prompt',
      (tester) async {
    location = FakeLocationService(
      accessState: LocationAccess.needsPermission,
    );
    await open(tester);

    expect(find.text('Izinkan akses lokasi'), findsOneWidget);
    expect(find.textContaining('bukti hadir'), findsOneWidget);
    await tester.tap(find.text('Izinkan'));
    await tester.pumpAndSettle();
    expect(location.requests, 1);
  });

  testWidgets('"Nanti" does not ask the OS', (tester) async {
    location = FakeLocationService(
      accessState: LocationAccess.needsPermission,
    );
    await open(tester);
    await tester.tap(find.text('Nanti'));
    await tester.pumpAndSettle();
    expect(location.requests, 0);
  });

  testWidgets('denied permanently: offers the app settings', (tester) async {
    location = FakeLocationService(
      accessState: LocationAccess.deniedForever,
    );
    await open(tester);
    expect(find.text('Izin lokasi ditolak'), findsOneWidget);
    await tester.tap(find.text('Buka pengaturan'));
    await tester.pumpAndSettle();
    expect(location.openedSettings, [LocationAccess.deniedForever]);
  });

  testWidgets('already granted: no dialog', (tester) async {
    location = FakeLocationService();
    await open(tester);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('asked only once per app run', (tester) async {
    location = FakeLocationService(
      accessState: LocationAccess.needsPermission,
    );
    await open(tester);
    await tester.tap(find.text('Nanti'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await open(tester);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
