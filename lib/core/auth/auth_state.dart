import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  AuthState._internal();

  static final AuthState instance = AuthState._internal();

  String? _token;
  String? _refreshToken;
  List<String> _permissions = [];

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  List<String> get permissions => List.unmodifiable(_permissions);

  void setToken({
    required String accessToken,
    required String refreshToken,
  }) {
    _token = accessToken;
    _refreshToken = refreshToken;
    notifyListeners();
  }

  void clear() {
    _token = null;
    _refreshToken = null;
    _permissions = [];
    notifyListeners();
  }

  void setPermissions(List<String> permissions) {
    _permissions = permissions;
    notifyListeners();
  }
}
