import '../entities/note.dart';

/// Use case murni (Domain Layer) untuk melakukan filter pencarian judul catatan.
/// Bebas dari dependensi framework Flutter, Dio, maupun SQLite.
class SearchNotes {
  const SearchNotes();

  /// Menyaring daftar [notes] berdasarkan [query] judul secara case-insensitive.
  List<Note> call({required List<Note> notes, required String query}) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      return note.title.toLowerCase().contains(trimmedQuery);
    }).toList();
  }
}
