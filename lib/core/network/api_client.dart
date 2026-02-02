import 'package:dio/dio.dart';
import '../env/env.dart';
import '../storage/session_storage.dart';
import '../types/app_error.dart';

typedef UnauthorizedCallback = void Function();

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  late final Dio dio = Dio(
    BaseOptions(baseUrl: Env.apiBaseUrl),
  )
    ..interceptors.addAll([
      // Detailed logging to help diagnose failing requests
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionStorage.instance.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) async {
          // Log for debugging, but suppress noisy 403 missing-permission logs for weak-words
          try {
            final status = error.response?.statusCode;
            final path = error.requestOptions.path ?? '';
            // Suppress logs for known missing-permission responses to reduce noise
            final respData = error.response?.data;
            final missingPermDetail = respData is Map && respData['detail']?.toString().contains('Missing permissions') == true;
            final shouldSuppress = status == 403 && (path.contains('/vocab/weak-words') || missingPermDetail);
            if (!shouldSuppress) {
              // ignore: avoid_print
              print('ApiClient.onError: ${error.message}');
              // ignore: avoid_print
              print('Request path: ${error.requestOptions.path}');
              // ignore: avoid_print
              print('Request headers: ${error.requestOptions.headers}');
              if (error.response != null) {
                // ignore: avoid_print
                print('Response status: ${error.response?.statusCode}');
                // ignore: avoid_print
                print('Response data: ${error.response?.data}');
              }
            }
          } catch (_) {}

          if (error.response?.statusCode == 401) {
            await SessionStorage.instance.clearToken();
            _onUnauthorized?.call();
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: AppError(
                code: 'network_error',
                message: error.message ?? 'Unknown error',
                status: error.response?.statusCode,
                raw: error,
              ),
            ),
          );
        },
      ),
    ]);

  UnauthorizedCallback? _onUnauthorized;

  void setOnUnauthorized(UnauthorizedCallback callback) {
    _onUnauthorized = callback;
  }
}
