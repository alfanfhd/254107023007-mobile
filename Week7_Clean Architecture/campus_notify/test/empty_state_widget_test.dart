import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';

void main() {
  testWidgets(
    'Menampilkan Empty State yang tepat saat pencarian tidak menemukan hasil',
    (WidgetTester tester) async {
      final sampleNotes = [
        Note(
          id: 1,
          title: 'Tugas Kuliah Mobile',
          body: 'Mengerjakan Clean Architecture',
          updatedAt: DateTime(2026, 11, 1),
        ),
      ];

      // Build widget dengan ProviderScope dan override notesProvider
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notesProvider.overrideWith((ref) async => sampleNotes)],
          child: const MaterialApp(home: NotesPage()),
        ),
      );

      // Tunggu future provider selesai me-render
      await tester.pumpAndSettle();

      // Pastikan catatan awal muncul di layar
      expect(find.text('Tugas Kuliah Mobile'), findsOneWidget);
      expect(find.byKey(const Key('empty_search_state')), findsNothing);

      // Masukkan query pencarian yang tidak cocok
      await tester.enterText(
        find.byKey(const Key('notes_search_field')),
        'zzz-tak-ada',
      );
      await tester.pumpAndSettle();

      // Verifikasi: Empty state pencarian muncul dengan teks informatif
      expect(find.byKey(const Key('empty_search_state')), findsOneWidget);
      expect(find.text('Catatan Tidak Ditemukan'), findsOneWidget);
      expect(
        find.text(
          'Tidak ada catatan yang cocok dengan kata kunci "zzz-tak-ada".',
        ),
        findsOneWidget,
      );
      expect(find.text('Tugas Kuliah Mobile'), findsNothing);

      // Tekan tombol Reset Pencarian
      await tester.tap(find.byKey(const Key('reset_search_button')));
      await tester.pumpAndSettle();

      // Verifikasi: Catatan kembali muncul dan empty state menghilang
      expect(find.text('Tugas Kuliah Mobile'), findsOneWidget);
      expect(find.byKey(const Key('empty_search_state')), findsNothing);
    },
  );
}
