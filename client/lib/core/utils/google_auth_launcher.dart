import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/api_endpoints.dart';

// Conditional import: use dart:html on web, stub on native
import 'google_auth_launcher_stub.dart'
    if (dart.library.html) 'google_auth_launcher_web.dart' as platform;

class GoogleAuthLauncher {
  /// Launches the real Google OAuth 2.0 / OpenID Connect authorization flow
  /// by navigating the current browser window to the backend OAuth initiation endpoint.
  static Future<void> launch(BuildContext context) async {
    final returnUrl = Uri.base.origin.isNotEmpty ? Uri.base.origin : 'http://localhost:3000';
    final oauthEndpoint = '${ApiEndpoints.baseUrl}/auth/google?returnUrl=${Uri.encodeComponent(returnUrl)}';

    try {
      if (kIsWeb) {
        platform.navigateToUrl(oauthEndpoint);
      } else {
        // For native platforms, show a message (not supported in this web-only flow)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign-in is only available on the web version.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start Google sign-in: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
