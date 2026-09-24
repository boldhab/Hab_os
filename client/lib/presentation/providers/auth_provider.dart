import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.authenticating() => const AuthState(status: AuthStatus.authenticating);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.unauthenticated, errorMessage: message);

  @override
  List<Object?> get props => [status, user, errorMessage];
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(authRepo: authRepo, storage: storage);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepo;
  final storage;

  AuthNotifier({required this.authRepo, required this.storage})
      : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await storage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }

    final user = await authRepo.getProfile();
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      await storage.clearAll();
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.authenticating();
    try {
      final user = await authRepo.login(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> register(String email, String password, {String? name}) async {
    state = AuthState.authenticating();
    try {
      final user = await authRepo.register(email: email, password: password, name: name);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await authRepo.logout();
    state = AuthState.unauthenticated();
  }
}
