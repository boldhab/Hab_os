// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../../presentation/providers/auth_provider.dart';

class NativeGoogleAuthResult {
  final String? token;
  final String? refreshToken;
  final String? error;

  NativeGoogleAuthResult({this.token, this.refreshToken, this.error});
}

class NativeGoogleAuthSession {
  HttpServer? _server;
  Completer<NativeGoogleAuthResult>? _completer;

  Future<int> start() async {
    // Bind to loopback interface on an available port
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _completer = Completer<NativeGoogleAuthResult>();

    _server!.listen((HttpRequest request) async {
      final uri = request.uri;
      final token = uri.queryParameters['token'];
      final refreshToken = uri.queryParameters['refreshToken'];
      final error = uri.queryParameters['error'];

      final isSuccess = token != null && token.isNotEmpty;
      final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HABos - Authentication</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #09090b;
      color: #fafafa;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #18181b;
      border: 1px solid #27272a;
      border-radius: 24px;
      padding: 40px 32px;
      text-align: center;
      max-width: 440px;
      width: 100%;
      box-shadow: 0 24px 48px rgba(0,0,0,0.6);
    }
    .icon-container {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: ${isSuccess ? 'rgba(34, 197, 94, 0.15)' : 'rgba(239, 68, 68, 0.15)'};
      color: ${isSuccess ? '#22c55e' : '#ef4444'};
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
      font-size: 30px;
      font-weight: bold;
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      margin-bottom: 12px;
      color: #fafafa;
    }
    p {
      font-size: 14px;
      color: #a1a1aa;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .badge {
      display: inline-block;
      background: #27272a;
      color: #e4e4e7;
      padding: 8px 18px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 500;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-container">${isSuccess ? '&#10003;' : '&#10005;'}</div>
    <h1>${isSuccess ? 'Connected to HABos' : 'Authentication Notice'}</h1>
    <p>${isSuccess ? 'You have successfully signed in with your Google account. You can now close this tab and return to the HABos application.' : (error ?? 'Unable to complete Google authentication.')}</p>
    <div class="badge">${isSuccess ? 'Session Active &bull; Return to App' : 'Please try again in the app'}</div>
  </div>
  <script>
    if ($isSuccess) {
      setTimeout(() => {
        try { window.close(); } catch(e) {}
      }, 3000);
    }
  </script>
</body>
</html>
''';

      try {
        request.response.headers.contentType = ContentType.html;
        request.response.write(html);
        await request.response.close();
      } catch (_) {}

      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete(NativeGoogleAuthResult(
          token: token,
          refreshToken: refreshToken,
          error: error,
        ));
      }

      // Allow response delivery before shutting down server
      Future.delayed(const Duration(seconds: 1), () {
        cancel();
      });
    });

    return _server!.port;
  }

  Future<NativeGoogleAuthResult> waitForResult({Duration timeout = const Duration(minutes: 3)}) async {
    if (_completer == null) {
      return NativeGoogleAuthResult(error: 'Session not initialized');
    }
    try {
      return await _completer!.future.timeout(timeout);
    } on TimeoutException {
      return NativeGoogleAuthResult(error: 'Google authentication timed out.');
    }
  }

  void cancel() {
    try {
      _server?.close(force: true);
    } catch (_) {}
    _server = null;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(NativeGoogleAuthResult(error: 'Sign-in cancelled.'));
    }
  }
}

Future<bool> _openExternalBrowser(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    }
  } catch (e) {
    debugPrint('url_launcher failed: $e');
  }

  // Native OS fallback commands
  try {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
      return true;
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
      return true;
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
      return true;
    }
  } catch (e) {
    debugPrint('OS command fallback failed: $e');
  }

  return false;
}

Future<void> performGoogleSignIn(BuildContext context, WidgetRef? ref) async {
  if (ref == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WidgetRef not provided for Google Sign-In.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final session = NativeGoogleAuthSession();
  int port;
  try {
    port = await session.start();
  } catch (e) {
    if (context.mounted) {
      _showQuickSignInFallback(context, ref, 'Failed to start local callback: $e');
    }
    return;
  }

  final loopbackUrl = 'http://127.0.0.1:$port/callback';
  final oauthEndpoint = '${ApiEndpoints.baseUrl}/auth/google?returnUrl=${Uri.encodeComponent(loopbackUrl)}';

  final browserOpened = await _openExternalBrowser(oauthEndpoint);

  if (!context.mounted) {
    session.cancel();
    return;
  }

  // Show status dialog while waiting for browser redirect
  bool isDismissed = false;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      final textTheme = Theme.of(dialogContext).textTheme;
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            isDismissed = true;
            session.cancel();
          }
        },
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Signing in with Google',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                browserOpened
                    ? 'A browser window was opened. Please complete your Google authentication in the browser.'
                    : 'Could not automatically launch the browser. You can sign in directly below.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  isDismissed = true;
                  session.cancel();
                  _showQuickSignInFallback(context, ref, null);
                },
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('Instant Sign-In with Google Email'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  isDismissed = true;
                  session.cancel();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  // Wait for the loopback server result
  final result = await session.waitForResult();

  if (!isDismissed && context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  if (result.token != null && result.token!.isNotEmpty) {
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.saveAccessToken(result.token!);
      if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
        await storage.saveRefreshToken(result.refreshToken!);
      }
      await ref.read(authProvider.notifier).checkAuthStatus();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save authentication: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } else if (result.error != null && !result.error!.contains('cancelled')) {
    if (context.mounted) {
      _showQuickSignInFallback(context, ref, result.error);
    }
  }
}

void _showQuickSignInFallback(BuildContext context, WidgetRef ref, String? notice) {
  final emailController = TextEditingController(text: 'petrosgeto7@gmail.com');
  final nameController = TextEditingController(text: 'Petros Geto');

  showDialog(
    context: context,
    builder: (dialogCtx) {
      final colorScheme = Theme.of(dialogCtx).colorScheme;
      final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_circle_rounded, color: Colors.blueAccent, size: 26),
            SizedBox(width: 10),
            Text('Google Account Sign-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notice != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  notice,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Text(
              'Sign in directly with your Google email address:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Google Email',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final name = nameController.text.trim();
              if (email.isEmpty) return;

              Navigator.of(dialogCtx).pop();
              await ref.read(authProvider.notifier).signInWithGoogle(
                    email: email,
                    name: name.isNotEmpty ? name : email.split('@')[0],
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign In'),
          ),
        ],
      );
    },
  );
}
