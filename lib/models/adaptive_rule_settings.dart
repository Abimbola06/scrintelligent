class AdaptiveRuleSettings {
  const AdaptiveRuleSettings({
    required this.dailyScreenTimeLimitMinutes,
    required this.entertainmentThreshold1Minutes,
    required this.entertainmentThreshold2Minutes,
    required this.entertainmentThreshold3Minutes,
    required this.entertainmentPenalty1Minutes,
    required this.entertainmentPenalty2Minutes,
    required this.entertainmentPenalty3Minutes,
    required this.maxEntertainmentPenaltyMinutesPerDay,
    required this.educationSessionTargetMinutes,
    required this.educationFirstSessionRewardMinutes,
    required this.educationRepeatSessionRewardMinutes,
    required this.quizReward70To79Minutes,
    required this.quizReward80To89Minutes,
    required this.quizReward90PlusMinutes,
  });

  static const defaults = AdaptiveRuleSettings(
    dailyScreenTimeLimitMinutes: 120,
    entertainmentThreshold1Minutes: 30,
    entertainmentThreshold2Minutes: 60,
    entertainmentThreshold3Minutes: 90,
    entertainmentPenalty1Minutes: 5,
    entertainmentPenalty2Minutes: 10,
    entertainmentPenalty3Minutes: 15,
    maxEntertainmentPenaltyMinutesPerDay: 30,
    educationSessionTargetMinutes: 3,
    educationFirstSessionRewardMinutes: 5,
    educationRepeatSessionRewardMinutes: 10,
    quizReward70To79Minutes: 10,
    quizReward80To89Minutes: 15,
    quizReward90PlusMinutes: 20,
  );

  final int dailyScreenTimeLimitMinutes;
  final int entertainmentThreshold1Minutes;
  final int entertainmentThreshold2Minutes;
  final int entertainmentThreshold3Minutes;
  final int entertainmentPenalty1Minutes;
  final int entertainmentPenalty2Minutes;
  final int entertainmentPenalty3Minutes;
  final int maxEntertainmentPenaltyMinutesPerDay;
  final int educationSessionTargetMinutes;
  final int educationFirstSessionRewardMinutes;
  final int educationRepeatSessionRewardMinutes;
  final int quizReward70To79Minutes;
  final int quizReward80To89Minutes;
  final int quizReward90PlusMinutes;

  AdaptiveRuleSettings copyWith({
    int? dailyScreenTimeLimitMinutes,
    int? entertainmentThreshold1Minutes,
    int? entertainmentThreshold2Minutes,
    int? entertainmentThreshold3Minutes,
    int? entertainmentPenalty1Minutes,
    int? entertainmentPenalty2Minutes,
    int? entertainmentPenalty3Minutes,
    int? maxEntertainmentPenaltyMinutesPerDay,
    int? educationSessionTargetMinutes,
    int? educationFirstSessionRewardMinutes,
    int? educationRepeatSessionRewardMinutes,
    int? quizReward70To79Minutes,
    int? quizReward80To89Minutes,
    int? quizReward90PlusMinutes,
  }) {
    return AdaptiveRuleSettings(
      dailyScreenTimeLimitMinutes:
          dailyScreenTimeLimitMinutes ?? this.dailyScreenTimeLimitMinutes,
      entertainmentThreshold1Minutes: entertainmentThreshold1Minutes ??
          this.entertainmentThreshold1Minutes,
      entertainmentThreshold2Minutes: entertainmentThreshold2Minutes ??
          this.entertainmentThreshold2Minutes,
      entertainmentThreshold3Minutes: entertainmentThreshold3Minutes ??
          this.entertainmentThreshold3Minutes,
      entertainmentPenalty1Minutes: entertainmentPenalty1Minutes ??
          this.entertainmentPenalty1Minutes,
      entertainmentPenalty2Minutes: entertainmentPenalty2Minutes ??
          this.entertainmentPenalty2Minutes,
      entertainmentPenalty3Minutes: entertainmentPenalty3Minutes ??
          this.entertainmentPenalty3Minutes,
      maxEntertainmentPenaltyMinutesPerDay:
          maxEntertainmentPenaltyMinutesPerDay ??
              this.maxEntertainmentPenaltyMinutesPerDay,
      educationSessionTargetMinutes:
          educationSessionTargetMinutes ?? this.educationSessionTargetMinutes,
      educationFirstSessionRewardMinutes:
          educationFirstSessionRewardMinutes ??
              this.educationFirstSessionRewardMinutes,
      educationRepeatSessionRewardMinutes:
          educationRepeatSessionRewardMinutes ??
              this.educationRepeatSessionRewardMinutes,
      quizReward70To79Minutes:
          quizReward70To79Minutes ?? this.quizReward70To79Minutes,
      quizReward80To89Minutes:
          quizReward80To89Minutes ?? this.quizReward80To89Minutes,
      quizReward90PlusMinutes:
          quizReward90PlusMinutes ?? this.quizReward90PlusMinutes,
    );
  }

  AdaptiveRuleSettings normalize() {
    final threshold1 = entertainmentThreshold1Minutes < 1
        ? 1
        : entertainmentThreshold1Minutes;
    final threshold2 = entertainmentThreshold2Minutes < threshold1 + 1
        ? threshold1 + 1
        : entertainmentThreshold2Minutes;
    final threshold3 = entertainmentThreshold3Minutes < threshold2 + 1
        ? threshold2 + 1
        : entertainmentThreshold3Minutes;

    return AdaptiveRuleSettings(
      dailyScreenTimeLimitMinutes:
          dailyScreenTimeLimitMinutes < 1 ? 1 : dailyScreenTimeLimitMinutes,
      entertainmentThreshold1Minutes: threshold1,
      entertainmentThreshold2Minutes: threshold2,
      entertainmentThreshold3Minutes: threshold3,
      entertainmentPenalty1Minutes:
          entertainmentPenalty1Minutes < 0 ? 0 : entertainmentPenalty1Minutes,
      entertainmentPenalty2Minutes:
          entertainmentPenalty2Minutes < 0 ? 0 : entertainmentPenalty2Minutes,
      entertainmentPenalty3Minutes:
          entertainmentPenalty3Minutes < 0 ? 0 : entertainmentPenalty3Minutes,
      maxEntertainmentPenaltyMinutesPerDay:
          maxEntertainmentPenaltyMinutesPerDay < 0
              ? 0
              : maxEntertainmentPenaltyMinutesPerDay,
      educationSessionTargetMinutes:
          educationSessionTargetMinutes < 1 ? 1 : educationSessionTargetMinutes,
      educationFirstSessionRewardMinutes: educationFirstSessionRewardMinutes < 0
          ? 0
          : educationFirstSessionRewardMinutes,
      educationRepeatSessionRewardMinutes:
          educationRepeatSessionRewardMinutes < 0
              ? 0
              : educationRepeatSessionRewardMinutes,
      quizReward70To79Minutes:
          quizReward70To79Minutes < 0 ? 0 : quizReward70To79Minutes,
      quizReward80To89Minutes:
          quizReward80To89Minutes < 0 ? 0 : quizReward80To89Minutes,
      quizReward90PlusMinutes:
          quizReward90PlusMinutes < 0 ? 0 : quizReward90PlusMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyScreenTimeLimitMinutes': dailyScreenTimeLimitMinutes,
      'entertainmentThreshold1Minutes': entertainmentThreshold1Minutes,
      'entertainmentThreshold2Minutes': entertainmentThreshold2Minutes,
      'entertainmentThreshold3Minutes': entertainmentThreshold3Minutes,
      'entertainmentPenalty1Minutes': entertainmentPenalty1Minutes,
      'entertainmentPenalty2Minutes': entertainmentPenalty2Minutes,
      'entertainmentPenalty3Minutes': entertainmentPenalty3Minutes,
      'maxEntertainmentPenaltyMinutesPerDay':
          maxEntertainmentPenaltyMinutesPerDay,
      'educationSessionTargetMinutes': educationSessionTargetMinutes,
      'educationFirstSessionRewardMinutes':
          educationFirstSessionRewardMinutes,
      'educationRepeatSessionRewardMinutes':
          educationRepeatSessionRewardMinutes,
      'quizReward70To79Minutes': quizReward70To79Minutes,
      'quizReward80To89Minutes': quizReward80To89Minutes,
      'quizReward90PlusMinutes': quizReward90PlusMinutes,
    };
  }

  factory AdaptiveRuleSettings.fromMap(Map<String, dynamic> map) {
    return AdaptiveRuleSettings(
      dailyScreenTimeLimitMinutes:
          map['dailyScreenTimeLimitMinutes'] as int? ??
              defaults.dailyScreenTimeLimitMinutes,
      entertainmentThreshold1Minutes:
          map['entertainmentThreshold1Minutes'] as int? ??
              defaults.entertainmentThreshold1Minutes,
      entertainmentThreshold2Minutes:
          map['entertainmentThreshold2Minutes'] as int? ??
              defaults.entertainmentThreshold2Minutes,
      entertainmentThreshold3Minutes:
          map['entertainmentThreshold3Minutes'] as int? ??
              defaults.entertainmentThreshold3Minutes,
      entertainmentPenalty1Minutes:
          map['entertainmentPenalty1Minutes'] as int? ??
              defaults.entertainmentPenalty1Minutes,
      entertainmentPenalty2Minutes:
          map['entertainmentPenalty2Minutes'] as int? ??
              defaults.entertainmentPenalty2Minutes,
      entertainmentPenalty3Minutes:
          map['entertainmentPenalty3Minutes'] as int? ??
              defaults.entertainmentPenalty3Minutes,
      maxEntertainmentPenaltyMinutesPerDay:
          map['maxEntertainmentPenaltyMinutesPerDay'] as int? ??
              defaults.maxEntertainmentPenaltyMinutesPerDay,
      educationSessionTargetMinutes:
          map['educationSessionTargetMinutes'] as int? ??
              defaults.educationSessionTargetMinutes,
      educationFirstSessionRewardMinutes:
          map['educationFirstSessionRewardMinutes'] as int? ??
              defaults.educationFirstSessionRewardMinutes,
      educationRepeatSessionRewardMinutes:
          map['educationRepeatSessionRewardMinutes'] as int? ??
              defaults.educationRepeatSessionRewardMinutes,
      quizReward70To79Minutes: map['quizReward70To79Minutes'] as int? ??
          defaults.quizReward70To79Minutes,
      quizReward80To89Minutes: map['quizReward80To89Minutes'] as int? ??
          defaults.quizReward80To89Minutes,
      quizReward90PlusMinutes: map['quizReward90PlusMinutes'] as int? ??
          defaults.quizReward90PlusMinutes,
    ).normalize();
  }
}
