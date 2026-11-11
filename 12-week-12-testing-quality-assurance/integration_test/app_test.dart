import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testing_lab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pengguna dapat menambahkan dan menghapus tugas',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verifikasi halaman awal
    expect(find.text('Daftar Tugas'), findsOneWidget);
    expect(find.text('Belum ada tugas'), findsOneWidget);

    // Tambah tugas pertama
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Baca materi Flutter',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Baca materi Flutter'), findsOneWidget);

    // Tambah tugas kedua
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Kerjakan latihan',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Kerjakan latihan'), findsOneWidget);

    // Hapus tugas pertama
    await tester.tap(find.byKey(const Key('delete-task-0')));
    await tester.pumpAndSettle();

    expect(find.text('Baca materi Flutter'), findsNothing);
    expect(find.text('Kerjakan latihan'), findsOneWidget);
  });

  testWidgets('validasi menolak judul kosong', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Tekan simpan tanpa mengisi judul
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Judul tugas tidak boleh kosong'), findsOneWidget);
  });
}
