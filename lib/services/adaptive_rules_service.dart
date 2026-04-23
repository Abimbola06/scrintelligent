import '../models/adaptive_rule_result.dart';
import '../models/adaptive_rule_settings.dart';
import '../models/child_usage_model.dart';

class AdaptiveRulesService {
  static const String quickLearnerBadge = 'Quick Learner';
  static const int _maxStoredInsightMessages = 30;
  static const int _maxStoredRuleEvents = 50;

  AdaptiveRuleResult evaluateQuizRule({
    required int score,
    required int total,
    required AdaptiveRuleSettings settings,
  }) {
    if (total <= 0) {
      return AdaptiveRuleResult.none;
    }

    final percentage = (score / total) * 100;
    final normalizedSettings = settings.normalize();

    if (percentage >= 90) {
      return AdaptiveRuleResult(
        screenTimeDelta: normalizedSettings.quizReward90PlusMinutes,
        rewardPointsDelta: normalizedSettings.quizReward90PlusMinutes,
        badgesToAdd: [quickLearnerBadge],
        eventType: 'quiz_reward',
        eventData: const {'band': '90_plus'},
        insightMessages: [
          'Excellent quiz performance earned '
              '${normalizedSettings.quizReward90PlusMinutes} extra minutes.',
        ],
      );
    }

    if (percentage >= 80) {
      return AdaptiveRuleResult(
        screenTimeDelta: normalizedSettings.quizReward80To89Minutes,
        rewardPointsDelta: normalizedSettings.quizReward80To89Minutes,
        eventType: 'quiz_reward',
        eventData: const {'band': '80_to_89'},
        insightMessages: [
          'Strong quiz performance earned '
              '${normalizedSettings.quizReward80To89Minutes} extra minutes.',
        ],
      );
    }

    if (percentage >= 70) {
      return AdaptiveRuleResult(
        screenTimeDelta: normalizedSettings.quizReward70To79Minutes,
        rewardPointsDelta: normalizedSettings.quizReward70To79Minutes,
        eventType: 'quiz_reward',
        eventData: const {'band': '70_to_79'},
        insightMessages: [
          'Good quiz performance earned '
              '${normalizedSettings.quizReward70To79Minutes} extra minutes.',
        ],
      );
    }

    return const AdaptiveRuleResult(
      eventType: 'quiz_completed',
      eventData: {'band': 'below_70'},
      insightMessages: [
        'Quiz completed. Keep practising to unlock bonus time.',
      ],
    );
  }

  AdaptiveRuleResult evaluateEntertainmentRule({
    required ChildUsageModel usage,
    required AdaptiveRuleSettings settings,
  }) {
    final normalizedSettings = settings.normalize();

    if (usage.penaltyMinutesToday >=
        normalizedSettings.maxEntertainmentPenaltyMinutesPerDay) {
      return AdaptiveRuleResult.none;
    }

    if (usage.entertainmentMinutesToday >
            normalizedSettings.entertainmentThreshold3Minutes &&
        usage.entertainmentWarningsToday == 2) {
      return _buildEntertainmentPenaltyResult(
        usage: usage,
        penaltyMinutes: normalizedSettings.entertainmentPenalty3Minutes,
        warningCount: 3,
        message:
            'Entertainment passed '
            '${normalizedSettings.entertainmentThreshold3Minutes} minutes today, '
            'so ${normalizedSettings.entertainmentPenalty3Minutes} minutes were reduced.',
        maxPenaltyMinutesPerDay:
            normalizedSettings.maxEntertainmentPenaltyMinutesPerDay,
      );
    }

    if (usage.entertainmentMinutesToday >
            normalizedSettings.entertainmentThreshold2Minutes &&
        usage.entertainmentWarningsToday == 1) {
      return _buildEntertainmentPenaltyResult(
        usage: usage,
        penaltyMinutes: normalizedSettings.entertainmentPenalty2Minutes,
        warningCount: 2,
        message:
            'Entertainment passed '
            '${normalizedSettings.entertainmentThreshold2Minutes} minutes today, '
            'so ${normalizedSettings.entertainmentPenalty2Minutes} minutes were reduced.',
        maxPenaltyMinutesPerDay:
            normalizedSettings.maxEntertainmentPenaltyMinutesPerDay,
      );
    }

    if (usage.entertainmentMinutesToday >
            normalizedSettings.entertainmentThreshold1Minutes &&
        usage.entertainmentWarningsToday == 0) {
      return _buildEntertainmentPenaltyResult(
        usage: usage,
        penaltyMinutes: normalizedSettings.entertainmentPenalty1Minutes,
        warningCount: 1,
        message:
            'Entertainment passed '
            '${normalizedSettings.entertainmentThreshold1Minutes} minutes today, '
            'so ${normalizedSettings.entertainmentPenalty1Minutes} minutes were reduced.',
        maxPenaltyMinutesPerDay:
            normalizedSettings.maxEntertainmentPenaltyMinutesPerDay,
      );
    }

    return AdaptiveRuleResult.none;
  }

  AdaptiveRuleResult evaluateEducationRule({
    required ChildUsageModel usage,
    required AdaptiveRuleSettings settings,
  }) {
    final normalizedSettings = settings.normalize();

    if (usage.educationStreakMinutes <
        normalizedSettings.educationSessionTargetMinutes) {
      return AdaptiveRuleResult.none;
    }

    final isFirstEducationSession = usage.educationSessionsToday == 0;
    final rewardMinutes = isFirstEducationSession
        ? normalizedSettings.educationFirstSessionRewardMinutes
        : normalizedSettings.educationRepeatSessionRewardMinutes;

    return AdaptiveRuleResult(
      eventType: 'education_reward',
      screenTimeDelta: rewardMinutes,
      rewardPointsDelta: rewardMinutes,
      insightMessages: [
        isFirstEducationSession
            ? 'First education session completed, earning '
                '${normalizedSettings.educationFirstSessionRewardMinutes} bonus minutes.'
            : 'Another education session completed, earning '
                '${normalizedSettings.educationRepeatSessionRewardMinutes} bonus minutes.',
      ],
      updatedCounters: {
        'educationSessionsToday': usage.educationSessionsToday + 1,
        'educationStreakMinutes': 0,
      },
    );
  }

  ChildUsageModel applyRuleResult({
    required ChildUsageModel usage,
    required AdaptiveRuleResult result,
  }) {
    if (!result.hasChanges) {
      return usage;
    }

    final updatedBadges = List<String>.from(usage.badges);
    for (final badge in result.badgesToAdd) {
      if (!updatedBadges.contains(badge)) {
        updatedBadges.add(badge);
      }
    }

    final updatedInsightMessages = [
      ...usage.insightMessages,
      ...result.insightMessages,
    ];
    final trimmedInsightMessages = updatedInsightMessages.length >
            _maxStoredInsightMessages
        ? updatedInsightMessages
            .sublist(updatedInsightMessages.length - _maxStoredInsightMessages)
        : updatedInsightMessages;
    final updatedRuleEvents = _appendRuleEvent(
      usage: usage,
      result: result,
    );
    final updatedScreenTime =
        usage.screenTimeRemaining + result.screenTimeDelta;
    final updatedBonusMinutes = result.screenTimeDelta > 0
        ? usage.bonusMinutesToday + result.screenTimeDelta
        : usage.bonusMinutesToday;
    final updatedPenaltyMinutes = result.screenTimeDelta < 0
        ? usage.penaltyMinutesToday + result.screenTimeDelta.abs()
        : usage.penaltyMinutesToday;

    final updatedUsage = usage.copyWith(
      screenTimeRemaining: updatedScreenTime < 0 ? 0 : updatedScreenTime,
      rewardPoints: usage.rewardPoints + result.rewardPointsDelta,
      badges: updatedBadges,
      bonusMinutesToday: updatedBonusMinutes,
      penaltyMinutesToday: updatedPenaltyMinutes,
      insightMessages: trimmedInsightMessages,
      ruleEvents: updatedRuleEvents,
    );

    return _applyUpdatedCounters(
      usage: updatedUsage,
      counters: result.updatedCounters,
    );
  }

  ChildUsageModel applyRuleResults({
    required ChildUsageModel usage,
    required AdaptiveRuleResult result,
  }) {
    return applyRuleResult(
      usage: usage,
      result: result,
    );
  }

  ChildUsageModel _applyUpdatedCounters({
    required ChildUsageModel usage,
    required Map<String, dynamic> counters,
  }) {
    if (counters.isEmpty) {
      return usage;
    }

    return usage.copyWith(
      educationSessionsToday: counters['educationSessionsToday'] as int? ??
          usage.educationSessionsToday,
      educationStreakMinutes: counters['educationStreakMinutes'] as int? ??
          usage.educationStreakMinutes,
      entertainmentMinutesToday: counters['entertainmentMinutesToday'] as int? ??
          usage.entertainmentMinutesToday,
      entertainmentWarningsToday:
          counters['entertainmentWarningsToday'] as int? ??
              usage.entertainmentWarningsToday,
      penaltyMinutesToday: counters['penaltyMinutesToday'] as int? ??
          usage.penaltyMinutesToday,
      bonusMinutesToday: counters['bonusMinutesToday'] as int? ??
          usage.bonusMinutesToday,
    );
  }

  AdaptiveRuleResult _buildEntertainmentPenaltyResult({
    required ChildUsageModel usage,
    required int penaltyMinutes,
    required int warningCount,
    required String message,
    required int maxPenaltyMinutesPerDay,
  }) {
    final remainingPenaltyAllowance =
        maxPenaltyMinutesPerDay - usage.penaltyMinutesToday;
    final appliedPenalty = penaltyMinutes > remainingPenaltyAllowance
        ? remainingPenaltyAllowance
        : penaltyMinutes;

    if (appliedPenalty <= 0) {
      return AdaptiveRuleResult.none;
    }

    return AdaptiveRuleResult(
      eventType: 'entertainment_penalty',
      screenTimeDelta: -appliedPenalty,
      insightMessages: [message],
      updatedCounters: {
        'entertainmentWarningsToday': warningCount,
      },
    );
  }

  List<Map<String, dynamic>> _appendRuleEvent({
    required ChildUsageModel usage,
    required AdaptiveRuleResult result,
  }) {
    if (!result.hasChanges) {
      return usage.ruleEvents;
    }

    final eventMessage = result.insightMessages.isEmpty
        ? 'Adaptive rule applied.'
        : result.insightMessages.first;
    final event = <String, dynamic>{
      'type': result.eventType,
      'message': eventMessage,
      'screenTimeDelta': result.screenTimeDelta,
      'rewardPointsDelta': result.rewardPointsDelta,
      'badgesAdded': result.badgesToAdd,
      'eventData': result.eventData,
      'createdAt': DateTime.now().toIso8601String(),
    };
    final updated = [
      ...usage.ruleEvents,
      event,
    ];

    if (updated.length <= _maxStoredRuleEvents) {
      return updated;
    }

    return updated.sublist(updated.length - _maxStoredRuleEvents);
  }
}
