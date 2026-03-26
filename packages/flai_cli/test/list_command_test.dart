import 'package:flai_cli/commands/list_command.dart';
import 'package:test/test.dart';

void main() {
  group('ListCommand', () {
    late ListCommand command;

    setUp(() {
      command = ListCommand();
    });

    test('has correct name', () {
      expect(command.name, equals('list'));
    });

    test('has non-empty description', () {
      expect(command.description, isNotEmpty);
    });

    test('description mentions listing components', () {
      expect(command.description.toLowerCase(), contains('list'));
    });
  });
}
