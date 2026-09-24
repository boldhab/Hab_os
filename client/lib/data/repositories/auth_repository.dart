import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio: dio, storage: storage);
});

class AuthRepository {
  final Dio dio;
  final SecureStorageService storage;

  AuthRepository({required this.dio, required this.storage});

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data['data'] ?? response.data;
      final user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
      final tokens = AuthTokensModel.fromJson(Map<String, dynamic>.from(data['tokens']));

      await storage.saveAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      await storage.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Login failed. Please check your credentials.';
      throw Exception(message);
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );

      final data = response.data['data'] ?? response.data;
      final user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
      final tokens = AuthTokensModel.fromJson(Map<String, dynamic>.from(data['tokens']));

      await storage.saveAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      await storage.saveUserId(user.id);

      return user;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Registration failed. Please try again.';
      throw Exception(message);
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      final response = await dio.get(ApiEndpoints.profile);
      final data = response.data['data'] ?? response.data;
      return UserModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await storage.clearAll();
  }
}
