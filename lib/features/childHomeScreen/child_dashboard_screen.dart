import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/child_usage_model.dart';
import '../../models/user_model.dart';
import '../../providers/screen_time_provider.dart';
import '../../services/activity_classifier_service.dart';
import '../../services/firestore_service.dart';
import 'child_blocked_screen.dart';
import 'child_quiz_screen.dart';
import 'child_profile_screen.dart';
import 'child_rewards_screen.dart';
import 'child_social_screen.dart';

const Color _childThemeColor = Color.fromRGBO(192, 117, 19, 1);
const Color _childThemeLightColor = Color.fromRGBO(250, 241, 229, 1);

class ChildDashboardScreen extends StatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen>
    with WidgetsBindingObserver {
  final _firestoreService = FirestoreService();
  late final ScreenTimeManager _screenTimeManager;
  late final Future<UserModel?> _childProfileFuture;
  late final Stream<ChildUsageModel?> _childUsageStream;
  String? _childUid;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screenTimeManager = ScreenTimeManager(
      onTimeLimitReached: _handleTimeLimitReached,
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _childUid = uid;
    _childProfileFuture = uid == null ? Future.value(null) : _loadChild(uid);
    _childUsageStream = uid == null
        ? Stream<ChildUsageModel?>.value(null)
        : _firestoreService.streamChildUsage(uid);

    WidgetsBinding.instance.addObserver(this);
    if (uid != null) {
      _screenTimeManager.startTracking(uid);
    }
  }

  Future<void> _handleTimeLimitReached() async {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const ChildBlockedScreen(),
      ),
      (route) => false,
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });

    _screenTimeManager.setActivityCategory(_categoryForTab(index));
  }

  ActivityCategory _categoryForTab(int index) {
    switch (index) {
      case 1:
        return ActivityClassifierService.classifyScreen('quiz');
      case 2:
        return ActivityClassifierService.classifyScreen('rewards');
      case 3:
        return ActivityClassifierService.classifyScreen('social');
      default:
        return ActivityClassifierService.classifyScreen('dashboard');
    }
  }

  Future<UserModel?> _loadChild(String uid) async {
    await _firestoreService.ensureChildUsageState(uid);
    return _firestoreService.getUser(uid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _screenTimeManager.pauseTracking();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _screenTimeManager.resumeTracking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenTimeManager.stopTracking();
    _screenTimeManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _childThemeLightColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _ChildHomeTab(
                    childProfileFuture: _childProfileFuture,
                    childUsageStream: _childUsageStream,
                  ),
                  const ChildQuizScreen(),
                  const ChildRewardsScreen(),
                  const ChildSocialScreen(),
                ],
              ),
            ),
            _ChildBottomNav(
              selectedIndex: _selectedIndex,
              onItemSelected: _selectTab,
              onProfileSelected: () async {
                _screenTimeManager.pauseTracking();

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChildProfileScreen(),
                  ),
                );

                if (!mounted || _childUid == null) return;
                _screenTimeManager.resumeTracking();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildHomeTab extends StatelessWidget {
  const _ChildHomeTab({
    required this.childProfileFuture,
    required this.childUsageStream,
  });

  final Future<UserModel?> childProfileFuture;
  final Stream<ChildUsageModel?> childUsageStream;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ChildHeader(childProfileFuture: childProfileFuture),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<ChildUsageModel?>(
                stream: childUsageStream,
                builder: (context, snapshot) {
                  final usage = snapshot.data;

                  return Column(
                    children: [
                      if (ScreenTimeManager.isFastTickMode) ...[
                        const _FastTickModeBanner(),
                        const SizedBox(height: 16),
                      ],
                      _TimeRemainingCard(usage: usage),
                      const SizedBox(height: 16),
                      _FocusCard(usage: usage),
                      const SizedBox(height: 16),
                      _RewardCard(usage: usage),
                      const SizedBox(height: 16),
                      _AdaptiveUpdateCard(usage: usage),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildHeader extends StatelessWidget {
  const _ChildHeader({
    required this.childProfileFuture,
  });

  final Future<UserModel?> childProfileFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 88),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _childThemeColor,
            Color.fromRGBO(224, 151, 55, 1),
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
          const SizedBox(height: 32),
          FutureBuilder<UserModel?>(
            future: childProfileFuture,
            builder: (context, snapshot) {
              final firstName = _firstName(snapshot.data);

              return Text(
                snapshot.connectionState == ConnectionState.waiting
                    ? "Hello!"
                    : "Hello, $firstName!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            "You've got this today",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _firstName(UserModel? profile) {
    final firstName = profile?.firstName.trim() ?? '';
    if (firstName.isNotEmpty) {
      return firstName;
    }

    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final displayFirstName = displayName.trim().split(' ').first;
    return displayFirstName.isEmpty ? "there" : displayFirstName;
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
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

class _FastTickModeBanner extends StatelessWidget {
  const _FastTickModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _childThemeColor.withOpacity(0.22),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.speed,
            color: _childThemeColor,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Test mode is on: every 5 seconds counts as 1 minute.",
              style: TextStyle(
                color: Color(0xFF5F3E15),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRemainingCard extends StatelessWidget {
  const _TimeRemainingCard({
    required this.usage,
  });

  final ChildUsageModel? usage;

  @override
  Widget build(BuildContext context) {
    final screenTimeRemaining =
        usage?.screenTimeRemaining ?? 120;
    final dailyUsage = usage?.dailyUsage ?? 0;
    final dailyLimit = screenTimeRemaining + dailyUsage;
    final progress = dailyLimit == 0 ? 0.0 : screenTimeRemaining / dailyLimit;
    final progressLabel = '${(progress * 100).round()}%';

    return _ChildCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Time Remaining",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMinutes(screenTimeRemaining),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${_formatMinutes(dailyUsage)} used today",
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 78,
            width: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(78, 78),
                  painter: _ChildRingProgressPainter(
                    progress: progress,
                    color: _childThemeColor,
                  ),
                ),
                Text(
                  progressLabel,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

class _ChildRingProgressPainter extends CustomPainter {
  const _ChildRingProgressPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    final backgroundPaint = Paint()
      ..color = _childThemeLightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress * 6.28318,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ChildRingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.usage,
  });

  final ChildUsageModel? usage;

  @override
  Widget build(BuildContext context) {
    final activityCategory =
        usage?.activityCategory ?? "Neutral";

    return _ChildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Focus",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            activityCategory,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Today's activity category.",
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.usage,
  });

  final ChildUsageModel? usage;

  @override
  Widget build(BuildContext context) {
    final rewardPoints = usage?.rewardPoints ?? 0;
    final badges = usage?.badges ?? const <String>[];
    final quizHistory =
        usage?.quizHistory ?? const <Map<String, dynamic>>[];
    final badgeCount = badges.length;
    final badgeSummary = _badgeSummary(badges);
    final quizCount = quizHistory.length;

    return _ChildCard(
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Color(0xFFF4A62A),
            size: 50,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Reward Progress",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$rewardPoints reward points",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badgeCount == 1
                      ? "1 badge earned: $badgeSummary"
                      : "$badgeCount badges earned",
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (badgeCount > 1) ...[
                  const SizedBox(height: 3),
                  Text(
                    badgeSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  "$quizCount quizzes completed",
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _badgeSummary(List<String> badges) {
    if (badges.isEmpty) {
      return "No badges yet";
    }

    return badges.join(", ");
  }
}

class _AdaptiveUpdateCard extends StatelessWidget {
  const _AdaptiveUpdateCard({
    required this.usage,
  });

  final ChildUsageModel? usage;

  @override
  Widget build(BuildContext context) {
    final latestMessage = _latestInsightMessage();

    return _ChildCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _childThemeLightColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: _childThemeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Adaptive Update",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  latestMessage ??
                      "Keep learning and making good choices. Your updates will appear here.",
                  style: const TextStyle(
                    color: Color(0xFF555555),
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

  String? _latestInsightMessage() {
    final messages = usage?.insightMessages ?? const <String>[];
    if (messages.isEmpty) {
      return null;
    }

    return messages.last;
  }
}

class _ChildBottomNav extends StatelessWidget {
  const _ChildBottomNav({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onProfileSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onProfileSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ChildBottomNavItem(
            icon: Icons.home,
            label: "Home",
            isActive: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          _ChildBottomNavItem(
            icon: Icons.quiz,
            label: "Quiz",
            isActive: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          _ChildBottomNavItem(
            icon: Icons.emoji_events,
            label: "Rewards",
            isActive: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),
          _ChildBottomNavItem(
            icon: Icons.forum,
            label: "Social",
            isActive: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
          _ChildBottomNavItem(
            icon: Icons.person,
            label: "Profile",
            isActive: false,
            onTap: onProfileSelected,
          ),
        ],
      ),
    );
  }
}

class _ChildBottomNavItem extends StatelessWidget {
  const _ChildBottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _childThemeColor : const Color(0xFF8E8275);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
