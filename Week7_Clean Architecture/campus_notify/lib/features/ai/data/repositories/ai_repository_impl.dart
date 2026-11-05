import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/ai/ai_service.dart';

import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl({required this.service});

  final AiService service;

  @override
  Future<({String? response, Failure? failure})> sendMessage(
    String message,
  ) async {
    try {
      const systemPrompt =
          'Kamu asisten kampus ramah untuk mahasiswa Polinema. Jawab dalam Bahasa Indonesia dengan singkat, solutif, dan informatif (maksimal 3 kalimat).';
      final text = await service.ask(message, systemInstruction: systemPrompt);
      return (response: text, failure: null);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return (response: null, failure: NetworkFailure(msg));
    }
  }

  @override
  Future<String?> getApiKey() => service.getApiKey();

  @override
  Future<void> saveApiKey(String key) => service.saveApiKey(key);
}
