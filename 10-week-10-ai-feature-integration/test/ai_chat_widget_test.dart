import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai/domain/repositories/ai_repository.dart';
import 'package:campus_notify/features/ai/presentation/pages/ai_chat_page.dart';
import 'package:campus_notify/features/ai/presentation/providers/ai_providers.dart';

class FakeAiRepository implements AiRepository {
  FakeAiRepository({this.fail = false});

  final bool fail;
  String? currentKey;

  @override
  Future<({String? response, Failure? failure})> sendMessage(
    String message,
  ) async {
    if (fail) {
      return (
        response: null,
        failure: const NetworkFailure('Koneksi timeout (simulasi)'),
      );
    }
    return (
      response: 'Halo Mahasiswa, jawaban atas "$message" telah tersedia.',
      failure: null,
    );
  }

  @override
  Future<String?> getApiKey() async => currentKey;

  @override
  Future<void> saveApiKey(String key) async {
    currentKey = key;
  }
}

void main() {
  testWidgets(
    'Menampilkan antarmuka chat AI, privacy notice, dan dialog API Key',
    (WidgetTester tester) async {
      final fakeRepo = FakeAiRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(home: AiChatPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi header dan pesan sambutan
      expect(find.text('Asisten Cerdas AI'), findsOneWidget);
      expect(find.textContaining('Privasi Terjaga'), findsOneWidget);
      expect(
        find.textContaining('Halo! Saya Asisten Cerdas Kampus Polinema'),
        findsOneWidget,
      );

      // Buka dialog API key
      await tester.tap(find.byKey(const Key('open_api_key_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.text('Atur Gemini API Key'), findsOneWidget);
      expect(find.byKey(const Key('api_key_input_field')), findsOneWidget);

      // Masukkan kunci dan simpan
      await tester.enterText(
        find.byKey(const Key('api_key_input_field')),
        'AIzaSyTest123',
      );
      await tester.tap(find.byKey(const Key('save_api_key_button')));
      await tester.pumpAndSettle();

      expect(fakeRepo.currentKey, 'AIzaSyTest123');
    },
  );

  testWidgets(
    'Mengirim pesan pengguna dan menampilkan bubble balasan asisten AI',
    (WidgetTester tester) async {
      final fakeRepo = FakeAiRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(home: AiChatPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Kirim pesan chat pengguna
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Kapan jadwal ujian akhir?',
      );
      await tester.tap(find.byKey(const Key('send_message_button')));
      await tester.pumpAndSettle();

      // Verifikasi bubble pesan user dan respons AI muncul di layar
      expect(find.text('Kapan jadwal ujian akhir?'), findsOneWidget);
      expect(
        find.text(
          'Halo Mahasiswa, jawaban atas "Kapan jadwal ujian akhir?" telah tersedia.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Menampilkan bubble Fallback Error ramah saat pemanggilan AI gagal',
    (WidgetTester tester) async {
      final failingRepo = FakeAiRepository(fail: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiRepositoryProvider.overrideWithValue(failingRepo)],
          child: const MaterialApp(home: AiChatPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Kirim pesan chat yang akan memicu kegagalan
      await tester.enterText(
        find.byKey(const Key('chat_input_field')),
        'Pertanyaan gagal',
      );
      await tester.tap(find.byKey(const Key('send_message_button')));
      await tester.pumpAndSettle();

      // Verifikasi pesan Fallback Error ditampilkan dengan ramah
      expect(find.textContaining('Layanan AI Sibuk'), findsOneWidget);
      expect(find.textContaining('mode offline'), findsOneWidget);
    },
  );
}
