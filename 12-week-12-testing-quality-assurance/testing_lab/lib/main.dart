import 'package:flutter/material.dart';
import 'in_memory_task_repository.dart';
import 'task_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing Lab',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: TaskListPage(repository: InMemoryTaskRepository()),
    );
  }
}
