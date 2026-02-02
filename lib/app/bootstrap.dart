import '../core/storage/session_storage.dart';
import '../core/auth/auth_state.dart';

Future<void> bootstrap() async {
  final token = await SessionStorage.instance.getToken();
  if (token != null) {
    AuthState.instance.setToken(token);
  }
}
