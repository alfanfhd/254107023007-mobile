import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import 'settings_page.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = FutureProvider<List<Note>>((ref) {
  return ref.watch(noteRepositoryProvider).fetchNotes();
});

final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).countDirty();
});

// ── Notes Page ─────────────────────────────────────────────────────────────────

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Catatan Offline',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            // Badge jumlah catatan dirty (belum tersinkron)
            dirtyAsync.when(
              data: (count) => count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count belum sync',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          // Tombol sync
          dirtyAsync.when(
            data: (count) => count > 0
                ? IconButton(
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: 'Sinkronisasi ($count catatan)',
                    onPressed: () async {
                      final repo = ref.read(noteRepositoryProvider);
                      await syncNotes(repo);
                      ref.invalidate(notesProvider);
                      ref.invalidate(dirtyCountProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$count catatan berhasil disinkron!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Gagal memuat catatan:\n$e', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (notes) => notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add_outlined,
                        size: 72, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada catatan.\nKetuk + untuk menambah!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: notes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => NoteTile(
                  note: notes[i],
                  onDelete: () async {
                    if (notes[i].id != null) {
                      await ref
                          .read(noteRepositoryProvider)
                          .deleteNote(notes[i].id!);
                      ref.invalidate(notesProvider);
                      ref.invalidate(dirtyCountProvider);
                    }
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catatan Baru'),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Isi catatan',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ref.read(noteRepositoryProvider).addNote(
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                  );
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ── Note Tile ──────────────────────────────────────────────────────────────────

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const NoteTile({super.key, required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Badge "belum tersinkron" jika dirty == true
                      if (note.dirty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'belum sync',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (note.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    note.updatedAt.toString().substring(0, 16),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: colorScheme.error, size: 20),
              onPressed: onDelete,
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
