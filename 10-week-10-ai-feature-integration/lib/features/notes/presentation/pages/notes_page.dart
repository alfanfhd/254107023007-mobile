import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notes_providers.dart';
import '../../domain/entities/note.dart';

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
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Kampus')),
      body: Column(
        children: [
          _buildSearchBar(context, query),
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _buildErrorState(err),
              data: (notes) {
                if (notes.isEmpty) {
                  return query.isNotEmpty
                      ? _buildEmptySearchResult(query)
                      : _buildInitialEmptyState();
                }
                return _buildNotesList(notes);
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

  Widget _buildSearchBar(BuildContext context, String currentQuery) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        key: const Key('notes_search_field'),
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: currentQuery.isNotEmpty
              ? IconButton(
                  key: const Key('clear_search_button'),
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
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

  Widget _buildEmptySearchResult(String query) {
    return Center(
      key: const Key('empty_search_state'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Pencarian'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialEmptyState() {
    return const Center(
      key: Key('initial_empty_state'),
      child: Text('Belum ada catatan. Tekan Catatan Baru untuk menambah.'),
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $err'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(notesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    return ListView.builder(
      itemCount: notes.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final note = notes[index];
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
      },
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Catatan Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Catatan *',
                        hintText: 'Masukkan judul catatan',
                        errorText: errorMessage,
                        border: const OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final addNote = ref.read(addNoteProvider);
                    final result = await addNote(
                      title: titleController.text,
                      body: bodyController.text,
                    );

                    if (result.failure != null) {
                      setState(() {
                        errorMessage = result.failure!.message;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.failure!.message),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }

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
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
