import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _themeModeKey = 'theme_mode';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(key: _themeModeKey, value: themeMode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeModeKey);
  }

  static const String _activeTimerKey = 'active_focus_timer';

  Future<void> saveActiveTimer(String json) async {
    await _storage.write(key: _activeTimerKey, value: json);
  }

  Future<String?> getActiveTimer() async {
    return await _storage.read(key: _activeTimerKey);
  }

  Future<void> clearActiveTimer() async {
    await _storage.delete(key: _activeTimerKey);
  }

  Future<void> saveBoolSetting(String key, bool value) async {
    await _storage.write(key: 'setting_$key', value: value.toString());
  }

  Future<bool?> getBoolSetting(String key) async {
    final val = await _storage.read(key: 'setting_$key');
    if (val == null) return null;
    return val == 'true';
  }

  Future<void> saveStringSetting(String key, String value) async {
    await _storage.write(key: 'setting_$key', value: value);
  }

  Future<String?> getStringSetting(String key) async {
    return await _storage.read(key: 'setting_$key');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
