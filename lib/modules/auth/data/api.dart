import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/types/api_response.dart';

class AuthApi {
  
  final _client = ApiClient.instance.dio;
  static const _refreshPath = '/auth/refresh';
  static const _loginEmailStartPath = '/auth/login/email';
  static const _loginPhoneStartPath = '/auth/login/phone/start';
  static const _otpVerifyPath = '/auth/otp/verify';
  static const _mePath = '/auth/me';

  static const _registerPhonePath = '/auth/register/phone/start';
  static const _registerEmailPath = '/auth/register/email';
  static const _forgotPasswordPath = '/auth/forgot-password';

  ApiResponse<Map<String, dynamic>> _wrap(Map<String, dynamic> raw) {
    final code = raw['code'];
    final ok = code == 200;
    return ApiResponse<Map<String, dynamic>>(
      status: ok ? 'success' : 'error',
      data: (raw['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      message: raw['message'] as String?,
      error: raw,
    );
  }

    Future<ApiResponse<Map<String, dynamic>>> refresh({
    required String refreshToken,
  }) async {
    final res = await _client.post(
      _refreshPath,
      data: {
        'refresh_token': refreshToken,
      },
      options: Options(headers: {
        'content-type': 'application/json',
      }),
    );
    return _wrap((res.data as Map).cast<String, dynamic>());
  }


  Future<ApiResponse<Map<String, dynamic>>> loginEmailStart({
    required String email,
    required String password,
    required String deviceId,
    required String deviceFingerprint,
  }) async {
    final res = await _client.post(
      _loginEmailStartPath,
      data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_fingerprint': deviceFingerprint,
      },
    );
    return _wrap((res.data as Map).cast<String, dynamic>());
  }

  Future<ApiResponse<Map<String, dynamic>>> loginPhoneStart({
    required String phone,
    required String deviceId,
    required String deviceFingerprint,
  }) async {
    final res = await _client.post(
      _loginPhoneStartPath,
      data: {
        'phone': phone,
        'device_id': deviceId,
        'device_fingerprint': deviceFingerprint,
      },
    );
    return _wrap((res.data as Map).cast<String, dynamic>());
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String otpId,
    required String code,
    required String deviceId,
    required bool trustDevice,
  }) async {
    final res = await _client.post(
      _otpVerifyPath,
      data: {
        'otp_id': otpId,
        'code': code,
        'device_id': deviceId,
        'trust_device': trustDevice,
      },
    );
    return _wrap((res.data as Map).cast<String, dynamic>());
  }

  Future<ApiResponse<Map<String, dynamic>>> me() async {
    final res = await _client.get(_mePath);
    return _wrap((res.data as Map).cast<String, dynamic>());
  }

  Future<ApiResponse<Map<String, dynamic>>> registerPhone({
    required String phone,
    required String displayName,
  }) async {
    final res = await _client.post(
      _registerPhonePath,
      data: {'phone': phone, 'display_name': displayName},
    );
    return _wrap((res.data as Map).cast<String, dynamic>());
  }

  Future<ApiResponse<Map<String, dynamic>>> registerEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.post(
      _registerEmailPath,
      data: {'email': email, 'password': password, 'display_name': displayName},
    );
    return _wrap((res.data as Map).cast<String, dynamic>());
  }

  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String identifier,
  }) async {
    final res = await _client.post(
      _forgotPasswordPath,
      data: {'identifier': identifier},
    );
    return _wrap((res.data as Map).cast<String, dynamic>());
  }
}
