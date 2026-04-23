import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/child_usage_model.dart';
import '../../services/firestore_service.dart';

const Color _childThemeColor = Color.fromRGBO(192, 117, 19, 1);

class ChildRewardsScreen extends StatelessWidget {
  const ChildRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Text("Sign in again to view rewards."),
      );
    }

    return StreamBuilder<ChildUsageModel?>(
      stream: FirestoreService().streamChildUsage(uid),
      builder: (context, snapshot) {
        final usage = snapshot.data ?? ChildUsageModel.defaults;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const Text(
                "Rewards",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Earn points and badges by completing learning activities.",
                style: TextStyle(
                  color: Color(0xFF6F5F4C),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _RewardPointsCard(points: usage.rewardPoints),
              const SizedBox(height: 16),
              _BadgesCard(badges: usage.badges),
              const SizedBox(height: 16),
              _QuizProgressCard(quizHistory: usage.quizHistory),
            ],
          ),
        );
      },
    );
  }
}

class _RewardPointsCard extends StatelessWidget {
  const _RewardPointsCard({
    required this.points,
  });

  final int points;

  @override
  Widget build(BuildContext context) {
    return _RewardsCard(
      child: Row(
        children: [
          const Icon(
            Icons.stars_rounded,
            color: _childThemeColor,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Reward Points",
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$points points",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
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
}

class _BadgesCard extends StatelessWidget {
  const _BadgesCard({
    required this.badges,
  });

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    return _RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Badges",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (badges.isEmpty)
            const Text(
              "No badges yet. Complete a perfect quiz to earn one.",
              style: TextStyle(
                color: Color(0xFF777777),
                fontSize: 12,
                height: 1.35,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((badge) {
                return Chip(
                  avatar: const CircleAvatar(
                    backgroundColor: _childThemeColor,
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  label: Text(badge),
                  backgroundColor: const Color(0xFFFFF3E2),
                  side: BorderSide.none,
                  labelStyle: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _QuizProgressCard extends StatelessWidget {
  const _QuizProgressCard({
    required this.quizHistory,
  });

  final List<Map<String, dynamic>> quizHistory;

  @override
  Widget build(BuildContext context) {
    final completedCount = quizHistory.length;
    final totalScore = quizHistory.fold<int>(0, (sum, quiz) {
      return sum + (quiz['score'] as int? ?? 0);
    });
    final totalPossible = quizHistory.fold<int>(0, (sum, quiz) {
      return sum + (quiz['total'] as int? ?? 0);
    });

    return _RewardsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quiz Progress",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$completedCount quizzes completed",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completedCount == 0
                ? "Finish a quiz to start building your history."
                : "Total score: $totalScore/$totalPossible",
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({
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
