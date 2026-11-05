import '../../../../core/failures.dart';
import '../repositories/ai_repository.dart';

class AskCampusAi {
  const AskCampusAi(this._repository);
  final AiRepository _repository;

  Future<({String? response, Failure? failure})> call(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return Future.value((
        response: null,
        failure: const ValidationFailure('Pertanyaan tidak boleh kosong'),
      ));
    }
    return _repository.sendMessage(trimmed);
  }
}

