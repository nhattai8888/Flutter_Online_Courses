import 'package:flutter/services.dart';

class DeviceFingerprint {
  DeviceFingerprint._internal();

  static final DeviceFingerprint instance = DeviceFingerprint._internal();

  static const MethodChannel _channel = MethodChannel('core_device_fingerprint');

  /// Try to get a stable fingerprint from native platform.
  /// If native is not implemented, returns null (caller should fallback).
  Future<String?> tryGetNativeFingerprint() async {
    try {
      final value = await _channel.invokeMethod<String>('getFingerprint');
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
