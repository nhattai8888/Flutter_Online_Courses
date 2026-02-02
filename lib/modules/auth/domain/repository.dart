import 'entity.dart';

abstract class AuthRepository {
  /// Email login start: POST /auth/login/email/start
  /// Either returns tokens immediately OR requires OTP challenge.
  Future<AuthLoginResult> loginEmailStart({
    required String email,
    required String password,
    required String deviceId,
    required String deviceFingerprint,
  });

  /// Phone login start: POST /auth/login/phone/start
  /// Returns otpId for OTP flow.
  Future<OtpChallenge> loginPhoneStart({
    required String phone,
    required String deviceId,
    required String deviceFingerprint,
  });

  /// OTP verify: POST /auth/otp/verify
  Future<AuthTokens> verifyOtp({
    required OtpVerifyPayload payload,
  });

  /// Me: GET /auth/me
  Future<AuthMe> getMe();

  Future<void> registerPhone({required RegisterPhonePayload payload});
  Future<void> registerEmail({required RegisterEmailPayload payload});

  /// Endpoint not specified (keep stub)
  Future<void> forgotPassword({required String identifier});
}
