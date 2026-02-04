import 'package:flutter/foundation.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/types/app_error.dart';

enum AuthMode { login, register }
enum AuthStep { credential, otp }

/// UI-only enum for social login buttons (not wired to backend yet).
enum SocialProvider { google, apple, microsoft }

class AuthController extends ChangeNotifier {
  final LoginEmailStartUseCase loginEmailStartUseCase;
  final LoginPhoneStartUseCase loginPhoneStartUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final GetMeUseCase getMeUseCase;
  final RegisterPhoneUseCase registerPhoneUseCase;
  final RegisterEmailUseCase registerEmailUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;

  AuthController({
    required this.loginEmailStartUseCase,
    required this.loginPhoneStartUseCase,
    required this.verifyOtpUseCase,
    required this.getMeUseCase,
    required this.registerPhoneUseCase,
    required this.registerEmailUseCase,
    required this.forgotPasswordUseCase,
  });

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _info; // for success toast/snackbar
  String? get info => _info;

  AuthMode _mode = AuthMode.login;
  AuthMode get mode => _mode;

  AuthStep _step = AuthStep.credential;
  AuthStep get step => _step;

  String? _otpId;
  String? get otpId => _otpId;

  // Keep last identifier so we can resend OTP (phone flow) easily.
  String? _lastIdentifier;
  String? get lastIdentifier => _lastIdentifier;
  bool _otpVerifiedSuccessfully = false;
  bool get otpVerifiedSuccessfully => _otpVerifiedSuccessfully;

  void setMode(AuthMode mode) {
    _mode = mode;
    _error = null;
    _info = null;
    _step = AuthStep.credential;
    _otpId = null;
      _otpVerifiedSuccessfully = false;
    notifyListeners();
  }

  void clearBanners() {
    _error = null;
    _info = null;
    notifyListeners();
  }

  bool isPhone(String input) => RegExp(r'^\+?\d{8,15}$').hasMatch(input.trim());
  bool isEmail(String input) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input.trim());

  /// Returns a user-friendly validation error (or null if valid).
  String? validateCredential({
    required String identifier,
    required String password,
    required String displayName,
  }) {
    final id = identifier.trim();
    if (id.isEmpty) return 'Vui lòng nhập Email hoặc SĐT.';

    final phone = isPhone(id);
    final email = isEmail(id);

    if (!phone && !email) return 'Email hoặc SĐT không hợp lệ.';

    if (_mode == AuthMode.login) {
      // Email login requires password; phone login uses OTP.
      if (email && password.trim().isEmpty) return 'Vui lòng nhập mật khẩu.';
      return null;
    }

    // Register
    if (displayName.trim().isEmpty) return 'Vui lòng nhập Tên hiển thị.';
    if (email && password.trim().length < 6) return 'Mật khẩu cần tối thiểu 6 ký tự.';
    return null;
  }

  Future<void> submitLogin({
    required String identifier,
    required String password, // only for email
  }) async {
    clearBanners();
    _lastIdentifier = identifier.trim();

    // Client-side validation
    final err = validateCredential(identifier: identifier, password: password, displayName: '');
    if (err != null) {
      _error = err;
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final deviceId = await SessionStorage.instance.getOrCreateDeviceId();
      final deviceFp = await SessionStorage.instance.getOrCreateDeviceFingerprint();
      final input = identifier.trim();

      if (isPhone(input)) {
        final challenge = await loginPhoneStartUseCase(
          phone: input,
          deviceId: deviceId,
          deviceFingerprint: deviceFp,
        );
        _otpId = challenge.otpId;
        _step = AuthStep.otp;
        _info = 'Đã gửi OTP. Vui lòng kiểm tra tin nhắn.';
        notifyListeners();
        return;
      }

      // Email login start
      final result = await loginEmailStartUseCase(
        email: input,
        password: password,
        deviceId: deviceId,
        deviceFingerprint: deviceFp,
      );

      if (result.requiresOtp) {
        _otpId = result.challenge!.otpId;
        _step = AuthStep.otp;
        _info = 'Tài khoản yêu cầu xác minh OTP do đăng nhập thiết bị khác.';
        notifyListeners();
        return;
      }

      await _applyTokensAndLoadMe(result.tokens!);
      _info = 'Đăng nhập thành công.';
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Resend OTP:
  /// - phone: call /auth/login/phone/start again using lastIdentifier
  /// - email: backend usually ties otp_id to challenge; we don't resend unless backend provides endpoint
  Future<void> resendOtp() async {
    clearBanners();

    final id = _lastIdentifier?.trim() ?? '';
    if (_step != AuthStep.otp || id.isEmpty) {
      _error = 'Không thể gửi lại OTP lúc này.';
      notifyListeners();
      return;
    }

    if (!isPhone(id)) {
      _error = 'Gửi lại OTP cho email chưa được backend cung cấp endpoint.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final deviceId = await SessionStorage.instance.getOrCreateDeviceId();
      final deviceFp = await SessionStorage.instance.getOrCreateDeviceFingerprint();

      final challenge = await loginPhoneStartUseCase(
        phone: id,
        deviceId: deviceId,
        deviceFingerprint: deviceFp,
      );

      _otpId = challenge.otpId; // update otp_id if backend rotates it
      _info = 'Đã gửi lại OTP.';
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitOtp({
    required String code,
    required bool trustDevice,
  }) async {
    clearBanners();

    if (_otpId == null) {
      _error = 'OTP không được yêu cầu cho phiên đăng nhập này.';
      notifyListeners();
      return;
    }

    if (code.trim().length < 4) {
      _error = 'Mã OTP không hợp lệ.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final deviceId = await SessionStorage.instance.getOrCreateDeviceId();

      final tokens = await verifyOtpUseCase(
        payload: OtpVerifyPayload(
          otpId: _otpId!,
          code: code.trim(),
          deviceId: deviceId,
          trustDevice: trustDevice,
        ),
      );

      await _applyTokensAndLoadMe(tokens);
  _otpVerifiedSuccessfully = true;

      _step = AuthStep.credential;
      _otpId = null;
      _info = 'Xác minh thành công.';
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitRegister({
    required String identifier,
    required String password,
    required String displayName,
  }) async {
    clearBanners();
    _lastIdentifier = identifier.trim();

    final err = validateCredential(
      identifier: identifier,
      password: password,
      displayName: displayName,
    );
    if (err != null) {
      _error = err;
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final input = identifier.trim();

      if (isPhone(input)) {
        await registerPhoneUseCase(
          payload: RegisterPhonePayload(phone: input, displayName: displayName.trim()),
        );
        _info = 'Đăng ký thành công. Vui lòng đăng nhập bằng OTP.';
        notifyListeners();
        return;
      }

      await registerEmailUseCase(
        payload: RegisterEmailPayload(
          email: input,
          password: password,
          displayName: displayName.trim(),
        ),
      );
      _info = 'Đăng ký thành công. Vui lòng đăng nhập.';
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forgotPassword(String identifier) async {
    clearBanners();

    final id = identifier.trim();
    if (id.isEmpty) {
      _error = 'Vui lòng nhập Email hoặc SĐT trước.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      await forgotPasswordUseCase(identifier: id);
      _info = 'Đã gửi hướng dẫn khôi phục (nếu tài khoản tồn tại).';
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> socialLogin(SocialProvider provider) async {
    _error = 'Đăng nhập với ${provider.name} chưa được hỗ trợ.';
    notifyListeners();
  }

  Future<void> _applyTokensAndLoadMe(AuthTokens tokens) async {
    await SessionStorage.instance.setTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    AuthState.instance.setToken(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);

    final me = await getMeUseCase.call();
    AuthState.instance.setPermissions(me.permissions);
  }

  String _friendlyError(Object e) {
    // If core ApiClient normalizes to AppError, show clean message
    if (e is AppError) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
