import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notes_providers.dart';
import '../../domain/entities/note.dart';

/// Halaman catatan.
///
/// Optimasi:
/// - halaman tidak lagi `watch` seluruh query; hanya search field yang
///   memakai `select((q) => q.isNotEmpty)`;
/// - setiap baris diekstrak menjadi [_NoteTile] agar bisa di-reuse oleh
///   `ListView.builder`;
/// - controller dialog di-dispose setelah dialog selesai (mencegah leak).
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).updateQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Kampus')),
      body: Column(
        children: [
          _NotesSearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _NotesErrorState(error: err),
              data: (notes) {
                if (notes.isEmpty) {
                  return _NotesEmptyState(onClear: _clearSearch);
                }
                return _NotesList(notes: notes);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
      ),
    );
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _AddNoteDialog(),
    );
    if (added != true) return;

    ref.invalidate(notesProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil ditambahkan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Dialog milik sendiri agar controller mengikuti siklus hidup route dialog.
/// Dispose setelah `showDialog` selesai terlalu dini: TextField masih bisa
/// dibangun ulang saat animasi pop berjalan.
class _AddNoteDialog extends ConsumerStatefulWidget {
  const _AddNoteDialog();

  @override
  ConsumerState<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends ConsumerState<_AddNoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _errorMessage;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final result = await ref.read(addNoteProvider)(
      title: _titleController.text,
      body: _bodyController.text,
    );

    if (!mounted) return;

    if (result.failure != null) {
      setState(() {
        _saving = false;
        _errorMessage = result.failure!.message;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan Baru'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('note_title_field'),
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Catatan *',
                hintText: 'Masukkan judul catatan',
                errorText: _errorMessage,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('note_body_field'),
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                hintText: 'Masukkan isi/deskripsi',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('save_note_button'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}

class _NotesSearchField extends ConsumerWidget {
  const _NotesSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: hanya rebuild saat status "ada teks" berubah, bukan setiap huruf.
    final hasQuery = ref.watch(
      searchQueryProvider.select((query) => query.isNotEmpty),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        key: const Key('notes_search_field'),
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: hasQuery
              ? IconButton(
                  key: const Key('clear_search_button'),
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

class _NotesEmptyState extends ConsumerWidget {
  const _NotesEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);

    if (query.isNotEmpty) {
      return _buildEmptySearchResult(context, query);
    }
    return const Center(
      key: Key('initial_empty_state'),
      child: Text('Belum ada catatan. Tekan Catatan Baru untuk menambah.'),
    );
  }

  Widget _buildEmptySearchResult(BuildContext context, String query) {
    return Center(
      key: const Key('empty_search_state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Catatan Tidak Ditemukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada catatan yang cocok dengan kata kunci "$query".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('reset_search_button'),
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Pencarian'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesErrorState extends ConsumerWidget {
  const _NotesErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(notesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('notes_list'),
      itemCount: notes.length,
      padding: const EdgeInsets.only(bottom: 80),
      // Lazy: hanya item yang terlihat yang di-build.
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index) {
        return _NoteTile(note: notes[index], index: index);
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.index});

  final Note note;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(note.body.isEmpty ? '(Tanpa isi)' : note.body),
        trailing: Text(
          '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
