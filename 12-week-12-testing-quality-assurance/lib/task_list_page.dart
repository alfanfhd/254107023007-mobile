import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'task_service.dart';
import 'is_valid_task_title.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key, required this.repository});

  final TaskRepository repository;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late final TaskService _service;
  List<String> _tasks = [];
  bool _isLoading = true;
  String? _error;
  final _controller = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _service = TaskService(widget.repository);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tasks = await _service.loadTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final title = _controller.text;
    if (!isValidTaskTitle(title)) {
      setState(() {
        _validationError = 'Judul tugas tidak boleh kosong';
      });
      return;
    }
    setState(() {
      _validationError = null;
    });
    try {
      await _service.addTask(title);
      _controller.clear();
      await _loadTasks();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteTask(int index) async {
    try {
      await _service.deleteTask(index);
      await _loadTasks();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('task-title-field'),
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Masukkan judul tugas',
                      errorText: _validationError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('save-task-button'),
                  onPressed: _addTask,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _error!,
                key: const Key('error-message'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    key: Key('loading-indicator'),
                    child: CircularProgressIndicator(),
                  )
                : _tasks.isEmpty
                    ? const Center(
                        key: Key('empty-message'),
                        child: Text('Belum ada tugas'),
                      )
                    : ListView.builder(
                        key: const Key('task-list'),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_tasks[index]),
                            trailing: IconButton(
                              key: Key('delete-task-$index'),
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteTask(index),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
