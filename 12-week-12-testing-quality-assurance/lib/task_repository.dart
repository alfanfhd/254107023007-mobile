abstract interface class TaskRepository {
  Future<List<String>> getTasks();
  Future<void> addTask(String title);
  Future<void> deleteTask(int index);
}
