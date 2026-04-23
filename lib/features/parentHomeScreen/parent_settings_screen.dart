import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/adaptive_rule_settings.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../authScreen/signin_screen.dart';

const Color _parentThemeColor = Color.fromARGB(180, 182, 57, 193);

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoggingOut = false;
  bool _isLoadingRuleSettings = true;
  bool _isSavingRuleSettings = false;
  AdaptiveRuleSettings _ruleSettings = AdaptiveRuleSettings.defaults;

  @override
  void initState() {
    super.initState();
    _loadRuleSettings();
  }

  Future<void> _loadRuleSettings() async {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    if (parentUid == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingRuleSettings = false;
      });
      return;
    }

    final settings =
        await _firestoreService.getAdaptiveRuleSettingsForParent(parentUid);
    if (!mounted) return;
    setState(() {
      _ruleSettings = settings;
      _isLoadingRuleSettings = false;
    });
  }

  Future<void> _saveRuleSettings() async {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    if (parentUid == null || _isSavingRuleSettings) {
      return;
    }

    setState(() {
      _isSavingRuleSettings = true;
    });

    try {
      await _firestoreService.updateFamilyAdaptiveRuleSettings(
        familyId: parentUid,
        settings: _ruleSettings,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Adaptive rule settings saved."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _parentThemeColor,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingRuleSettings = false;
      });
    }
  }

  void _updateRuleSettings(AdaptiveRuleSettings settings) {
    setState(() {
      _ruleSettings = settings.normalize();
    });
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    await AuthService.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const SigninScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor: _parentThemeColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 26,
                              backgroundColor: Color(0xFFE9E3F7),
                              child: Icon(
                                Icons.person,
                                color: _parentThemeColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName?.isNotEmpty == true
                                        ? user!.displayName!
                                        : "Parent Account",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? "",
                                    style: const TextStyle(
                                      color: Color(0xFF777777),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isLoadingRuleSettings
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _parentThemeColor,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Adaptive Rule Controls",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Configure family limits and rewards.",
                                    style: TextStyle(
                                      color: Color(0xFF777777),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _RuleSettingStepper(
                                    label: "Daily screen-time limit",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .dailyScreenTimeLimitMinutes,
                                    min: 30,
                                    max: 720,
                                    step: 5,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          dailyScreenTimeLimitMinutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Education session length",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .educationSessionTargetMinutes,
                                    min: 1,
                                    max: 30,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          educationSessionTargetMinutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "First education reward",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .educationFirstSessionRewardMinutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          educationFirstSessionRewardMinutes:
                                              value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Repeat education reward",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .educationRepeatSessionRewardMinutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          educationRepeatSessionRewardMinutes:
                                              value,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Entertainment thresholds",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _RuleSettingStepper(
                                    label: "Threshold #1",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .entertainmentThreshold1Minutes,
                                    min: 1,
                                    max: 1440,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          entertainmentThreshold1Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Threshold #2",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .entertainmentThreshold2Minutes,
                                    min: 1,
                                    max: 1440,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          entertainmentThreshold2Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Threshold #3",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .entertainmentThreshold3Minutes,
                                    min: 1,
                                    max: 1440,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          entertainmentThreshold3Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Penalty #1",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .entertainmentPenalty1Minutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          entertainmentPenalty1Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Penalty #2",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .entertainmentPenalty2Minutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          entertainmentPenalty2Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Penalty #3",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .entertainmentPenalty3Minutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          entertainmentPenalty3Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "Daily max penalty",
                                    unit: "mins",
                                    value: _ruleSettings
                                        .maxEntertainmentPenaltyMinutesPerDay,
                                    min: 0,
                                    max: 240,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          maxEntertainmentPenaltyMinutesPerDay:
                                              value,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Quiz reward bands",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _RuleSettingStepper(
                                    label: "70-79% reward",
                                    unit: "mins",
                                    value: _ruleSettings.quizReward70To79Minutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          quizReward70To79Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "80-89% reward",
                                    unit: "mins",
                                    value: _ruleSettings.quizReward80To89Minutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          quizReward80To89Minutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  _RuleSettingStepper(
                                    label: "90%+ reward",
                                    unit: "mins",
                                    value: _ruleSettings.quizReward90PlusMinutes,
                                    min: 0,
                                    max: 120,
                                    onChanged: (value) {
                                      _updateRuleSettings(
                                        _ruleSettings.copyWith(
                                          quizReward90PlusMinutes: value,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isSavingRuleSettings
                                          ? null
                                          : _saveRuleSettings,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _parentThemeColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      icon: _isSavingRuleSettings
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.save),
                                      label: Text(
                                        _isSavingRuleSettings
                                            ? "Saving..."
                                            : "Save Rule Settings",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(98, 198, 27, 11),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: _isLoggingOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.logout),
                  label: Text(_isLoggingOut ? "Logging out..." : "Logout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleSettingStepper extends StatelessWidget {
  const _RuleSettingStepper({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final String unit;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: value <= min ? null : () => onChanged(value - step),
            icon: const Icon(Icons.remove_circle_outline),
            color: _parentThemeColor,
          ),
          SizedBox(
            width: 86,
            child: Text(
              "$value $unit",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: value >= max ? null : () => onChanged(value + step),
            icon: const Icon(Icons.add_circle_outline),
            color: _parentThemeColor,
          ),
        ],
      ),
    );
  }
}
