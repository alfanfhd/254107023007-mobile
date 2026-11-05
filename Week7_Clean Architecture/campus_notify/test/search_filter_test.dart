import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/usecases/search_notes.dart';

void main() {
  group('SearchNotes UseCase Tests', () {
    const searchNotes = SearchNotes();

    final sampleNotes = [
      Note(
        id: 1,
        title: 'Belanja Bulanan',
        body: 'Beli susu, roti, dan telur',
        updatedAt: DateTime(2026, 11, 1),
      ),
      Note(
        id: 2,
        title: 'Tugas Kuliah Mobile',
        body: 'Mengerjakan Clean Architecture & Riverpod',
        updatedAt: DateTime(2026, 11, 2),
      ),
      Note(
        id: 3,
        title: 'Daftar Belanja Kampus',
        body: 'Beli buku tulis dan binder',
        updatedAt: DateTime(2026, 11, 3),
      ),
      Note(
        id: 4,
        title: 'Rapat Organisasi HMTI',
        body: 'Persiapan acara workshop mobile development',
        updatedAt: DateTime(2026, 11, 4),
      ),
    ];

    test('filter abaikan huruf besar/kecil (case-insensitive search)', () {
      // Act: mencari kata 'belanja' dengan huruf kecil
      final results = searchNotes(notes: sampleNotes, query: 'belanja');

      // Assert: harus mencocokkan 'Belanja Bulanan' dan 'Daftar Belanja Kampus'
      expect(results.length, 2);
      expect(results.any((n) => n.id == 1), isTrue);
      expect(results.any((n) => n.id == 3), isTrue);
    });

    test('query tak cocok kembalikan kosong', () {
      // Act: mencari string acak yang tidak ada di judul
      final results = searchNotes(notes: sampleNotes, query: 'zzz-tak-ada');

      // Assert
      expect(results, isEmpty);
    });

    test(
      'query kosong atau hanya spasi mengembalikan seluruh daftar catatan',
      () {
        // Act
        final emptyQueryResults = searchNotes(notes: sampleNotes, query: '');
        final whitespaceQueryResults = searchNotes(
          notes: sampleNotes,
          query: '   ',
        );

        // Assert
        expect(emptyQueryResults.length, sampleNotes.length);
        expect(whitespaceQueryResults.length, sampleNotes.length);
      },
    );

    test('pencarian substring berhasil mencocokkan bagian judul', () {
      // Act
      final results = searchNotes(notes: sampleNotes, query: 'Kuliah');

      // Assert
      expect(results.length, 1);
      expect(results.first.title, 'Tugas Kuliah Mobile');
    });
  });
}
