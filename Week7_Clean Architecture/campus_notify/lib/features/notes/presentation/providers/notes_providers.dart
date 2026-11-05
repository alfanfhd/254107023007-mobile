import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../data/repositories/note_repository_impl.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';
import '../../domain/entities/note.dart';

Future<Database> openNotesDb() async {
  return openDatabase(
    join(await getDatabasesPath(), 'notes_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, body TEXT, updated_at TEXT, dirty INTEGER)',
      );
    },
    version: 1,
  );
}

// Data layer: database opener disuntikkan (mudah diganti fake saat test)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.notes;
});

// Riverpod 3: Menggunakan Notifier class (bukan legacy StateProvider)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
  void clear() => state = '';
}

// State query string pencarian judul catatan
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// Use case pencarian judul (Domain)
final searchNotesUseCaseProvider = Provider<SearchNotes>((ref) {
  return const SearchNotes();
});

// Selector Provider: memadukan daftar catatan dengan filter pencarian
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final searchUseCase = ref.watch(searchNotesUseCaseProvider);

  return notesAsync.whenData((notes) {
    return searchUseCase(notes: notes, query: query);
  });
});
