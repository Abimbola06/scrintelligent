import 'child_usage_model.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.familyId,
    required this.familyCode,
    required this.createdAt,
    required this.authProvider,
    this.childUsage = ChildUsageModel.defaults,
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String familyId;
  final String familyCode;
  final DateTime createdAt;
  final String authProvider;
  final ChildUsageModel childUsage;

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? familyId,
    String? familyCode,
    DateTime? createdAt,
    String? authProvider,
    ChildUsageModel? childUsage,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      familyCode: familyCode ?? this.familyCode,
      createdAt: createdAt ?? this.createdAt,
      authProvider: authProvider ?? this.authProvider,
      childUsage: childUsage ?? this.childUsage,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'familyId': familyId,
      'familyCode': familyCode,
      'createdAt': createdAt.toIso8601String(),
      'authProvider': authProvider,
    };

    if (role == 'child') {
      map.addAll(childUsage.toMap());
    }

    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      role: map['role'] as String? ?? '',
      familyId: map['familyId'] as String? ?? '',
      familyCode: map['familyCode'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      authProvider: map['authProvider'] as String? ?? '',
      childUsage: ChildUsageModel.fromMap(map),
    );
  }
}
