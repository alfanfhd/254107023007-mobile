import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_notify/ai/ai_service.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

void main() {
  group('AiService Tests', () {
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage();
    });

    test(
      'Melempar exception jika API key belum diatur di secure storage',
      () async {
        final service = AiService(storage: fakeStorage);

        expect(
          () => service.ask('Jadwal hari Senin?'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('API key tidak tersedia'),
            ),
          ),
        );
      },
    );

    test('Berhasil mengembalikan respons teks saat API Gemini mengembalikan HTTP 200', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'dummy_gemini_key');

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'dummy_gemini_key');
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': 'Jadwal kuliah hari Senin adalah Pemrograman Mobile jam 08:00 WIB.',
                    },
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(storage: fakeStorage, client: mockClient);
      final response = await service.ask('Jadwal hari Senin?');

      expect(
        response,
        'Jadwal kuliah hari Senin adalah Pemrograman Mobile jam 08:00 WIB.',
      );
    });

    test('Melempar exception terstruktur saat API Key ditolak / kuota habis (HTTP 403)', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'invalid_key');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'API key not valid'},
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(storage: fakeStorage, client: mockClient);

      expect(
        () => service.ask('Halo AI'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API Key tidak valid atau kuota habis'),
          ),
        ),
      );
    });

    test(
      'Menyaring NIK 16 digit otomatis dari prompt demi privasi data pengguna',
      () {
        final service = AiService(storage: fakeStorage);
        final sanitized = service.sanitizePrompt(
          'Halo AI, ini data NIK saya 3507123456780001 mohon bantu cek nilai.',
        );

        expect(sanitized, contains('[NIK_DISAMARKAN]'));
        expect(sanitized.contains('3507123456780001'), isFalse);
      },
    );

    test('Dapat menyimpan dan membaca API key dari Secure Storage', () async {
      final service = AiService(storage: fakeStorage);
      await service.saveApiKey('AIzaSyNewKey123');

      final saved = await service.getApiKey();
      expect(saved, 'AIzaSyNewKey123');
    });

    test('Mendukung fungsi simulasi OCR dan Speech-to-Text', () async {
      final service = AiService(storage: fakeStorage);
      final ocrResult = await service.recognizeText('path/image.jpg');
      final sttResult = await service.speechToText('path/audio.mp3');

      expect(ocrResult, contains('Ekstraksi OCR'));
      expect(sttResult, contains('tugas pemrograman mobile'));
    });
  });
}
