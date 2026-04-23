import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/adaptive_rule_settings.dart';
import '../models/child_usage_model.dart';
import '../services/activity_classifier_service.dart';
import '../services/adaptive_rules_service.dart';
import '../services/firestore_service.dart';

class ScreenTimeManager extends ChangeNotifier {
  static const bool isFastTickMode = bool.fromEnvironment(
    'SCRINTELLIGENT_FAST_TICKS',
  );

  ScreenTimeManager({
    FirestoreService? firestoreService,
    Duration? tickInterval,
    int minutesPerTick = 1,
    ActivityCategory initialActivityCategory = ActivityCategory.neutral,
    VoidCallback? onTimeLimitReached,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _adaptiveRulesService = AdaptiveRulesService(),
        _tickInterval = tickInterval ??
            (isFastTickMode
                ? const Duration(seconds: 5)
                : const Duration(seconds: 60)),
        _minutesPerTick = minutesPerTick,
        _currentActivityCategory = initialActivityCategory,
        _onTimeLimitReached = onTimeLimitReached;

  final FirestoreService _firestoreService;
  final AdaptiveRulesService _adaptiveRulesService;
  final Duration _tickInterval;
  final int _minutesPerTick;
  final VoidCallback? _onTimeLimitReached;
  ActivityCategory _currentActivityCategory;

  Timer? _timer;
  String? _childUid;
  bool _isSaving = false;
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isDisposed = false;
  AdaptiveRuleSettings _ruleSettings = AdaptiveRuleSettings.defaults;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  ActivityCategory get currentActivityCategory => _currentActivityCategory;

  void setActivityCategory(ActivityCategory category) {
    if (_currentActivityCategory == category) {
      return;
    }

    _currentActivityCategory = category;
    _notify();
  }

  Future<void> startTracking(String childUid) async {
    if (_isTracking && _childUid == childUid && !_isPaused) {
      return;
    }

    _childUid = childUid;
    _isTracking = true;
    _isPaused = false;

    await _firestoreService.ensureChildUsageState(childUid);
    _ruleSettings = await _firestoreService.getAdaptiveRuleSettingsForChild(
      childUid,
    );
    if (_isDisposed || !_isTracking || _childUid != childUid) {
      return;
    }

    _startTimer();
    _notify();
  }

  void pauseTracking() {
    if (!_isTracking || _isPaused) {
      return;
    }

    _timer?.cancel();
    _timer = null;
    _isPaused = true;
    _notify();
  }

  void resumeTracking() {
    if (!_isTracking || !_isPaused || _childUid == null) {
      return;
    }

    _isPaused = false;
    _startTimer();
    _notify();
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _childUid = null;
    _isTracking = false;
    _isPaused = false;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) {
      _recordTick();
    });
  }

  Future<void> _recordTick() async {
    final childUid = _childUid;
    if (childUid == null || _isPaused || _isSaving) {
      return;
    }

    _isSaving = true;
    try {
      final currentUsage = await _firestoreService.getChildUsage(childUid) ??
          ChildUsageModel.defaults;
      if (currentUsage.screenTimeRemaining <= 0) {
        await stopTracking();
        _onTimeLimitReached?.call();
        return;
      }

      final trackedUsage = currentUsage.copyWith(
        dailyUsage: currentUsage.dailyUsage + _minutesPerTick,
        screenTimeRemaining:
            (currentUsage.screenTimeRemaining - _minutesPerTick)
                .clamp(0, 1 << 31)
                .toInt(),
        activityCategory: ActivityClassifierService.toFirestoreValue(
          _currentActivityCategory,
        ),
        educationStreakMinutes:
            _currentActivityCategory == ActivityCategory.education
                ? currentUsage.educationStreakMinutes + _minutesPerTick
                : 0,
        educationMinutesToday:
            _currentActivityCategory == ActivityCategory.education
                ? currentUsage.educationMinutesToday + _minutesPerTick
                : currentUsage.educationMinutesToday,
        entertainmentMinutesToday: _currentActivityCategory ==
                ActivityCategory.entertainment
            ? currentUsage.entertainmentMinutesToday + _minutesPerTick
            : currentUsage.entertainmentMinutesToday,
        socialMinutesToday: _currentActivityCategory == ActivityCategory.social
            ? currentUsage.socialMinutesToday + _minutesPerTick
            : currentUsage.socialMinutesToday,
        neutralMinutesToday:
            _currentActivityCategory == ActivityCategory.neutral
                ? currentUsage.neutralMinutesToday + _minutesPerTick
                : currentUsage.neutralMinutesToday,
        updatedAt: DateTime.now(),
      );
      final entertainmentRuleResult =
          _adaptiveRulesService.evaluateEntertainmentRule(
        usage: trackedUsage,
        settings: _ruleSettings,
      );
      final usageAfterEntertainmentRule =
          _adaptiveRulesService.applyRuleResult(
        usage: trackedUsage,
        result: entertainmentRuleResult,
      );
      final educationRuleResult = _adaptiveRulesService.evaluateEducationRule(
        usage: usageAfterEntertainmentRule,
        settings: _ruleSettings,
      );
      final updatedUsage = _adaptiveRulesService.applyRuleResult(
        usage: usageAfterEntertainmentRule,
        result: educationRuleResult,
      );

      await _firestoreService.updateChildUsage(
        childUid: childUid,
        usage: updatedUsage,
      );

      if (updatedUsage.screenTimeRemaining <= 0) {
        await stopTracking();
        _onTimeLimitReached?.call();
      }
    } finally {
      _isSaving = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
