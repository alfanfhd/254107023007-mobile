import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_navigation/pages/todo_page.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: TodoPage()),
      ),
    );

    // Awalnya kosong
    expect(find.text('Belum ada tugas'), findsOneWidget);

    // Tap tombol FAB (+) untuk buka dialog
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Masukkan teks tugas baru
    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');

    // Tap tombol Tambah, lalu tunggu dialog tutup sepenuhnya
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle(); // pastikan dialog tutup dulu sebelum expect

    // Tugas harus muncul di list (hanya 1, bukan EditableText di dialog)
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });

  testWidgets('menghapus tugas', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: TodoPage()),
      ),
    );

    // Tambah tugas dulu
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas untuk dihapus');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle(); // tunggu dialog tutup

    expect(find.text('Tugas untuk dihapus'), findsOneWidget);

    // Hapus tugas
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    // Harus kembali ke state kosong
    expect(find.text('Belum ada tugas'), findsOneWidget);
  });
}
