import 'package:dio/dio.dart';
import '../../constants/api_endpoints.dart';
import '../../storage/secure_storage_service.dart';

class RefreshInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorageService storageService;
  bool _isRefreshing = false;

  RefreshInterceptor({
    required this.dio,
    required this.storageService,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final requestPath = err.requestOptions.path;
      // Avoid looping if the failing request is refresh or login
      if (requestPath.contains(ApiEndpoints.refresh) ||
          requestPath.contains(ApiEndpoints.login)) {
        return handler.next(err);
      }

      _isRefreshing = true;

      try {
        final refreshToken = await storageService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await storageService.clearAll();
          _isRefreshing = false;
          return handler.next(err);
        }

        // Dedicated Dio instance for refresh call to avoid interceptor recursion
        final tokenDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
        final response = await tokenDio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data['data'] ?? response.data;
          final newAccessToken = data['accessToken'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;

          if (newAccessToken != null) {
            await storageService.saveAccessToken(newAccessToken);
            if (newRefreshToken != null) {
              await storageService.saveRefreshToken(newRefreshToken);
            }

            // Retry original request with new access token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(options);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (_) {
        await storageService.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }
}
