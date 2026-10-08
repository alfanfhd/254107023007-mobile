import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      if (!email.contains('@') || password.length < 6) {
        return (session: null, failure: const LocalFailure('Email atau kata sandi tidak valid'));
      }
      return (
        session: AuthSession(
          access: 'mock-access-for-$email',
          refresh: 'mock-refresh-for-$email',
        ),
        failure: null
      );
    } catch (e) {
      return (session: null, failure: NetworkFailure('Gagal login: $e'));
    }
  }

  @override
  Future<({String? token, Failure? failure})> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      if (refreshToken.isEmpty) {
        return (token: null, failure: const LocalFailure('Refresh token hilang'));
      }
      return (
        token: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
        failure: null
      );
    } catch (e) {
      return (token: null, failure: NetworkFailure('Gagal refresh token: $e'));
    }
  }
}
