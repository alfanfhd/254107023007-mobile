import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call(String email, String password) {
    return _repository.login(email: email, password: password);
  }
}
