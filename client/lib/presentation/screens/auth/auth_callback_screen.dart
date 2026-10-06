// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final String? token;
  final String? refreshToken;
  final String? error;

  const AuthCallbackScreen({
    super.key,
    this.token,
    this.refreshToken,
    this.error,
  });

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  String _statusMessage = 'Finalizing Google authentication...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processCallback();
    });
  }

  Future<void> _processCallback() async {
    // 1. Check if error was returned by Google or backend
    final error = widget.error ?? Uri.base.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      setState(() {
        _hasError = true;
        _statusMessage = 'Authentication failed: $error';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    // 2. Extract tokens from widget or current browser URI parameters (including hash fragment)
    var token = widget.token ?? Uri.base.queryParameters['token'];
    var refreshToken =
        widget.refreshToken ?? Uri.base.queryParameters['refreshToken'];

    if ((token == null || token.isEmpty) && Uri.base.hasFragment) {
      final fragment = Uri.base.fragment;
      final qIndex = fragment.indexOf('?');
      if (qIndex != -1) {
        final queryStr = fragment.substring(qIndex + 1);
        final params = Uri.splitQueryString(queryStr);
        token ??= params['token'];
        refreshToken ??= params['refreshToken'];
      }
    }

    if (token == null || token.isEmpty) {
      setState(() {
        _hasError = true;
        _statusMessage = 'No authentication token received from Google callback.';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    try {
      // 3. Securely store application tokens
      final storage = ref.read(secureStorageProvider);
      await storage.saveAccessToken(token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await storage.saveRefreshToken(refreshToken);
      }

      setState(() {
        _statusMessage = 'Loading your HABos workspace...';
      });

      // 4. Update auth state and fetch user profile
      await ref.read(authProvider.notifier).checkAuthStatus();

      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        context.go('/');
      } else {
        setState(() {
          _hasError = true;
          _statusMessage = 'Failed to load profile. Redirecting to login...';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _statusMessage = 'Error completing sign-in: ${e.toString()}';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _hasError
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _hasError
                      ? Icon(
                          Icons.error_outline_rounded,
                          color: colorScheme.error,
                          size: 36,
                        )
                      : SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _hasError ? 'Authentication Notice' : 'Connecting to HABos',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: _hasError
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
