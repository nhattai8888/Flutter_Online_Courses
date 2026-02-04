import 'dart:async';

import 'package:dio/dio.dart';

import '../env/env.dart';
import '../storage/session_storage.dart';
import '../types/app_error.dart';

typedef UnauthorizedCallback = void Function();

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  final SessionStorage _storage = SessionStorage.instance;

  UnauthorizedCallback? onUnauthorized;

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'content-type': 'application/json',
      },
      // keep default validateStatus => Dio throws for 4xx/5xx
    ),
  )..interceptors.addAll([
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    ]);

  // ---- refresh lock (avoid multi refresh) ----
  Completer<void>? _refreshCompleter;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    // Only handle 401 here for refresh
    if (status == 401) {
      final didRefresh = await _tryRefreshToken();
      if (didRefresh) {
        try {
          final retryResponse = await _retry(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          // fallthrough to logout
        }
      }

      await _storage.clearToken();
      onUnauthorized?.call();

      return handler.reject(_asAppError(err));
    }

    return handler.reject(_asAppError(err));
  }

  Future<bool> _tryRefreshToken() async {
    // If a refresh is already running, wait for it
    if (_refreshCompleter != null) {
      try {
        await _refreshCompleter!.future;
        final token = await _storage.getToken();
        return token != null && token.isNotEmpty;
      } catch (_) {
        return false;
      }
    }

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    _refreshCompleter = Completer<void>();

    try {
      // IMPORTANT: use a separate Dio without interceptors to avoid recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          headers: {'content-type': 'application/json'},
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      // Accept both:
      // A) {code, data:{access_token, refresh_token, token_type}, message}
      // B) {status:"success", data:{...}}
      final Map<String, dynamic> json = (res.data as Map).cast<String, dynamic>();

      Map<String, dynamic> tokenObj;
      if (json['data'] is Map && (json['data'] as Map)['access_token'] != null) {
        tokenObj = (json['data'] as Map).cast<String, dynamic>();
      } else if (json['data'] is Map && (json['data'] as Map)['data'] is Map) {
        tokenObj = ((json['data'] as Map)['data'] as Map).cast<String, dynamic>();
      } else if (json['access_token'] != null) {
        tokenObj = json;
      } else {
        throw Exception('Invalid refresh response');
      }

      final newAccess = tokenObj['access_token'] as String;
      final newRefresh = tokenObj['refresh_token'] as String;

      await _storage.setTokens(accessToken: newAccess, refreshToken: newRefresh);

      _refreshCompleter!.complete();
      _refreshCompleter = null;
      return true;
    } catch (e) {
      _refreshCompleter?.completeError(e);
      _refreshCompleter = null;
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storage.getToken();

    final opts = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers),
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      validateStatus: requestOptions.validateStatus,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      extra: requestOptions.extra,
    );

    if (token != null && token.isNotEmpty) {
      opts.headers ??= {};
      opts.headers!['authorization'] = 'Bearer $token';
    }

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: opts,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }

  DioException _asAppError(DioException err) {
    final status = err.response?.statusCode;
    final raw = err.response?.data;

    final message = (raw is Map && raw['detail'] is String)
        ? raw['detail'] as String
        : err.message ?? 'Network error';

    return DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: AppError(
        code: 'HTTP_${status ?? 'UNKNOWN'}',
        message: message,
        status: status,
        raw: raw,
      ),
    );
  }
}
