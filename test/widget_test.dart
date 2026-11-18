import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:got_report/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App shows the Posts page with a loading indicator', (
    WidgetTester tester,
  ) async {
    dotenv.testLoad(
      fileInput: 'BASE_URL=https://jsonplaceholder.typicode.com',
    );
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(MyApp(sharedPreferences: sharedPreferences));

    expect(find.text('Posts'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Dio schedules its request pipeline via an internal zero-duration
    // Timer; flush it so it doesn't trip the "pending timer" test
    // invariant once this callback returns.
    await tester.pump(Duration.zero);
  });
}
