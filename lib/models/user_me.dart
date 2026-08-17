enum InterfaceLocale {
  en,
  ja;

  static InterfaceLocale fromJson(String value) =>
      InterfaceLocale.values.firstWhere(
        (e) => e.name == value,
        orElse: () => InterfaceLocale.en,
      );

  String toJson() => name;
}

enum AnswerLanguageMode {
  interface,
  source;

  static AnswerLanguageMode fromJson(String value) =>
      AnswerLanguageMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AnswerLanguageMode.interface,
      );

  String toJson() => name;
}

class UserPreferences {
  const UserPreferences({
    required this.interfaceLocale,
    required this.answerLanguageMode,
    required this.notifyReadLaterDigest,
    required this.notifyWeeklyStats,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      interfaceLocale: InterfaceLocale.fromJson(
        json['interfaceLocale'] as String,
      ),
      answerLanguageMode: AnswerLanguageMode.fromJson(
        json['answerLanguageMode'] as String,
      ),
      notifyReadLaterDigest: json['notifyReadLaterDigest'] as bool,
      notifyWeeklyStats: json['notifyWeeklyStats'] as bool,
    );
  }

  final InterfaceLocale interfaceLocale;
  final AnswerLanguageMode answerLanguageMode;
  final bool notifyReadLaterDigest;
  final bool notifyWeeklyStats;

  UserPreferences copyWith({
    InterfaceLocale? interfaceLocale,
    AnswerLanguageMode? answerLanguageMode,
    bool? notifyReadLaterDigest,
    bool? notifyWeeklyStats,
  }) {
    return UserPreferences(
      interfaceLocale: interfaceLocale ?? this.interfaceLocale,
      answerLanguageMode: answerLanguageMode ?? this.answerLanguageMode,
      notifyReadLaterDigest:
          notifyReadLaterDigest ?? this.notifyReadLaterDigest,
      notifyWeeklyStats: notifyWeeklyStats ?? this.notifyWeeklyStats,
    );
  }
}

class UserMe {
  const UserMe({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.preferences,
  });

  factory UserMe.fromJson(Map<String, dynamic> json) {
    return UserMe(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
    );
  }

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final UserPreferences preferences;
}
