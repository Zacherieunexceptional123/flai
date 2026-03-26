import 'package:flai_cli/commands/doctor_command.dart';
import 'package:test/test.dart';

void main() {
  group('DoctorCommand', () {
    late DoctorCommand command;

    setUp(() {
      command = DoctorCommand();
    });

    test('has correct name', () {
      expect(command.name, equals('doctor'));
    });

    test('has non-empty description', () {
      expect(command.description, isNotEmpty);
    });

    test('description mentions checking project health', () {
      expect(command.description.toLowerCase(), contains('check'));
    });
  });
}
