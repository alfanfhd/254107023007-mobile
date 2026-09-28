import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/note_repository.dart';
import '../data/local/note.dart';
import '../data/sync.dart';
import 'settings_page.dart';

final noteRepositoryProvider = Provider((ref) => NoteRepository());

final notesProvider = FutureProvider<List<Note>>((ref) {
  return ref.watch(noteRepositoryProvider).fetchNotes();
});

final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).countDirty();
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCountAsync = ref.watch(dirtyCountProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          // Toggle Simulasi Offline
          Row(
            children: [
              const Icon(Icons.wifi_off, size: 20),
              Switch(
                value: isOffline,
                onChanged: (val) {
                  ref.read(forceOfflineProvider.notifier).toggle(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Mode Offline Aktif (Simulasi)' : 'Mode Online Aktif'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: dirtyCountAsync.when(
                data: (count) => IconButton(
                  icon: Badge(
                    label: Text(count.toString()),
                    isLabelVisible: count > 0,
                    child: const Icon(Icons.sync),
                  ),
                  onPressed: () async {
                    if (count == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Semua catatan sudah sinkron.')),
                      );
                      return;
                    }

                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Menyinkronkan catatan...')),
                      );
                      
                      final synced = await ref.read(syncServiceProvider).syncNotes(
                        ref.read(noteRepositoryProvider), 
                        isOffline,
                      );
                      
                      ref.invalidate(notesProvider);
                      ref.invalidate(dirtyCountProvider);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$synced catatan berhasil disinkronkan!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const Icon(Icons.error),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) return const Center(child: Text('Belum ada catatan.'));
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.body),
                trailing: note.dirty ? const Icon(Icons.cloud_upload_outlined, color: Colors.orange) : const Icon(Icons.check_circle, color: Colors.green),
                onLongPress: () async {
                  await ref.read(noteRepositoryProvider).deleteNote(note.id!);
                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(noteRepositoryProvider).addNote(
            title: 'Catatan Baru ${DateTime.now().second}',
            body: 'Isi catatan offline',
          );
          ref.invalidate(notesProvider);
          ref.invalidate(dirtyCountProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
