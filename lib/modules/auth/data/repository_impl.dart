import '../domain/entity.dart';
import '../domain/repository.dart';
import '../../../core/types/api_response.dart';
import 'api.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi api;

  AuthRepositoryImpl(this.api);

  AuthTokens _mapTokens(Map<String, dynamic> data) {
    return AuthTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      tokenType: (data['token_type'] as String?) ?? 'bearer',
    );
  }

   @override
  Future<AuthTokenPair> refresh(String refreshToken) async {
    final res = await api.refresh(refreshToken: refreshToken);
    final data = unwrap<Map<String, dynamic>>(res);

    // Backend sample:
    // { code:200, data:{ access_token, refresh_token, token_type }, message:"OK" }
    final inner = (data['data'] is Map) ? (data['data'] as Map).cast<String, dynamic>() : data;

    return AuthTokenPair(
      accessToken: inner['access_token'] as String,
      refreshToken: inner['refresh_token'] as String,
      tokenType: (inner['token_type'] as String?) ?? 'bearer',
    );
  }

  @override
  Future<AuthLoginResult> loginEmailStart({
    required String email,
    required String password,
    required String deviceId,
    required String deviceFingerprint,
  }) async {
    final res = await api.loginEmailStart(
      email: email,
      password: password,
      deviceId: deviceId,
      deviceFingerprint: deviceFingerprint,
    );

    final data = unwrap(res);

    // OTP-required shape (must exist for "logged on other device before")
    // Expect: { require_otp: true, otp_id: "..." }
    final otpId = data['otp_id'] as String?;
    final mfaRequired = data['mfa_required'] == true;
    if (mfaRequired) {
      if (otpId == null || otpId.isEmpty) {
        throw Exception('mfa_required=true but otp_id missing');
      }
      return AuthLoginResult.requireOtp(OtpChallenge(otpId: otpId));
    }


    // Normal login returns tokens like provided
    if (data.containsKey('access_token')) {
      return AuthLoginResult.authed(_mapTokens(data));
    }

    throw Exception('Unexpected login response data.');
  }

  @override
  Future<OtpChallenge> loginPhoneStart({
    required String phone,
    required String deviceId,
    required String deviceFingerprint,
  }) async {
    final res = await api.loginPhoneStart(
      phone: phone,
      deviceId: deviceId,
      deviceFingerprint: deviceFingerprint,
    );

    final data = unwrap(res);

    final otpId = data['otp_id'] as String?;
    if (otpId == null || otpId.isEmpty) {
      throw Exception('Missing otp_id from /auth/login/phone/start');
    }
    return OtpChallenge(otpId: otpId);
  }

  @override
  Future<AuthTokens> verifyOtp({required OtpVerifyPayload payload}) async {
    final res = await api.verifyOtp(
      otpId: payload.otpId,
      code: payload.code,
      deviceId: payload.deviceId,
      trustDevice: payload.trustDevice,
    );

    final data = unwrap(res);
    return _mapTokens(data);
  }

  @override
  Future<AuthMe> getMe() async {
    final res = await api.me();
    final data = unwrap(res);

    return AuthMe(
      userId: data['user_id'] as String,
      displayName: data['display_name'] as String,
      roles: (data['roles'] as List<dynamic>? ?? const []).cast<String>(),
      permissions: (data['permissions'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  @override
  Future<void> registerPhone({required RegisterPhonePayload payload}) async {
    final res = await api.registerPhone(
      phone: payload.phone,
      displayName: payload.displayName,
    );
    unwrap(res);
  }

  @override
  Future<void> registerEmail({required RegisterEmailPayload payload}) async {
    final res = await api.registerEmail(
      email: payload.email,
      password: payload.password,
      displayName: payload.displayName,
    );
    unwrap(res);
  }

  @override
  Future<void> forgotPassword({required String identifier}) async {
    final res = await api.forgotPassword(identifier: identifier);
    unwrap(res);
  }
}
