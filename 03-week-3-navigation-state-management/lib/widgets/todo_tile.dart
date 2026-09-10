import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

/// TodoTile: widget terpisah untuk setiap baris item ToDo.
/// Dipisahkan dari TodoPage agar build() lebih pendek dan mudah diuji secara unit.
class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.index});

  /// Index item di dalam todoListProvider
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: hanya rebuild saat item di index ini berubah, bukan seluruh list
    final todo = ref.watch(
      todoListProvider.select((list) => index < list.length ? list[index] : null),
    );

    if (todo == null) return const SizedBox.shrink();

    return ListTile(
      leading: Checkbox(
        value: todo.done,
        // ref.read di callback: tidak berlangganan, hanya memanggil method
        onChanged: (_) => ref.read(todoListProvider.notifier).toggle(index),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => ref.read(todoListProvider.notifier).remove(index),
      ),
    );
  }
}
