import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_lab/task_list_page.dart';
import 'fake_task_repository.dart';

void main() {
  group('TaskListPage', () {
    testWidgets('menampilkan judul halaman', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(repository: FakeTaskRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daftar Tugas'), findsOneWidget);
    });

    testWidgets('menampilkan pesan kosong saat tidak ada tugas',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(repository: FakeTaskRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-message')), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsOneWidget);
    });

    testWidgets('menampilkan daftar tugas yang sudah ada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(
            repository:
                FakeTaskRepository(initialTasks: ['Tugas 1', 'Tugas 2']),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tugas 1'), findsOneWidget);
      expect(find.text('Tugas 2'), findsOneWidget);
    });

    testWidgets('menambahkan tugas baru saat tombol simpan ditekan',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(repository: FakeTaskRepository()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      expect(find.text('Baca materi'), findsOneWidget);
    });

    testWidgets('menampilkan error validasi saat judul kosong',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(repository: FakeTaskRepository()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      expect(find.text('Judul tugas tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('menghapus tugas saat tombol delete ditekan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(
            repository: FakeTaskRepository(initialTasks: ['Hapus saya']),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hapus saya'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete-task-0')));
      await tester.pumpAndSettle();

      expect(find.text('Hapus saya'), findsNothing);
      expect(find.text('Belum ada tugas'), findsOneWidget);
    });

    testWidgets('membersihkan field setelah tugas ditambahkan',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(repository: FakeTaskRepository()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Tugas baru',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('task-title-field')),
      );
      expect(textField.controller?.text, isEmpty);
    });
  });
}
