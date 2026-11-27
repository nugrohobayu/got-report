import 'package:flutter_test/flutter_test.dart';
import 'package:ada_tugas/core/push/push_notifications.dart';

void main() {
  group('taskIdFromPushRoute', () {
    test('reads the task id from /tasks/<id>', () {
      expect(
        taskIdFromPushRoute('/tasks/0193a1b2-7c4d-7e8f-9a0b-1c2d3e4f5a6b'),
        '0193a1b2-7c4d-7e8f-9a0b-1c2d3e4f5a6b',
      );
      expect(taskIdFromPushRoute('/tasks/abc/'), 'abc');
    });

    test('ignores other or missing routes', () {
      expect(taskIdFromPushRoute(null), isNull);
      expect(taskIdFromPushRoute(''), isNull);
      expect(taskIdFromPushRoute('/'), isNull);
      expect(taskIdFromPushRoute('/tasks/'), isNull);
      expect(taskIdFromPushRoute('/tasks/abc/form'), isNull);
      expect(taskIdFromPushRoute('/tasks/../login'), isNull);
    });
  });
}
