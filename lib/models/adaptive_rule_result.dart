class AdaptiveRuleResult {
  const AdaptiveRuleResult({
    this.screenTimeDelta = 0,
    this.rewardPointsDelta = 0,
    this.badgesToAdd = const [],
    this.insightMessages = const [],
    this.updatedCounters = const {},
    this.eventType = 'rule_update',
    this.eventData = const {},
  });

  static const none = AdaptiveRuleResult();

  final int screenTimeDelta;
  final int rewardPointsDelta;
  final List<String> badgesToAdd;
  final List<String> insightMessages;
  final Map<String, dynamic> updatedCounters;
  final String eventType;
  final Map<String, dynamic> eventData;

  bool get hasChanges =>
      screenTimeDelta != 0 ||
      rewardPointsDelta != 0 ||
      badgesToAdd.isNotEmpty ||
      insightMessages.isNotEmpty ||
      updatedCounters.isNotEmpty;
}
