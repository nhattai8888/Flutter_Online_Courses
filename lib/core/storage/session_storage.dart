import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../devices/device_fingerprint.dart';
class SessionStorage {
  SessionStorage._internal();

  static final SessionStorage instance = SessionStorage._internal();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  static const _deviceIdKey = 'device_id';
  static const _deviceFingerprintKey = 'device_fingerprint';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

 Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_tokenKey, accessToken);
    await sp.setString(_refreshTokenKey, refreshToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> setRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  /// ✅ device_id: generate once and persist for this app install.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final created = _randomHex(16); // 32 hex chars
    await prefs.setString(_deviceIdKey, created);
    return created;
  }

  /// ✅ device_fingerprint: prefer native-derived stable fingerprint.
  /// - If native available: persist it once and reuse.
  /// - If native not available: fallback to persisted random fingerprint (still stable per install).
  Future<String> getOrCreateDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();

    // If we already have one persisted, reuse it.
    final existing = prefs.getString(_deviceFingerprintKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Try native fingerprint first.
    final nativeFp = await DeviceFingerprint.instance.tryGetNativeFingerprint();
    if (nativeFp != null && nativeFp.isNotEmpty) {
      await prefs.setString(_deviceFingerprintKey, nativeFp);
      return nativeFp;
    }

    // Fallback (still stable per install)
    final created = _randomHex(16);
    await prefs.setString(_deviceFingerprintKey, created);
    return created;
  }

  String _randomHex(int bytesLen) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(bytesLen, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
