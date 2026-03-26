import 'package:flai_cli/commands/add_command.dart';
import 'package:test/test.dart';

void main() {
  group('AddCommand', () {
    late AddCommand command;

    setUp(() {
      command = AddCommand();
    });

    test('has correct name', () {
      expect(command.name, equals('add'));
    });

    test('has non-empty description', () {
      expect(command.description, isNotEmpty);
    });

    test('description mentions adding a component', () {
      expect(command.description.toLowerCase(), contains('add'));
    });

    test('has custom invocation string', () {
      expect(command.invocation, equals('flai add <component>'));
    });

    group('argument parser', () {
      test('has --dry-run flag', () {
        final option = command.argParser.options['dry-run'];
        expect(option, isNotNull);
        expect(option!.isFlag, isTrue);
        expect(option.negatable, isFalse);
      });
    });
  });
}
