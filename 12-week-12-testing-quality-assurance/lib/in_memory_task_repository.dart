import 'task_repository.dart';

class InMemoryTaskRepository implements TaskRepository {
  final List<String> _tasks = [];

  @override
  Future<List<String>> getTasks() async {
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> addTask(String title) async {
    _tasks.add(title);
  }

  @override
  Future<void> deleteTask(int index) async {
    if (index < 0 || index >= _tasks.length) {
      throw RangeError('Index di luar jangkauan');
    }
    _tasks.removeAt(index);
  }
}
