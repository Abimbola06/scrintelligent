import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

const Color _parentThemeColor = Color.fromARGB(180, 182, 57, 193);

class ParentInsightsScreen extends StatefulWidget {
  const ParentInsightsScreen({super.key});

  @override
  State<ParentInsightsScreen> createState() => _ParentInsightsScreenState();
}

class _ParentInsightsScreenState extends State<ParentInsightsScreen> {
  final _firestoreService = FirestoreService();
  late Future<_ParentInsightsData> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture = _loadInsights();
  }

  Future<_ParentInsightsData> _loadInsights() async {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    if (parentUid == null) {
      return const _ParentInsightsData();
    }

    final family = await _firestoreService.getFamily(parentUid);
    if (family == null) {
      return const _ParentInsightsData();
    }

    final children = await _firestoreService.getUsersByIds(family.childUids);
    return _ParentInsightsData(
      family: family,
      children: children,
    );
  }

  void _refreshInsights() {
    setState(() {
      _insightsFuture = _loadInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor: _parentThemeColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Insights",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _refreshInsights,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_ParentInsightsData>(
          future: _insightsFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const _ParentInsightsData();
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _parentThemeColor,
                ),
              );
            }

            if (data.children.isEmpty) {
              return const _EmptyInsightsState();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FamilySummaryCard(data: data),
                  const SizedBox(height: 16),
                  const Text(
                    "Child Usage",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...data.children.map((child) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ChildInsightCard(child: child),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ParentInsightsData {
  const _ParentInsightsData({
    this.family,
    this.children = const [],
  });

  final FamilyModel? family;
  final List<UserModel> children;
}

class _FamilySummaryCard extends StatelessWidget {
  const _FamilySummaryCard({
    required this.data,
  });

  final _ParentInsightsData data;

  @override
  Widget build(BuildContext context) {
    final totalDailyUsage = data.children.fold<int>(0, (sum, child) {
      return sum + child.childUsage.dailyUsage;
    });
    final totalRemaining = data.children.fold<int>(0, (sum, child) {
      return sum + child.childUsage.screenTimeRemaining;
    });

    return _InsightCard(
      child: Row(
        children: [
          const Icon(
            Icons.insights,
            color: _parentThemeColor,
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${data.children.length} linked children",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${_formatMinutes(totalDailyUsage)} used today - ${_formatMinutes(totalRemaining)} remaining",
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildInsightCard extends StatelessWidget {
  const _ChildInsightCard({
    required this.child,
  });

  final UserModel child;

  @override
  Widget build(BuildContext context) {
    final usage = child.childUsage;
    final badgeCount = usage.badges.length;
    final quizCount = usage.quizHistory.length;
    final latestInsightMessages = usage.insightMessages.reversed.take(3);
    final latestRuleEvents = usage.ruleEvents.reversed.take(5).toList();

    return _InsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE9E3F7),
                child: Icon(
                  Icons.child_care,
                  color: _parentThemeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _childDisplayName(child),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      child.email,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _CategoryPill(category: usage.activityCategory),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                icon: Icons.timer,
                label: "Remaining",
                value: _formatMinutes(usage.screenTimeRemaining),
              ),
              _MetricPill(
                icon: Icons.access_time,
                label: "Used",
                value: _formatMinutes(usage.dailyUsage),
              ),
              _MetricPill(
                icon: Icons.stars,
                label: "Points",
                value: "${usage.rewardPoints}",
              ),
              _MetricPill(
                icon: Icons.emoji_events,
                label: "Badges",
                value: "$badgeCount",
              ),
              _MetricPill(
                icon: Icons.quiz,
                label: "Quizzes",
                value: "$quizCount",
              ),
              _MetricPill(
                icon: Icons.add_circle,
                label: "Bonus",
                value: _formatMinutes(usage.bonusMinutesToday),
              ),
              _MetricPill(
                icon: Icons.remove_circle,
                label: "Penalty",
                value: _formatMinutes(usage.penaltyMinutesToday),
              ),
            ],
          ),
          if (usage.badges.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              "Badges: ${usage.badges.join(', ')}",
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _AdaptiveInsightMessages(
            messages: latestInsightMessages.toList(),
          ),
          const SizedBox(height: 12),
          _RuleTimeline(
            events: latestRuleEvents,
          ),
        ],
      ),
    );
  }

  String _childDisplayName(UserModel child) {
    final fullName = '${child.firstName} ${child.lastName}'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return child.email.isEmpty ? "Child" : child.email;
  }
}

class _AdaptiveInsightMessages extends StatelessWidget {
  const _AdaptiveInsightMessages({
    required this.messages,
  });

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _parentThemeColor.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: _parentThemeColor,
                size: 17,
              ),
              SizedBox(width: 6),
              Text(
                "Adaptive Insights",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (messages.isEmpty)
            const Text(
              "No adaptive rule activity yet. Insights will appear after quiz rewards, education sessions, or entertainment limits.",
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                height: 1.35,
              ),
            )
          else
            ...messages.map((message) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: _parentThemeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RuleTimeline extends StatelessWidget {
  const _RuleTimeline({
    required this.events,
  });

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE3E3EE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.timeline,
                color: _parentThemeColor,
                size: 17,
              ),
              SizedBox(width: 6),
              Text(
                "Rule Timeline",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const Text(
              "No timeline events yet.",
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            )
          else
            ...events.map((event) {
              final message = event['message'] as String? ?? 'Rule event';
              final type = event['type'] as String? ?? 'rule_update';
              final screenDelta = event['screenTimeDelta'] as int? ?? 0;
              final pointsDelta = event['rewardPointsDelta'] as int? ?? 0;
              final timeLabel = _eventTimeLabel(event['createdAt']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: _parentThemeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(
                              color: Color(0xFF444444),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$type | ${_deltaLabel(screenDelta, pointsDelta)} | $timeLabel",
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _deltaLabel(int screenDelta, int pointsDelta) {
    String screenLabel;
    if (screenDelta == 0) {
      screenLabel = "0m";
    } else if (screenDelta > 0) {
      screenLabel = "+${screenDelta}m";
    } else {
      screenLabel = "${screenDelta}m";
    }

    String pointsLabel;
    if (pointsDelta == 0) {
      pointsLabel = "0pts";
    } else if (pointsDelta > 0) {
      pointsLabel = "+${pointsDelta}pts";
    } else {
      pointsLabel = "${pointsDelta}pts";
    }

    return "$screenLabel, $pointsLabel";
  }

  String _eventTimeLabel(dynamic rawCreatedAt) {
    if (rawCreatedAt is! String) {
      return "time unavailable";
    }

    final parsed = DateTime.tryParse(rawCreatedAt);
    if (parsed == null) {
      return "time unavailable";
    }

    final now = DateTime.now();
    final local = parsed.toLocal();
    final isToday = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    if (isToday) {
      return "today $hour:$minute";
    }

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return "$day/$month $hour:$minute";
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E9F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _parentThemeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            "$label: $value",
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyInsightsState extends StatelessWidget {
  const _EmptyInsightsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "No linked children yet. Once a child joins your family, their usage insights will appear here.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF777777),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

String _formatMinutes(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) {
    return "${minutes}m";
  }
  if (minutes == 0) {
    return "${hours}h";
  }
  return "${hours}h ${minutes}m";
}
