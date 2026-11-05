import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  AiService({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;
  static const String _defaultUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String> ask(String question, {String? systemInstruction}) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final sanitizedQuestion = sanitizePrompt(question);

    final List<Map<String, dynamic>> contents = [];
    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': 'Instruksi Sistem: $systemInstruction'},
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Dipahami, saya siap membantu sesuai instruksi kampus.'},
        ],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': sanitizedQuestion},
      ],
    });

    final response = await _client.post(
      Uri.parse('$_defaultUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return 'Maaf, AI tidak menghasilkan respons. Silakan coba kembali.';
      }
      final parts = candidates[0]['content']['parts'] as List<dynamic>;
      return parts[0]['text'] as String;
    } else if (response.statusCode == 400 || response.statusCode == 403) {
      throw Exception(
        'API Key tidak valid atau kuota habis (HTTP ${response.statusCode})',
      );
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key.trim());
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: 'ai_api_key');
  }

  String sanitizePrompt(String input) {
    // Sanitasi privasi: menyaring potensi NIK (16 digit angka) atau data sensitif
    final nikRegex = RegExp(r'\b\d{16}\b');
    return input.replaceAll(nikRegex, '[NIK_DISAMARKAN]');
  }

  // Simulasi fitur OCR (Optical Character Recognition)
  Future<String> recognizeText(String imagePath) async {
    // Simulasi ekstraksi teks dari gambar dokumen / papan pengumuman
    return 'Ekstraksi OCR: Pengumuman Jadwal Ujian Akhir Semester Ruang A2.';
  }

  // Simulasi fitur Speech-to-Text
  Future<String> speechToText(String audioPath) async {
    // Simulasi transkripsi input suara pengguna menjadi string teks
    return 'Kapan batas akhir pengumpulan tugas pemrograman mobile?';
  }
}
