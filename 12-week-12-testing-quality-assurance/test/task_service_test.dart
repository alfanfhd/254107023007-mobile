import 'package:flutter_test/flutter_test.dart';
import 'package:testing_lab/task_service.dart';
import 'fake_task_repository.dart';

void main() {
  group('TaskService', () {
    group('loadTasks', () {
      test('meneruskan data dari repository', () async {
        final service = TaskService(
          FakeTaskRepository(initialTasks: ['Baca materi', 'Kerjakan tugas']),
        );

        final tasks = await service.loadTasks();

        expect(tasks, ['Baca materi', 'Kerjakan tugas']);
      });

      test('mengembalikan daftar kosong jika tidak ada tugas', () async {
        final service = TaskService(FakeTaskRepository());

        final tasks = await service.loadTasks();

        expect(tasks, isEmpty);
      });

      test('melempar exception jika repository gagal', () async {
        final service = TaskService(
          FakeTaskRepository(error: Exception('Koneksi gagal')),
        );

        expect(() => service.loadTasks(), throwsException);
      });
    });

    group('addTask', () {
      test('menambahkan tugas valid ke repository', () async {
        final repo = FakeTaskRepository();
        final service = TaskService(repo);

        await service.addTask('Tugas baru');

        final tasks = await repo.getTasks();
        expect(tasks, ['Tugas baru']);
      });

      test('menghapus spasi di awal dan akhir judul', () async {
        final repo = FakeTaskRepository();
        final service = TaskService(repo);

        await service.addTask('  Tugas baru  ');

        final tasks = await repo.getTasks();
        expect(tasks, ['Tugas baru']);
      });

      test('menolak judul kosong dengan ArgumentError', () async {
        final service = TaskService(FakeTaskRepository());

        expect(() => service.addTask(''), throwsArgumentError);
      });

      test('menolak judul hanya spasi dengan ArgumentError', () async {
        final service = TaskService(FakeTaskRepository());

        expect(() => service.addTask('   '), throwsArgumentError);
      });
    });

    group('deleteTask', () {
      test('menghapus tugas berdasarkan index', () async {
        final repo = FakeTaskRepository(initialTasks: ['A', 'B', 'C']);
        final service = TaskService(repo);

        await service.deleteTask(1);

        final tasks = await repo.getTasks();
        expect(tasks, ['A', 'C']);
      });

      test('melempar RangeError untuk index negatif', () async {
        final service = TaskService(
          FakeTaskRepository(initialTasks: ['A']),
        );

        expect(() => service.deleteTask(-1), throwsRangeError);
      });

      test('melempar RangeError untuk index di luar jangkauan', () async {
        final service = TaskService(
          FakeTaskRepository(initialTasks: ['A']),
        );

        expect(() => service.deleteTask(5), throwsRangeError);
      });
    });
  });
}
