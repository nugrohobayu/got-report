import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ada_tugas/core/config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    dotenv.testLoad(fileInput: 'BASE_URL=https://default.example.com');
    SharedPreferences.setMockInitialValues({});
    EnvConfig.init(await SharedPreferences.getInstance());
  });

  test('uses the .env value without an override', () {
    expect(EnvConfig.baseUrl, 'https://default.example.com');
    expect(EnvConfig.baseUrlOverride, isNull);
  });

  test('saved URL overrides .env, trimmed and without trailing slash', () async {
    await EnvConfig.setBaseUrl('  https://dev.example.com:8080/  ');
    expect(EnvConfig.baseUrl, 'https://dev.example.com:8080');
  });

  test('saving the default value or null removes the override', () async {
    await EnvConfig.setBaseUrl('https://dev.example.com');
    await EnvConfig.setBaseUrl('https://default.example.com/');
    expect(EnvConfig.baseUrlOverride, isNull);

    await EnvConfig.setBaseUrl('https://dev.example.com');
    await EnvConfig.setBaseUrl(null);
    expect(EnvConfig.baseUrl, 'https://default.example.com');
  });

  test('validateBaseUrl', () {
    expect(EnvConfig.validateBaseUrl(''), isNotNull);
    expect(EnvConfig.validateBaseUrl('api.example.com'), isNotNull);
    expect(EnvConfig.validateBaseUrl('ftp://api.example.com'), isNotNull);
    expect(EnvConfig.validateBaseUrl('http://10.0.2.2:8080'), isNull);
    expect(EnvConfig.validateBaseUrl('https://api.example.com/'), isNull);
  });
}
