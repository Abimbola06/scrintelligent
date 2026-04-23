import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'child_usage_detail_screen.dart';
import 'parent_children_screen.dart';
import 'parent_insights_screen.dart';
import 'parent_settings_screen.dart';

const Color _parentThemeColor = Color.fromARGB(180, 182, 57, 193);

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _firestoreService = FirestoreService();
  late final Future<_ParentDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _dashboardFuture = _loadDashboardData(uid);
  }

  Future<_ParentDashboardData> _loadDashboardData(String? uid) async {
    if (uid == null) {
      return const _ParentDashboardData();
    }

    final parentFuture = _firestoreService.getUser(uid);
    final familyFuture = _firestoreService.getFamily(uid);
    final parent = await parentFuture;
    final family = await familyFuture;
    final children = family == null
        ? <UserModel>[]
        : await _firestoreService.getUsersByIds(family.childUids);

    return _ParentDashboardData(
      parent: parent,
      family: family,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: FutureBuilder<_ParentDashboardData>(
                  future: _dashboardFuture,
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? const _ParentDashboardData();
                    final isLoading =
                        snapshot.connectionState == ConnectionState.waiting;

                    return Column(
                      children: [
                        _DashboardHeader(firstName: data.parentFirstName),
                        Transform.translate(
                          offset: const Offset(0, -42),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _FamilyCodeCard(
                                  family: data.family,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: 14),
                                _LinkedChildrenCard(
                                  children: data.children,
                                  childCount: data.childCount,
                                  isLoading: isLoading,
                                  onChildTap: (child) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChildUsageDetailScreen(
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                _TopCategoriesCard(
                                  children: data.children,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: 14),
                                _AiInsightCard(
                                  isLoading: isLoading,
                                  insight: data.aiInsight,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ParentInsightsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const _DashboardBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _ParentDashboardData {
  const _ParentDashboardData({
    this.parent,
    this.family,
    this.children = const [],
  });

  final UserModel? parent;
  final FamilyModel? family;
  final List<UserModel> children;

  String get parentFirstName {
    final firstName = parent?.firstName.trim() ?? '';
    if (firstName.isNotEmpty) {
      return firstName;
    }

    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final displayFirstName = displayName.trim().split(' ').first;
    return displayFirstName.isEmpty ? "Parent" : displayFirstName;
  }

  int get childCount => family?.childUids.length ?? children.length;

  _DashboardAiInsight get aiInsight {
    final childProfiles = children.where((child) => child.role == 'child');
    _RankedRuleEvent? bestEvent;
    var eventsTriggeredToday = 0;

    for (final child in childProfiles) {
      for (final event in child.childUsage.ruleEvents) {
        final ranked = _RankedRuleEvent.fromMap(
          childName: _childDisplayName(child),
          event: event,
        );

        if (ranked == null) {
          continue;
        }

        if (_isSameDay(ranked.createdAt, DateTime.now())) {
          eventsTriggeredToday += 1;
        }

        if (bestEvent == null ||
            ranked.impactScore > bestEvent.impactScore ||
            (ranked.impactScore == bestEvent.impactScore &&
                ranked.createdAt.isAfter(bestEvent.createdAt))) {
          bestEvent = ranked;
        }
      }
    }

    if (bestEvent != null) {
      return _DashboardAiInsight(
        title: bestEvent.screenTimeDelta == 0
            ? "No screen-time change"
            : bestEvent.screenTimeDelta > 0
                ? "+${bestEvent.screenTimeDelta} min earned"
                : "${bestEvent.screenTimeDelta} min applied",
        body:
            "${bestEvent.childName}: ${bestEvent.message}",
        helper: eventsTriggeredToday == 0
            ? "Tap to open full insights"
            : "$eventsTriggeredToday rule event${eventsTriggeredToday == 1 ? '' : 's'} triggered today",
        screenTimeDelta: bestEvent.screenTimeDelta,
        hasData: true,
      );
    }

    for (final child in childProfiles) {
      if (child.childUsage.insightMessages.isNotEmpty) {
        final latestMessage = child.childUsage.insightMessages.last;
        return _DashboardAiInsight(
          title: "Adaptive summary",
          body: "${_childDisplayName(child)}: $latestMessage",
          helper: "Tap to open full insights",
          screenTimeDelta: 0,
          hasData: true,
        );
      }
    }

    return const _DashboardAiInsight(
      title: "No adaptive activity yet",
      body:
          "Insights will appear after quiz rewards, education streaks, or entertainment penalties.",
      helper: "Tap to open Insights",
      screenTimeDelta: 0,
      hasData: false,
    );
  }

  String _childDisplayName(UserModel child) {
    final fullName = "${child.firstName} ${child.lastName}".trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return child.email.isEmpty ? "Child" : child.email;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _FamilyCodeCard extends StatelessWidget {
  const _FamilyCodeCard({
    required this.family,
    required this.isLoading,
  });

  final FamilyModel? family;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final familyCode = family?.familyCode ?? "--------";

    return _DashboardCard(
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE9E3F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.key,
              color: _parentThemeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Family Code",
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? "Loading..." : familyCode,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            "Share with child",
            style: TextStyle(
              color: Color(0xFF777777),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.firstName,
  });

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 88),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _parentThemeColor,
            Color.fromARGB(220, 182, 57, 193),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.add, color: Colors.white, size: 22),
              Icon(Icons.cloud, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            "Good morning,",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            firstName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Here's today's overview",
            style: TextStyle(
              color: Color(0xFFE6DAFF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LinkedChildrenCard extends StatelessWidget {
  const _LinkedChildrenCard({
    required this.children,
    required this.childCount,
    required this.isLoading,
    required this.onChildTap,
  });

  final List<UserModel> children;
  final int childCount;
  final bool isLoading;
  final ValueChanged<UserModel> onChildTap;

  @override
  Widget build(BuildContext context) {
    final label = childCount == 1 ? "linked child" : "linked children";

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9E3F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care,
                  color: _parentThemeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Linked Children",
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? "Loading..." : "$childCount $label",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLoading) ...[
            const SizedBox(height: 14),
            if (children.isEmpty)
              const Text(
                "No child account has joined this family yet.",
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "Tap a child to view screen-time details.",
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children.map((child) {
                  final name = _childDisplayName(child);
                  return ActionChip(
                    avatar: const CircleAvatar(
                      backgroundColor: _parentThemeColor,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    label: Text(name),
                    backgroundColor: const Color(0xFFF1E9F7),
                    labelStyle: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide.none,
                    onPressed: () => onChildTap(child),
                  );
                }).toList(),
              ),
            ],
          ],
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

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({
    required this.children,
    required this.isLoading,
  });

  final List<UserModel> children;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final rows = children
        .where((child) => child.role == 'child')
        .map(
          (child) => _TopChildFocusData(
            childName: _childDisplayName(child),
            focus: _resolveTopFocus(child),
          ),
        )
        .toList()
      ..sort((a, b) => b.focus.minutes.compareTo(a.focus.minutes));
    final topMinutes =
        rows.isEmpty ? 1 : (rows.first.focus.minutes < 1 ? 1 : rows.first.focus.minutes);

    return _DashboardCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: _parentThemeColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Top Focus Per Child",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Today's strongest category by child",
            style: TextStyle(
              color: Color(0xFF75717E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Loading child focus...",
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 12,
                ),
              ),
            )
          else if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No child focus data available yet.",
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 12,
                ),
              ),
            )
          else
            ...rows.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10),
                child: _TopChildFocusRow(
                  rank: index + 1,
                  childName: child.childName,
                  category: child.focus.category,
                  minutes: child.focus.minutes,
                  maxMinutes: topMinutes,
                ),
              );
            }),
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

  _TopCategoryFocus _resolveTopFocus(UserModel child) {
    final usage = child.childUsage;
    final buckets = <String, int>{
      'Education': usage.educationMinutesToday,
      'Entertainment': usage.entertainmentMinutesToday,
      'Social': usage.socialMinutesToday,
      'Neutral': usage.neutralMinutesToday,
    };

    var topCategory = 'Neutral';
    var topMinutes = 0;

    buckets.forEach((category, minutes) {
      if (minutes > topMinutes) {
        topCategory = category;
        topMinutes = minutes;
      }
    });

    if (topMinutes == 0) {
      topCategory = usage.activityCategory;
      topMinutes = usage.dailyUsage;
    }

    return _TopCategoryFocus(
      category: topCategory,
      minutes: topMinutes,
    );
  }
}

class _TopChildFocusData {
  const _TopChildFocusData({
    required this.childName,
    required this.focus,
  });

  final String childName;
  final _TopCategoryFocus focus;
}

class _TopCategoryFocus {
  const _TopCategoryFocus({
    required this.category,
    required this.minutes,
  });

  final String category;
  final int minutes;
}

class _TopChildFocusRow extends StatelessWidget {
  const _TopChildFocusRow({
    required this.rank,
    required this.childName,
    required this.category,
    required this.minutes,
    required this.maxMinutes,
  });

  final int rank;
  final String childName;
  final String category;
  final int minutes;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCategory(category);
    final color = _colorForCategory(category);
    final ratio = (minutes / maxMinutes).clamp(0.08, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9E1F2),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 22,
            width: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE4F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$rank",
              style: const TextStyle(
                color: _parentThemeColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 13,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: ratio,
                          backgroundColor: const Color(0xFFE8E2EE),
                          color: _parentThemeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatMinutes(minutes),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) {
      return "${mins}m";
    }
    if (mins == 0) {
      return "${hours}h";
    }
    return "${hours}h ${mins}m";
  }

  Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return const Color(0xFF65C86F);
      case 'entertainment':
        return const Color(0xFFE85D4F);
      case 'social':
        return const Color(0xFFD1AA4A);
      default:
        return const Color(0xFF8A8FA6);
    }
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return Icons.menu_book;
      case 'entertainment':
        return Icons.sports_esports;
      case 'social':
        return Icons.chat_bubble;
      default:
        return Icons.circle;
    }
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.isLoading,
    required this.insight,
    required this.onTap,
  });

  final bool isLoading;
  final _DashboardAiInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delta = insight.screenTimeDelta;
    final deltaBadgeColor = delta > 0
        ? const Color(0xFF2E9D57)
        : delta < 0
            ? const Color(0xFFC24A3E)
            : _parentThemeColor;
    final deltaBadgeBg = delta > 0
        ? const Color(0xFFE8F6ED)
        : delta < 0
            ? const Color(0xFFFDEEEB)
            : const Color(0xFFF1E9F7);
    final deltaLabel = delta == 0
        ? "0 min"
        : delta > 0
            ? "+$delta min"
            : "$delta min";

    return _DashboardCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: _parentThemeColor,
                  size: 17,
                ),
                const SizedBox(width: 6),
                const Text(
                  "AI Insight",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8A8A8A),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Text(
                "Loading adaptive summary...",
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 12,
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      insight.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: deltaBadgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      deltaLabel,
                      style: TextStyle(
                        color: deltaBadgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                insight.body,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                insight.helper,
                style: TextStyle(
                  color: insight.hasData
                      ? const Color(0xFF666666)
                      : const Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardAiInsight {
  const _DashboardAiInsight({
    required this.title,
    required this.body,
    required this.helper,
    required this.screenTimeDelta,
    required this.hasData,
  });

  final String title;
  final String body;
  final String helper;
  final int screenTimeDelta;
  final bool hasData;
}

class _RankedRuleEvent {
  const _RankedRuleEvent({
    required this.childName,
    required this.message,
    required this.screenTimeDelta,
    required this.rewardPointsDelta,
    required this.createdAt,
  });

  final String childName;
  final String message;
  final int screenTimeDelta;
  final int rewardPointsDelta;
  final DateTime createdAt;

  int get impactScore =>
      (screenTimeDelta.abs() * 10) + (rewardPointsDelta.abs() * 3);

  static _RankedRuleEvent? fromMap({
    required String childName,
    required Map<String, dynamic> event,
  }) {
    final message = (event['message'] as String?)?.trim();
    final createdAt = _parseDateTime(event['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final screenTimeDelta = _parseInt(event['screenTimeDelta']);
    final rewardPointsDelta = _parseInt(event['rewardPointsDelta']);

    if ((message == null || message.isEmpty) &&
        screenTimeDelta == 0 &&
        rewardPointsDelta == 0) {
      return null;
    }

    return _RankedRuleEvent(
      childName: childName,
      message: (message == null || message.isEmpty) ? "Adaptive rule applied." : message,
      screenTimeDelta: screenTimeDelta,
      rewardPointsDelta: rewardPointsDelta,
      createdAt: createdAt,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
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
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _BottomNavItem(
            icon: Icons.home,
            label: "Home",
            isActive: true,
          ),
          _BottomNavItem(
            icon: Icons.group,
            label: "Children",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentChildrenScreen(),
                ),
              );
            },
          ),
          _BottomNavItem(
            icon: Icons.insert_chart,
            label: "Reports",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentInsightsScreen(),
                ),
              );
            },
          ),
          _BottomNavItem(
            icon: Icons.settings,
            label: "Settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _parentThemeColor : const Color(0xFF60606A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
