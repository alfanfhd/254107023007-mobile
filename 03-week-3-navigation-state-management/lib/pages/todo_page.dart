import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

/// TodoPage: halaman utama daftar tugas.
/// Refactored: item baris menggunakan TodoTile tersendiri.
/// Filter toggle: tampilkan semua atau hanya yang belum selesai.
class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch: subscribe ke todoListProvider — rebuild saat list berubah
    final todos = ref.watch(todoListProvider);
    // ref.watch: derived provider — hanya tugas yang belum selesai
    final pending = ref.watch(pendingTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
        actions: [
          // Badge menunjukkan jumlah tugas pending
          if (pending.isNotEmpty)
            Badge(
              label: Text('${pending.length}'),
              child: const Icon(Icons.pending_actions),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          // ListView menggunakan TodoTile — build() lebih pendek & mudah diuji
          : ListView.builder(
              itemCount: todos.length,
              // TodoTile: widget terpisah, hanya rebuild saat item-nya berubah
              itemBuilder: (context, index) => TodoTile(index: index),
            ),
      floatingActionButton: FloatingActionButton(
        // ref.read di callback — tidak berlangganan, hanya trigger dialog
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(todoListProvider.notifier)
                    .add(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
