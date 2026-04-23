import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/child_usage_model.dart';
import '../../services/activity_classifier_service.dart';
import '../../services/adaptive_rules_service.dart';
import '../../services/firestore_service.dart';

const Color _childThemeColor = Color.fromRGBO(192, 117, 19, 1);

class ChildQuizScreen extends StatefulWidget {
  const ChildQuizScreen({super.key});

  @override
  State<ChildQuizScreen> createState() => _ChildQuizScreenState();
}

class _ChildQuizScreenState extends State<ChildQuizScreen> {
  final _firestoreService = FirestoreService();
  final _adaptiveRulesService = AdaptiveRulesService();
  final List<_QuizQuestion> _questions = const [
    _QuizQuestion(
      question: "Which activity helps your brain learn?",
      options: ["Watching random videos", "Practicing a quiz", "Skipping rest"],
      correctAnswerIndex: 1,
    ),
    _QuizQuestion(
      question: "What should you do when screen time is almost finished?",
      options: ["Ignore it", "Plan a break", "Open more apps"],
      correctAnswerIndex: 1,
    ),
    _QuizQuestion(
      question: "Which category does a quiz belong to?",
      options: ["Education", "Social", "Entertainment"],
      correctAnswerIndex: 0,
    ),
  ];

  final Map<int, int> _selectedAnswers = {};
  bool _isSaving = false;
  bool _isLoadingQuizStatus = true;
  DateTime? _latestQuizCompletedAt;

  bool get _allQuestionsAnswered =>
      _selectedAnswers.length == _questions.length;
  bool get _hasCompletedQuizToday =>
      _latestQuizCompletedAt != null &&
      _isSameDay(_latestQuizCompletedAt!, DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadQuizStatus();
  }

  Future<void> _loadQuizStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingQuizStatus = false;
      });
      return;
    }

    final usage = await _firestoreService.getChildUsage(uid);
    final latestCompletedAt = _extractLatestQuizCompletion(usage?.quizHistory);

    if (!mounted) return;
    setState(() {
      _latestQuizCompletedAt = latestCompletedAt;
      _isLoadingQuizStatus = false;
    });
  }

  Future<void> _submitQuiz() async {
    if (!_allQuestionsAnswered || _isSaving || _hasCompletedQuizToday) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final score = _calculateScore();
    final currentUsage =
        await _firestoreService.getChildUsage(uid) ?? ChildUsageModel.defaults;
    final ruleSettings =
        await _firestoreService.getAdaptiveRuleSettingsForChild(uid);
    final ruleResult = _adaptiveRulesService.evaluateQuizRule(
      score: score,
      total: _questions.length,
      settings: ruleSettings,
    );
    final rewardedUsage = _adaptiveRulesService.applyRuleResult(
      usage: currentUsage,
      result: ruleResult,
    );
    final updatedQuizHistory = [
      ...rewardedUsage.quizHistory,
      {
        'quizId': 'quiz_001',
        'score': score,
        'total': _questions.length,
        'completedAt': DateTime.now().toIso8601String(),
      },
    ];

    final updatedUsage = rewardedUsage.copyWith(
      activityCategory: ActivityClassifierService.toFirestoreValue(
        ActivityCategory.education,
      ),
      quizHistory: updatedQuizHistory,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.updateChildUsage(
      childUid: uid,
      usage: updatedUsage,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _latestQuizCompletedAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _buildQuizResultMessage(
            score: score,
            ruleMessages: ruleResult.insightMessages,
          ),
        ),
        backgroundColor: _childThemeColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _buildQuizResultMessage({
    required int score,
    required List<String> ruleMessages,
  }) {
    final resultMessage = "Quiz complete! You scored $score/${_questions.length}.";

    if (ruleMessages.isEmpty) {
      return resultMessage;
    }

    return "$resultMessage ${ruleMessages.first}";
  }

  int _calculateScore() {
    var score = 0;

    for (var index = 0; index < _questions.length; index++) {
      if (_selectedAnswers[index] == _questions[index].correctAnswerIndex) {
        score++;
      }
    }

    return score;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Text(
            "Learning Quiz",
            style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Answer all questions to earn reward points.",
            style: TextStyle(
              color: Color(0xFF6F5F4C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_questions.length, _buildQuestionCard),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !_isLoadingQuizStatus &&
                      _allQuestionsAnswered &&
                      !_hasCompletedQuizToday &&
                      !_isSaving
                  ? _submitQuiz
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _childThemeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD7C5AB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isLoadingQuizStatus
                          ? "Checking quiz status..."
                          : _hasCompletedQuizToday
                          ? "Quiz completed today"
                          : "Submit Quiz",
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(question.options.length, (optionIndex) {
            final isSelected = _selectedAnswers[questionIndex] == optionIndex;

            return RadioListTile<int>(
              value: optionIndex,
              groupValue: _selectedAnswers[questionIndex],
              dense: true,
              activeColor: _childThemeColor,
              contentPadding: EdgeInsets.zero,
              title: Text(
                question.options[optionIndex],
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFF5F5F5F),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              onChanged: _isLoadingQuizStatus || _hasCompletedQuizToday
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedAnswers[questionIndex] = value;
                      });
                    },
            );
          }),
        ],
      ),
    );
  }

  DateTime? _extractLatestQuizCompletion(List<Map<String, dynamic>>? history) {
    if (history == null || history.isEmpty) {
      return null;
    }

    DateTime? latest;
    for (final quiz in history) {
      final rawCompletedAt = quiz['completedAt'];
      final parsed = _parseDateTime(rawCompletedAt);
      if (parsed == null) {
        continue;
      }
      if (latest == null || parsed.isAfter(latest)) {
        latest = parsed;
      }
    }

    return latest;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }

    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });

  final String question;
  final List<String> options;
  final int correctAnswerIndex;
}
