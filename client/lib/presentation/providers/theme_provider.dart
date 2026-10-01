import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/utils/app_haptics.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeNotifier(storage);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService _storage;

  ThemeNotifier(this._storage) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final saved = await _storage.getThemeMode();
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    AppHaptics.selection();
    state = mode;
    final modeStr = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await _storage.saveThemeMode(modeStr);
  }

  Future<void> toggleTheme(BuildContext context) async {
    AppHaptics.selection();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}
