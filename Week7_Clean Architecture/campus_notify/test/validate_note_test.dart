import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/add_note.dart';

class MockNoteRepository implements NoteRepository {
  MockNoteRepository({this.fail = false});

  final bool fail;
  final List<Note> storedNotes = [];
  bool addNoteCalled = false;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fail) {
      return (notes: <Note>[], failure: const LocalFailure('db error'));
    }
    return (notes: storedNotes, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addNoteCalled = true;
    if (fail) {
      return (
        note: null,
        failure: const LocalFailure('Gagal menyimpan ke database'),
      );
    }
    final note = Note(
      id: storedNotes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    storedNotes.add(note);
    return (note: note, failure: null);
  }
}

void main() {
  group('AddNote Validation Tests', () {
    late MockNoteRepository repository;
    late AddNote useCase;

    setUp(() {
      repository = MockNoteRepository();
      useCase = AddNote(repository);
    });

    test('Harus mengembalikan ValidationFailure jika judul kosong', () async {
      // Act
      final result = await useCase.call(title: '', body: 'Catatan konten');

      // Assert
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, 'Judul catatan tidak boleh kosong');
      expect(result.note, isNull);
      expect(repository.addNoteCalled, isFalse);
    });

    test('Harus mengembalikan ValidationFailure jika judul hanya berisi spasi (edge case whitespace)', () async {
      // Act
      final result = await useCase.call(title: '    ', body: 'Catatan spasi');

      // Assert
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, 'Judul catatan tidak boleh kosong');
      expect(result.note, isNull);
      expect(repository.addNoteCalled, isFalse);
    });

    test(
      'Berhasil menyimpan catatan jika judul valid dan format sudah di-trim',
      () async {
        // Act
        final result = await useCase.call(
          title: '  Catatan Baru  ',
          body: 'Deskripsi ',
        );

        // Assert
        expect(result.failure, isNull);
        expect(result.note, isNotNull);
        expect(result.note?.title, 'Catatan Baru');
        expect(result.note?.body, 'Deskripsi');
        expect(repository.addNoteCalled, isTrue);
        expect(repository.storedNotes.length, 1);
      },
    );

    test(
      'Meneruskan kegagalan jika repository mengalami error database',
      () async {
        // Arrange
        final failingRepo = MockNoteRepository(fail: true);
        final failingUseCase = AddNote(failingRepo);

        // Act
        final result = await failingUseCase.call(title: 'Judul Valid');

        // Assert
        expect(result.failure, isA<LocalFailure>());
        expect(result.note, isNull);
        expect(failingRepo.addNoteCalled, isTrue);
      },
    );
  });
}
