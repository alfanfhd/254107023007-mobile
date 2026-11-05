import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/ai/ai_service.dart';

import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/ask_campus_ai.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(service: ref.watch(aiServiceProvider));
});

final askCampusAiProvider = Provider<AskCampusAi>((ref) {
  return AskCampusAi(ref.watch(aiRepositoryProvider));
});

class AiLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final aiLoadingProvider = NotifierProvider<AiLoadingNotifier, bool>(
  AiLoadingNotifier.new,
);

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        id: 'initial_welcome',
        text: 'Halo! Saya Asisten Cerdas Kampus Polinema. Ada yang bisa saya bantu mengenai jadwal, pengumuman, atau materi perkuliahan?',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    ];
  }

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    state = [...state, userMsg];

    ref.read(aiLoadingProvider.notifier).set(true);

    final useCase = ref.read(askCampusAiProvider);
    final result = await useCase.call(trimmed);

    ref.read(aiLoadingProvider.notifier).set(false);

    if (result.failure != null) {
      final errorMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_err',
        text:
            'Layanan AI Sibuk: ${result.failure!.message}. Silakan coba lagi nanti atau gunakan mode offline.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isError: true,
      );
      state = [...state, errorMsg];
    } else {
      final aiMsg = ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_ai',
        text: result.response ?? 'Respons kosong dari asisten AI.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      state = [...state, aiMsg];
    }
  }

  void clearChat() {
    state = [
      ChatMessage(
        id: 'initial_welcome',
        text: 'Percakapan telah direset. Silakan ajukan pertanyaan baru.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(
      ChatMessagesNotifier.new,
    );
