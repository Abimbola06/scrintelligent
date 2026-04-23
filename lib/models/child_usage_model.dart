class ChildUsageModel {
  const ChildUsageModel({
    required this.screenTimeRemaining,
    required this.dailyUsage,
    required this.activityCategory,
    required this.rewardPoints,
    required this.badges,
    required this.quizHistory,
    required this.educationSessionsToday,
    required this.educationStreakMinutes,
    required this.educationMinutesToday,
    required this.entertainmentMinutesToday,
    required this.socialMinutesToday,
    required this.neutralMinutesToday,
    required this.entertainmentWarningsToday,
    required this.penaltyMinutesToday,
    required this.bonusMinutesToday,
    required this.insightMessages,
    required this.ruleEvents,
    this.updatedAt,
  });

  static const defaults = ChildUsageModel(
    screenTimeRemaining: 120,
    dailyUsage: 0,
    activityCategory: 'Neutral',
    rewardPoints: 0,
    badges: [],
    quizHistory: [],
    educationSessionsToday: 0,
    educationStreakMinutes: 0,
    educationMinutesToday: 0,
    entertainmentMinutesToday: 0,
    socialMinutesToday: 0,
    neutralMinutesToday: 0,
    entertainmentWarningsToday: 0,
    penaltyMinutesToday: 0,
    bonusMinutesToday: 0,
    insightMessages: [],
    ruleEvents: [],
  );

  final int screenTimeRemaining;
  final int dailyUsage;
  final String activityCategory;
  final int rewardPoints;
  final List<String> badges;
  final List<Map<String, dynamic>> quizHistory;
  final int educationSessionsToday;
  final int educationStreakMinutes;
  final int educationMinutesToday;
  final int entertainmentMinutesToday;
  final int socialMinutesToday;
  final int neutralMinutesToday;
  final int entertainmentWarningsToday;
  final int penaltyMinutesToday;
  final int bonusMinutesToday;
  final List<String> insightMessages;
  final List<Map<String, dynamic>> ruleEvents;
  final DateTime? updatedAt;

  ChildUsageModel copyWith({
    int? screenTimeRemaining,
    int? dailyUsage,
    String? activityCategory,
    int? rewardPoints,
    List<String>? badges,
    List<Map<String, dynamic>>? quizHistory,
    int? educationSessionsToday,
    int? educationStreakMinutes,
    int? educationMinutesToday,
    int? entertainmentMinutesToday,
    int? socialMinutesToday,
    int? neutralMinutesToday,
    int? entertainmentWarningsToday,
    int? penaltyMinutesToday,
    int? bonusMinutesToday,
    List<String>? insightMessages,
    List<Map<String, dynamic>>? ruleEvents,
    DateTime? updatedAt,
  }) {
    return ChildUsageModel(
      screenTimeRemaining:
          screenTimeRemaining ?? this.screenTimeRemaining,
      dailyUsage: dailyUsage ?? this.dailyUsage,
      activityCategory: activityCategory ?? this.activityCategory,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      badges: badges ?? this.badges,
      quizHistory: quizHistory ?? this.quizHistory,
      educationSessionsToday:
          educationSessionsToday ?? this.educationSessionsToday,
      educationStreakMinutes:
          educationStreakMinutes ?? this.educationStreakMinutes,
      educationMinutesToday:
          educationMinutesToday ?? this.educationMinutesToday,
      entertainmentMinutesToday:
          entertainmentMinutesToday ?? this.entertainmentMinutesToday,
      socialMinutesToday: socialMinutesToday ?? this.socialMinutesToday,
      neutralMinutesToday: neutralMinutesToday ?? this.neutralMinutesToday,
      entertainmentWarningsToday:
          entertainmentWarningsToday ?? this.entertainmentWarningsToday,
      penaltyMinutesToday: penaltyMinutesToday ?? this.penaltyMinutesToday,
      bonusMinutesToday: bonusMinutesToday ?? this.bonusMinutesToday,
      insightMessages: insightMessages ?? this.insightMessages,
      ruleEvents: ruleEvents ?? this.ruleEvents,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'screenTimeRemaining': screenTimeRemaining,
      'dailyUsage': dailyUsage,
      'activityCategory': activityCategory,
      'rewardPoints': rewardPoints,
      'badges': badges,
      'quizHistory': quizHistory,
      'educationSessionsToday': educationSessionsToday,
      'educationStreakMinutes': educationStreakMinutes,
      'educationMinutesToday': educationMinutesToday,
      'entertainmentMinutesToday': entertainmentMinutesToday,
      'socialMinutesToday': socialMinutesToday,
      'neutralMinutesToday': neutralMinutesToday,
      'entertainmentWarningsToday': entertainmentWarningsToday,
      'penaltyMinutesToday': penaltyMinutesToday,
      'bonusMinutesToday': bonusMinutesToday,
      'insightMessages': insightMessages,
      'ruleEvents': ruleEvents,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChildUsageModel.fromMap(Map<String, dynamic> map) {
    return ChildUsageModel(
      screenTimeRemaining: map['screenTimeRemaining'] as int? ??
          defaults.screenTimeRemaining,
      dailyUsage: map['dailyUsage'] as int? ?? defaults.dailyUsage,
      activityCategory: map['activityCategory'] as String? ??
          defaults.activityCategory,
      rewardPoints: map['rewardPoints'] as int? ?? defaults.rewardPoints,
      badges: List<String>.from(map['badges'] as List? ?? defaults.badges),
      quizHistory: List<Map<String, dynamic>>.from(
        (map['quizHistory'] as List? ?? defaults.quizHistory).map(
          (quiz) => Map<String, dynamic>.from(quiz as Map),
        ),
      ),
      educationSessionsToday: map['educationSessionsToday'] as int? ??
          defaults.educationSessionsToday,
      educationStreakMinutes: map['educationStreakMinutes'] as int? ??
          defaults.educationStreakMinutes,
      educationMinutesToday: map['educationMinutesToday'] as int? ??
          defaults.educationMinutesToday,
      entertainmentMinutesToday: map['entertainmentMinutesToday'] as int? ??
          defaults.entertainmentMinutesToday,
      socialMinutesToday: map['socialMinutesToday'] as int? ??
          defaults.socialMinutesToday,
      neutralMinutesToday: map['neutralMinutesToday'] as int? ??
          defaults.neutralMinutesToday,
      entertainmentWarningsToday: map['entertainmentWarningsToday'] as int? ??
          defaults.entertainmentWarningsToday,
      penaltyMinutesToday: map['penaltyMinutesToday'] as int? ??
          defaults.penaltyMinutesToday,
      bonusMinutesToday: map['bonusMinutesToday'] as int? ??
          defaults.bonusMinutesToday,
      insightMessages: List<String>.from(
        map['insightMessages'] as List? ?? defaults.insightMessages,
      ),
      ruleEvents: List<Map<String, dynamic>>.from(
        (map['ruleEvents'] as List? ?? defaults.ruleEvents).map(
          (event) => Map<String, dynamic>.from(event as Map),
        ),
      ),
      updatedAt: _dateTimeFromMapValue(map['updatedAt']),
    );
  }

  static DateTime? _dateTimeFromMapValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
