import 'package:equatable/equatable.dart';

class UserPreferenceModel extends Equatable {
  final List<String>? dashboardModules;
  final int dailyCodingTargetMins;
  final int dailyStudyTargetMins;
  final int dailyReadingTargetMins;
  final int weeklyGymTarget;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final Map<String, dynamic>? lifeScoreWeights;

  const UserPreferenceModel({
    this.dashboardModules,
    required this.dailyCodingTargetMins,
    required this.dailyStudyTargetMins,
    required this.dailyReadingTargetMins,
    required this.weeklyGymTarget,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.lifeScoreWeights,
  });

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserPreferenceModel(
      dashboardModules: json['dashboardModules'] != null
          ? List<String>.from(json['dashboardModules'])
          : null,
      dailyCodingTargetMins: json['dailyCodingTargetMins'] ?? 120,
      dailyStudyTargetMins: json['dailyStudyTargetMins'] ?? 120,
      dailyReadingTargetMins: json['dailyReadingTargetMins'] ?? 30,
      weeklyGymTarget: json['weeklyGymTarget'] ?? 4,
      quietHoursStart: json['quietHoursStart'],
      quietHoursEnd: json['quietHoursEnd'],
      lifeScoreWeights: json['lifeScoreWeights'] != null
          ? Map<String, dynamic>.from(json['lifeScoreWeights'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dashboardModules': dashboardModules,
      'dailyCodingTargetMins': dailyCodingTargetMins,
      'dailyStudyTargetMins': dailyStudyTargetMins,
      'dailyReadingTargetMins': dailyReadingTargetMins,
      'weeklyGymTarget': weeklyGymTarget,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'lifeScoreWeights': lifeScoreWeights,
    };
  }

  @override
  List<Object?> get props => [
        dashboardModules,
        dailyCodingTargetMins,
        dailyStudyTargetMins,
        dailyReadingTargetMins,
        weeklyGymTarget,
        quietHoursStart,
        quietHoursEnd,
        lifeScoreWeights,
      ];
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? bio;
  final String? avatarUrl;
  final String timezone;
  final String dateFormat;
  final UserPreferenceModel? preferences;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.bio,
    this.avatarUrl,
    required this.timezone,
    required this.dateFormat,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      timezone: json['timezone'] ?? 'UTC',
      dateFormat: json['dateFormat'] ?? 'YYYY-MM-DD',
      preferences: json['preferences'] != null
          ? UserPreferenceModel.fromJson(
              Map<String, dynamic>.from(json['preferences']),
            )
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? avatarUrl,
    String? timezone,
    String? dateFormat,
    UserPreferenceModel? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'timezone': timezone,
      'dateFormat': dateFormat,
      'preferences': preferences?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        bio,
        avatarUrl,
        timezone,
        dateFormat,
        preferences,
      ];
}
