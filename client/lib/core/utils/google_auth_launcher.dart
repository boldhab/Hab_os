import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Conditional imports across Web, Native (Desktop/Mobile), and Stub
import 'google_auth_launcher_stub.dart'
    if (dart.library.html) 'google_auth_launcher_web.dart'
    if (dart.library.io) 'google_auth_launcher_native.dart' as platform;

class GoogleAuthLauncher {
  /// Launches Google authentication flow on Web or Native platforms
  static Future<void> launch(BuildContext context, {WidgetRef? ref}) async {
    try {
      await platform.performGoogleSignIn(context, ref);
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
