import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ada_tugas/core/auth/session_cubit.dart';
import 'package:ada_tugas/core/auth/token_storage.dart';
import 'package:ada_tugas/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Logged-out user lands on the login page', (tester) async {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost');
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MyApp(
        sharedPreferences: sharedPreferences,
        tokenStorage: TokenStorage(),
        sessionCubit: SessionCubit(SessionStatus.unauthenticated),
      ),
    );
    await tester.pump();

    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
