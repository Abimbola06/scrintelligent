import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'child_usage_detail_screen.dart';

const Color _parentThemeColor = Color.fromARGB(180, 182, 57, 193);

class ParentChildrenScreen extends StatefulWidget {
  const ParentChildrenScreen({super.key});

  @override
  State<ParentChildrenScreen> createState() => _ParentChildrenScreenState();
}

class _ParentChildrenScreenState extends State<ParentChildrenScreen> {
  final _firestoreService = FirestoreService();
  late Future<_ParentChildrenData> _childrenFuture;
  final Set<String> _busyChildIds = {};

  @override
  void initState() {
    super.initState();
    _childrenFuture = _loadChildren();
  }

  Future<_ParentChildrenData> _loadChildren() async {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    if (parentUid == null) {
      return const _ParentChildrenData();
    }

    final family = await _firestoreService.getFamily(parentUid);
    if (family == null) {
      return const _ParentChildrenData();
    }

    final children = await _firestoreService.getUsersByIds(family.childUids);
    return _ParentChildrenData(
      family: family,
      children: children.where((child) => child.role == 'child').toList(),
    );
  }

  void _refresh() {
    setState(() {
      _childrenFuture = _loadChildren();
    });
  }

  Future<void> _refreshAsync() async {
    _refresh();
    await _childrenFuture;
  }

  Future<void> _openDetails(UserModel child) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildUsageDetailScreen(
          child: child,
        ),
      ),
    );
  }

  Future<void> _pauseChild(UserModel child) async {
    final shouldPause = await _confirmAction(
      title: "Pause child for today?",
      message:
          "This will set ${_displayName(child)}'s remaining time to 0 until the next daily reset.",
      confirmLabel: "Pause",
    );
    if (!shouldPause) return;

    await _runChildAction(
      childUid: child.uid,
      action: () => _firestoreService.pauseChildForToday(child.uid),
      successMessage: "${_displayName(child)} has been paused for today.",
    );
  }

  Future<void> _resetChild(UserModel child) async {
    final shouldReset = await _confirmAction(
      title: "Reset child usage for today?",
      message:
          "This will reset today's usage counters and restore the daily time limit for ${_displayName(child)}.",
      confirmLabel: "Reset",
    );
    if (!shouldReset) return;

    await _runChildAction(
      childUid: child.uid,
      action: () => _firestoreService.resetChildForToday(child.uid),
      successMessage: "${_displayName(child)} has been reset for today.",
    );
  }

  Future<void> _runChildAction({
    required String childUid,
    required Future<String?> Function() action,
    required String successMessage,
  }) async {
    if (_busyChildIds.contains(childUid)) {
      return;
    }

    setState(() {
      _busyChildIds.add(childUid);
    });

    try {
      final error = await action();
      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color.fromARGB(98, 198, 27, 11),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _parentThemeColor,
          ),
        );
        _refresh();
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _busyChildIds.remove(childUid);
      });
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: _parentThemeColor,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor: _parentThemeColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Children",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_ParentChildrenData>(
          future: _childrenFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const _ParentChildrenData();
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _parentThemeColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "We couldn't load your children right now.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _refresh,
                        style: FilledButton.styleFrom(
                          backgroundColor: _parentThemeColor,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text("Try again"),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (data.children.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshAsync,
                color: _parentThemeColor,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (data.family != null)
                      _FamilySummaryCard(
                        family: data.family!,
                        onCopyCode: () async {
                          await Clipboard.setData(
                            ClipboardData(text: data.family!.familyCode),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Family code copied."),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: _parentThemeColor,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      "No linked children yet.\nShare your family code so a child can join.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshAsync,
              color: _parentThemeColor,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: data.children.length + 1,
                separatorBuilder: (_, index) {
                  if (index == 0) {
                    return const SizedBox(height: 14);
                  }
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    if (data.family == null) {
                      return const SizedBox.shrink();
                    }
                    return _FamilySummaryCard(
                      family: data.family!,
                      onCopyCode: () async {
                        await Clipboard.setData(
                          ClipboardData(text: data.family!.familyCode),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Family code copied."),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: _parentThemeColor,
                          ),
                        );
                      },
                    );
                  }

                  final child = data.children[index - 1];
                  final name = _displayName(child);
                  final isBusy = _busyChildIds.contains(child.uid);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isBusy ? null : () => _openDetails(child),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${_formatMinutes(child.childUsage.dailyUsage)} used | ${_formatMinutes(child.childUsage.screenTimeRemaining)} left",
                                        style: const TextStyle(
                                          color: Color(0xFF777777),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF8A8A8A),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ChildActionButton(
                                icon: Icons.visibility_outlined,
                                label: "View",
                                onTap:
                                    isBusy ? null : () => _openDetails(child),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ChildActionButton(
                                icon: Icons.pause_circle_outline,
                                label: "Pause",
                                onTap: isBusy ? null : () => _pauseChild(child),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ChildActionButton(
                                icon: Icons.restart_alt_outlined,
                                label: "Reset",
                                isPrimary: true,
                                isBusy: isBusy,
                                onTap: isBusy ? null : () => _resetChild(child),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _displayName(UserModel child) {
    final fullName = "${child.firstName} ${child.lastName}".trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return child.email.isEmpty ? "Child" : child.email;
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

class _ParentChildrenData {
  const _ParentChildrenData({
    this.family,
    this.children = const [],
  });

  final FamilyModel? family;
  final List<UserModel> children;
}

class _FamilySummaryCard extends StatelessWidget {
  const _FamilySummaryCard({
    required this.family,
    required this.onCopyCode,
  });

  final FamilyModel family;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    final childCount = family.childUids.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Family Summary",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$childCount / 5 children linked",
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                "Code: ${family.familyCode}",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCopyCode,
                icon: const Icon(
                  Icons.copy,
                  size: 16,
                  color: _parentThemeColor,
                ),
                label: const Text(
                  "Copy",
                  style: TextStyle(color: _parentThemeColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildActionButton extends StatelessWidget {
  const _ChildActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isBusy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final buttonColor =
        isPrimary ? const Color(0xFFE9D7F2) : const Color(0xFFF1E9F7);
    final iconColor = isPrimary ? const Color(0xFF9D3DAA) : _parentThemeColor;
    final effectiveButtonColor =
        enabled ? buttonColor : const Color(0xFFE8E8E8);
    final effectiveIconColor = enabled ? iconColor : const Color(0xFF9C9C9C);
    final labelColor =
        enabled ? const Color(0xFF333333) : const Color(0xFF9C9C9C);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: effectiveButtonColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: effectiveButtonColor,
                width: 1.6,
              ),
            ),
            child: Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9E3F7),
                  shape: BoxShape.circle,
                ),
                child: isBusy
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: effectiveIconColor,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 20,
                        color: effectiveIconColor,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
