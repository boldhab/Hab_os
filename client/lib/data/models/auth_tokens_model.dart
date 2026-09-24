import 'package:equatable/equatable.dart';

class AuthTokensModel extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresIn: json['expiresIn'] ?? '15m',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}
