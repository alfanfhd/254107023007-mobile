import 'package:flutter_test/flutter_test.dart';
import 'package:testing_lab/is_valid_task_title.dart';

void main() {
  group('isValidTaskTitle', () {
    test('menerima judul yang berisi teks', () {
      expect(isValidTaskTitle('Belajar Flutter'), isTrue);
    });

    test('menerima judul dengan spasi di awal dan akhir', () {
      expect(isValidTaskTitle('  Belajar  '), isTrue);
    });

    test('menolak string kosong', () {
      expect(isValidTaskTitle(''), isFalse);
    });

    test('menolak string yang hanya berisi spasi', () {
      expect(isValidTaskTitle('   '), isFalse);
    });

    test('menerima judul satu karakter', () {
      expect(isValidTaskTitle('A'), isTrue);
    });
  });
}
