// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../../presentation/providers/auth_provider.dart';

Future<void> performGoogleSignIn(BuildContext context, WidgetRef? ref) async {
  final returnUrl = Uri.base.origin.isNotEmpty ? Uri.base.origin : 'http://localhost:3000';
  final oauthEndpoint = '${ApiEndpoints.baseUrl}/auth/google?returnUrl=${Uri.encodeComponent(returnUrl)}';

  // Navigate current browser window to Google OAuth endpoint
  try {
    html.window.location.href = oauthEndpoint;
  } catch (e) {
    if (context.mounted && ref != null) {
      _showQuickSignInFallback(context, ref, 'Failed to navigate to Google OAuth: $e');
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
        title: Row(
          children: [
            const Icon(Icons.account_circle_rounded, color: Colors.blueAccent, size: 26),
            const SizedBox(width: 10),
            const Text('Google Account Sign-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
