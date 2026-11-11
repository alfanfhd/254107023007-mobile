import 'task_repository.dart';
import 'is_valid_task_title.dart';

class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  Future<void> addTask(String title) async {
    if (!isValidTaskTitle(title)) {
      throw ArgumentError('Judul tugas tidak boleh kosong');
    }
    await _repository.addTask(title.trim());
  }

  Future<void> deleteTask(int index) {
    return _repository.deleteTask(index);
  }
}
