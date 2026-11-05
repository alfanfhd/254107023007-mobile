import '../../../../core/failures.dart';

abstract class AiRepository {
  Future<({String? response, Failure? failure})> sendMessage(String message);
  Future<String?> getApiKey();
  Future<void> saveApiKey(String key);
}

