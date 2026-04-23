import 'adaptive_rule_settings.dart';

class FamilyModel {
  const FamilyModel({
    required this.familyId,
    required this.parentUid,
    required this.parentName,
    required this.familyCode,
    required this.childUids,
    required this.createdAt,
    this.adaptiveRuleSettings = AdaptiveRuleSettings.defaults,
  });

  final String familyId;
  final String parentUid;
  final String parentName;
  final String familyCode;
  final List<String> childUids;
  final DateTime createdAt;
  final AdaptiveRuleSettings adaptiveRuleSettings;

  FamilyModel copyWith({
    String? familyId,
    String? parentUid,
    String? parentName,
    String? familyCode,
    List<String>? childUids,
    DateTime? createdAt,
    AdaptiveRuleSettings? adaptiveRuleSettings,
  }) {
    return FamilyModel(
      familyId: familyId ?? this.familyId,
      parentUid: parentUid ?? this.parentUid,
      parentName: parentName ?? this.parentName,
      familyCode: familyCode ?? this.familyCode,
      childUids: childUids ?? this.childUids,
      createdAt: createdAt ?? this.createdAt,
      adaptiveRuleSettings:
          adaptiveRuleSettings ?? this.adaptiveRuleSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'parentUid': parentUid,
      'parentName': parentName,
      'familyCode': familyCode,
      'childUids': childUids,
      'createdAt': createdAt.toIso8601String(),
      'adaptiveRuleSettings': adaptiveRuleSettings.toMap(),
    };
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      familyId: map['familyId'] as String? ?? '',
      parentUid: map['parentUid'] as String? ?? '',
      parentName: map['parentName'] as String? ?? '',
      familyCode: map['familyCode'] as String? ?? '',
      childUids: List<String>.from(map['childUids'] as List? ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      adaptiveRuleSettings: AdaptiveRuleSettings.fromMap(
        Map<String, dynamic>.from(
          map['adaptiveRuleSettings'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}
