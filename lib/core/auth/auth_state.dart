import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  AuthState._internal();

  static final AuthState instance = AuthState._internal();

  String? _token;
  List<String> _permissions = [];

  String? get token => _token;
  List<String> get permissions => List.unmodifiable(_permissions);

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void clear() {
    _token = null;
    _permissions = [];
    notifyListeners();
  }

  void setPermissions(List<String> permissions) {
    _permissions = permissions;
    notifyListeners();
  }
}
