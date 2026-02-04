import 'entity.dart';
import 'repository.dart';
class RefreshTokenUseCase {
  final AuthRepository repo;
  RefreshTokenUseCase(this.repo);

  Future<AuthTokenPair> call(String refreshToken) {
    return repo.refresh(refreshToken);
  }
}


class LoginEmailStartUseCase {
  final AuthRepository repository;
  LoginEmailStartUseCase(this.repository);

  Future<AuthLoginResult> call({
    required String email,
    required String password,
    required String deviceId,
    required String deviceFingerprint,
  }) {
    return repository.loginEmailStart(
      email: email,
      password: password,
      deviceId: deviceId,
      deviceFingerprint: deviceFingerprint,
    );
  }
}

class LoginPhoneStartUseCase {
  final AuthRepository repository;
  LoginPhoneStartUseCase(this.repository);

  Future<OtpChallenge> call({
    required String phone,
    required String deviceId,
    required String deviceFingerprint,
  }) {
    return repository.loginPhoneStart(
      phone: phone,
      deviceId: deviceId,
      deviceFingerprint: deviceFingerprint,
    );
  }
}

class VerifyOtpUseCase {
  final AuthRepository repository;
  VerifyOtpUseCase(this.repository);

  Future<AuthTokens> call({required OtpVerifyPayload payload}) {
    return repository.verifyOtp(payload: payload);
  }
}

class GetMeUseCase {
  final AuthRepository repository;
  GetMeUseCase(this.repository);

  Future<AuthMe> call() => repository.getMe();
}

class RegisterPhoneUseCase {
  final AuthRepository repository;
  RegisterPhoneUseCase(this.repository);

  Future<void> call({required RegisterPhonePayload payload}) {
    return repository.registerPhone(payload: payload);
  }
}

class RegisterEmailUseCase {
  final AuthRepository repository;
  RegisterEmailUseCase(this.repository);

  Future<void> call({required RegisterEmailPayload payload}) {
    return repository.registerEmail(payload: payload);
  }
}

class ForgotPasswordUseCase {
  final AuthRepository repository;
  ForgotPasswordUseCase(this.repository);

  Future<void> call({required String identifier}) {
    return repository.forgotPassword(identifier: identifier);
  }
}
