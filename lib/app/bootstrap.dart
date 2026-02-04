import '../core/storage/session_storage.dart';
import '../core/auth/auth_state.dart';

Future<void> bootstrap() async {
  final token = await SessionStorage.instance.getToken();
  final refreshToken = await SessionStorage.instance.getRefreshToken();
  if (token != null) {
    AuthState.instance.setToken(
      accessToken: token,
      refreshToken: refreshToken ?? '',
    );
  }
}
