import 'package:testing_lab/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<String>? initialTasks, this.error})
      : _tasks = initialTasks ?? [];

  final List<String> _tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> addTask(String title) async {
    if (error != null) throw error!;
    _tasks.add(title);
  }

  @override
  Future<void> deleteTask(int index) async {
    if (error != null) throw error!;
    if (index < 0 || index >= _tasks.length) {
      throw RangeError('Index di luar jangkauan');
    }
    _tasks.removeAt(index);
  }
}
