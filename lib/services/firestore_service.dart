import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/adaptive_rule_settings.dart';
import '../models/child_usage_model.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    Random? random,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final Random _random;

  static const String usersCollection = 'users';
  static const String familiesCollection = 'families';
  static const String _familyCodeCharacters =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _familyCodeLength = 8;

  Future<String> generateUniqueFamilyCode() async {
    while (true) {
      final code = _generateFamilyCode();
      final existingFamilies = await _firestore
          .collection(familiesCollection)
          .where('familyCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existingFamilies.docs.isEmpty) {
        return code;
      }
    }
  }

  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .set(user.toMap());
  }

  Future<bool> userExists(String uid) async {
    final userDoc = await _firestore.collection(usersCollection).doc(uid).get();
    return userDoc.exists;
  }

  Future<UserModel?> getUser(String uid) async {
    final userDoc = await _firestore.collection(usersCollection).doc(uid).get();
    final data = userDoc.data();

    if (!userDoc.exists || data == null) {
      return null;
    }

    return UserModel.fromMap(data);
  }

  Future<List<UserModel>> getUsersByIds(
    List<String> uids, {
    bool resetChildUsage = false,
  }) async {
    if (uids.isEmpty) {
      return [];
    }

    if (resetChildUsage) {
      await Future.wait(uids.map(resetChildUsageIfNewDay));
    }

    final users = await Future.wait(uids.map(getUser));
    return users.whereType<UserModel>().toList();
  }

  Stream<List<UserModel>> streamChildrenForFamily(String familyId) {
    if (familyId.isEmpty) {
      return Stream<List<UserModel>>.value(const []);
    }

    return _firestore
        .collection(usersCollection)
        .where('familyId', isEqualTo: familyId)
        .where('role', isEqualTo: 'child')
        .snapshots()
        .asyncMap((snapshot) async {
      final childUids = snapshot.docs.map((doc) => doc.id).toList();
      await Future.wait(childUids.map(resetChildUsageIfNewDay));

      final users = await Future.wait(childUids.map(getUser));
      return users.whereType<UserModel>().toList();
    });
  }

  Future<ChildUsageModel?> getChildUsage(String uid) async {
    await resetChildUsageIfNewDay(uid);

    final userDoc = await _firestore.collection(usersCollection).doc(uid).get();
    final data = userDoc.data();

    if (!userDoc.exists || data == null || data['role'] != 'child') {
      return null;
    }

    return ChildUsageModel.fromMap(data);
  }

  Stream<ChildUsageModel?> streamChildUsage(String uid) {
    return _firestore
        .collection(usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null || data['role'] != 'child') {
        return null;
      }

      return ChildUsageModel.fromMap(data);
    });
  }

  Future<void> resetChildUsageIfNewDay(String childUid) async {
    final userRef = _firestore.collection(usersCollection).doc(childUid);

    await _firestore.runTransaction<void>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data();

      if (!userSnapshot.exists ||
          userData == null ||
          userData['role'] != 'child') {
        return;
      }

      final usage = ChildUsageModel.fromMap(userData);
      final updatedAt = usage.updatedAt;
      if (updatedAt != null && _isSameDay(updatedAt, DateTime.now())) {
        return;
      }

      final familyId = userData['familyId'] as String? ?? '';
      final familyData = await _familyDataForUserTransaction(
        transaction: transaction,
        familyId: familyId,
      );
      final dailyLimit = _dailyScreenLimitFromFamilyData(familyData);

      transaction.update(
        userRef,
        ChildUsageModel.defaults
            .copyWith(
              screenTimeRemaining: dailyLimit,
              updatedAt: DateTime.now(),
            )
            .toMap(),
      );
    });
  }

  Future<void> updateChildUsageState({
    required String childUid,
    int? screenTimeRemaining,
    int? dailyUsage,
    String? activityCategory,
    int? rewardPoints,
    List<String>? badges,
    List<Map<String, dynamic>>? quizHistory,
    int? educationSessionsToday,
    int? educationStreakMinutes,
    int? educationMinutesToday,
    int? entertainmentMinutesToday,
    int? socialMinutesToday,
    int? neutralMinutesToday,
    int? entertainmentWarningsToday,
    int? penaltyMinutesToday,
    int? bonusMinutesToday,
    List<String>? insightMessages,
    List<Map<String, dynamic>>? ruleEvents,
  }) async {
    final updates = <String, dynamic>{};

    if (screenTimeRemaining != null) {
      updates['screenTimeRemaining'] = screenTimeRemaining;
    }
    if (dailyUsage != null) {
      updates['dailyUsage'] = dailyUsage;
    }
    if (activityCategory != null) {
      updates['activityCategory'] = activityCategory;
    }
    if (rewardPoints != null) {
      updates['rewardPoints'] = rewardPoints;
    }
    if (badges != null) {
      updates['badges'] = badges;
    }
    if (quizHistory != null) {
      updates['quizHistory'] = quizHistory;
    }
    if (educationSessionsToday != null) {
      updates['educationSessionsToday'] = educationSessionsToday;
    }
    if (educationStreakMinutes != null) {
      updates['educationStreakMinutes'] = educationStreakMinutes;
    }
    if (educationMinutesToday != null) {
      updates['educationMinutesToday'] = educationMinutesToday;
    }
    if (entertainmentMinutesToday != null) {
      updates['entertainmentMinutesToday'] = entertainmentMinutesToday;
    }
    if (socialMinutesToday != null) {
      updates['socialMinutesToday'] = socialMinutesToday;
    }
    if (neutralMinutesToday != null) {
      updates['neutralMinutesToday'] = neutralMinutesToday;
    }
    if (entertainmentWarningsToday != null) {
      updates['entertainmentWarningsToday'] = entertainmentWarningsToday;
    }
    if (penaltyMinutesToday != null) {
      updates['penaltyMinutesToday'] = penaltyMinutesToday;
    }
    if (bonusMinutesToday != null) {
      updates['bonusMinutesToday'] = bonusMinutesToday;
    }
    if (insightMessages != null) {
      updates['insightMessages'] = insightMessages;
    }
    if (ruleEvents != null) {
      updates['ruleEvents'] = ruleEvents;
    }

    if (updates.isEmpty) {
      return;
    }

    updates['updatedAt'] = DateTime.now().toIso8601String();

    await _firestore.collection(usersCollection).doc(childUid).update(updates);
  }

  Future<void> updateChildUsageFields({
    required String childUid,
    required Map<String, dynamic> data,
  }) async {
    if (data.isEmpty) {
      return;
    }

    await _firestore.collection(usersCollection).doc(childUid).update({
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateChildUsage({
    required String childUid,
    required ChildUsageModel usage,
  }) async {
    final updatedUsage = usage.copyWith(updatedAt: DateTime.now());

    await _firestore
        .collection(usersCollection)
        .doc(childUid)
        .update(updatedUsage.toMap());
  }

  Future<void> ensureChildUsageState(String childUid) async {
    final userRef = _firestore.collection(usersCollection).doc(childUid);

    await _firestore.runTransaction<void>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data();

      if (!userSnapshot.exists ||
          userData == null ||
          userData['role'] != 'child') {
        return;
      }

      final familyId = userData['familyId'] as String? ?? '';
      final familyData = await _familyDataForUserTransaction(
        transaction: transaction,
        familyId: familyId,
      );
      final dailyLimit = _dailyScreenLimitFromFamilyData(familyData);
      final defaults = {
        ...ChildUsageModel.defaults
            .copyWith(screenTimeRemaining: dailyLimit)
            .toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final updates = <String, dynamic>{};

      defaults.forEach((key, value) {
        if (!userData.containsKey(key)) {
          updates[key] = value;
        }
      });

      if (updates.isNotEmpty) {
        transaction.update(userRef, updates);
      }
    });
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> saveFamily(FamilyModel family) async {
    await _firestore
        .collection(familiesCollection)
        .doc(family.parentUid)
        .set(family.toMap());
  }

  Future<FamilyModel?> getFamily(String parentUid) async {
    final familyDoc =
        await _firestore.collection(familiesCollection).doc(parentUid).get();
    final data = familyDoc.data();

    if (!familyDoc.exists || data == null) {
      return null;
    }

    return FamilyModel.fromMap(data);
  }

  Future<FamilyModel?> getFamilyByCode(String familyCode) async {
    final familyQuery = await _firestore
        .collection(familiesCollection)
        .where('familyCode', isEqualTo: familyCode)
        .limit(1)
        .get();

    if (familyQuery.docs.isEmpty) {
      return null;
    }

    return FamilyModel.fromMap(familyQuery.docs.first.data());
  }

  Future<AdaptiveRuleSettings> getAdaptiveRuleSettingsForParent(
    String parentUid,
  ) async {
    final family = await getFamily(parentUid);
    return family?.adaptiveRuleSettings ?? AdaptiveRuleSettings.defaults;
  }

  Future<AdaptiveRuleSettings> getAdaptiveRuleSettingsForChild(
    String childUid,
  ) async {
    final child = await getUser(childUid);
    final familyId = child?.familyId ?? '';
    if (familyId.isEmpty) {
      return AdaptiveRuleSettings.defaults;
    }

    final family = await getFamily(familyId);
    return family?.adaptiveRuleSettings ?? AdaptiveRuleSettings.defaults;
  }

  Future<void> updateFamilyAdaptiveRuleSettings({
    required String familyId,
    required AdaptiveRuleSettings settings,
  }) async {
    await _firestore.collection(familiesCollection).doc(familyId).update({
      'adaptiveRuleSettings': settings.normalize().toMap(),
    });
  }

  Future<String?> pauseChildForToday(String childUid) async {
    final userRef = _firestore.collection(usersCollection).doc(childUid);

    return _firestore.runTransaction<String?>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data();

      if (!userSnapshot.exists || userData == null) {
        return "Child account not found.";
      }
      if (userData['role'] != 'child') {
        return "This account is not a child profile.";
      }

      final usage = ChildUsageModel.fromMap(userData);
      final updatedInsightMessages = [
        ...usage.insightMessages,
        'Paused by parent for the rest of today.',
      ];
      final trimmedInsightMessages = updatedInsightMessages.length > 30
          ? updatedInsightMessages
              .sublist(updatedInsightMessages.length - 30)
          : updatedInsightMessages;
      final updatedRuleEvents = [
        ...usage.ruleEvents,
        {
          'type': 'parent_pause',
          'message': 'Paused by parent for the rest of today.',
          'screenTimeDelta': -usage.screenTimeRemaining,
          'rewardPointsDelta': 0,
          'badgesAdded': const <String>[],
          'eventData': const <String, dynamic>{},
          'createdAt': DateTime.now().toIso8601String(),
        },
      ];

      transaction.update(userRef, {
        'screenTimeRemaining': 0,
        'insightMessages': trimmedInsightMessages,
        'ruleEvents': updatedRuleEvents.length > 50
            ? updatedRuleEvents.sublist(updatedRuleEvents.length - 50)
            : updatedRuleEvents,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return null;
    });
  }

  Future<String?> resetChildForToday(String childUid) async {
    final userRef = _firestore.collection(usersCollection).doc(childUid);

    return _firestore.runTransaction<String?>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data();

      if (!userSnapshot.exists || userData == null) {
        return "Child account not found.";
      }
      if (userData['role'] != 'child') {
        return "This account is not a child profile.";
      }

      final familyId = userData['familyId'] as String? ?? '';
      final familyData = await _familyDataForUserTransaction(
        transaction: transaction,
        familyId: familyId,
      );
      final dailyLimit = _dailyScreenLimitFromFamilyData(familyData);
      final usage = ChildUsageModel.fromMap(userData);
      final resetUsage = usage.copyWith(
        screenTimeRemaining: dailyLimit,
        dailyUsage: 0,
        activityCategory: 'Neutral',
        educationSessionsToday: 0,
        educationStreakMinutes: 0,
        educationMinutesToday: 0,
        entertainmentMinutesToday: 0,
        socialMinutesToday: 0,
        neutralMinutesToday: 0,
        entertainmentWarningsToday: 0,
        penaltyMinutesToday: 0,
        bonusMinutesToday: 0,
        insightMessages: const [],
        ruleEvents: const [],
        updatedAt: DateTime.now(),
      );

      transaction.update(userRef, resetUsage.toMap());
      return null;
    });
  }

  Future<String?> addChildToFamily({
    required String familyId,
    required String childUid,
  }) async {
    final familyRef = _firestore.collection(familiesCollection).doc(familyId);

    return await _firestore.runTransaction<String?>((transaction) async {
      final familySnapshot = await transaction.get(familyRef);
      final familyData = familySnapshot.data();

      if (!familySnapshot.exists || familyData == null) {
        return "Family not found.";
      }

      final childUids =
          List<String>.from(familyData['childUids'] as List? ?? []);

      if (childUids.contains(childUid)) {
        return null;
      }

      if (childUids.length >= 5) {
        return "This family already has the maximum number of children.";
      }

      childUids.add(childUid);
      transaction.update(familyRef, {'childUids': childUids});
      return null;
    });
  }

  Future<String?> saveChildAndJoinFamily({
    required UserModel childUser,
    required String familyId,
  }) async {
    final userRef = _firestore.collection(usersCollection).doc(childUser.uid);
    final familyRef = _firestore.collection(familiesCollection).doc(familyId);

    return await _firestore.runTransaction<String?>((transaction) async {
      final familySnapshot = await transaction.get(familyRef);
      final familyData = familySnapshot.data();

      if (!familySnapshot.exists || familyData == null) {
        return "Family not found.";
      }

      final childUids =
          List<String>.from(familyData['childUids'] as List? ?? []);

      if (!childUids.contains(childUser.uid)) {
        if (childUids.length >= 5) {
          return "This family already has the maximum number of children.";
        }

        childUids.add(childUser.uid);
      }

      transaction.set(userRef, childUser.toMap());
      transaction.update(familyRef, {'childUids': childUids});
      return null;
    });
  }

  String _generateFamilyCode() {
    return List.generate(_familyCodeLength, (_) {
      final index = _random.nextInt(_familyCodeCharacters.length);
      return _familyCodeCharacters[index];
    }).join();
  }

  Future<Map<String, dynamic>?> _familyDataForUserTransaction({
    required Transaction transaction,
    required String familyId,
  }) async {
    if (familyId.isEmpty) {
      return null;
    }

    final familyRef = _firestore.collection(familiesCollection).doc(familyId);
    final familySnapshot = await transaction.get(familyRef);
    return familySnapshot.data();
  }

  int _dailyScreenLimitFromFamilyData(Map<String, dynamic>? familyData) {
    if (familyData == null) {
      return AdaptiveRuleSettings.defaults.dailyScreenTimeLimitMinutes;
    }

    final settingsMap = Map<String, dynamic>.from(
      familyData['adaptiveRuleSettings'] as Map? ?? const <String, dynamic>{},
    );
    return AdaptiveRuleSettings.fromMap(settingsMap)
        .dailyScreenTimeLimitMinutes;
  }
}
