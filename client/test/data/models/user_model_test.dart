import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/data/models/user_model.dart';
import 'package:habos_client/data/models/auth_tokens_model.dart';

void main() {
  group('UserModel', () {
    test('should parse from valid JSON correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'name': 'Test User',
        'avatarUrl': 'https://example.com/avatar.png',
        'timezone': 'UTC',
        'dateFormat': 'YYYY-MM-DD',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.timezone, 'UTC');
      expect(user.dateFormat, 'YYYY-MM-DD');
    });

    test('should support copyWith', () {
      const user = UserModel(
        id: '1',
        email: 'a@b.com',
        name: 'Alice',
        timezone: 'UTC',
        dateFormat: 'YYYY-MM-DD',
      );

      final updated = user.copyWith(name: 'Bob');

      expect(updated.id, '1');
      expect(updated.name, 'Bob');
      expect(updated.email, 'a@b.com');
    });
  });

  group('AuthTokensModel', () {
    test('should parse tokens correctly', () {
      final json = {
        'accessToken': 'jwt.access.token',
        'refreshToken': 'jwt.refresh.token',
        'expiresIn': '15m',
      };

      final tokens = AuthTokensModel.fromJson(json);

      expect(tokens.accessToken, 'jwt.access.token');
      expect(tokens.refreshToken, 'jwt.refresh.token');
      expect(tokens.expiresIn, '15m');
    });
  });
}
