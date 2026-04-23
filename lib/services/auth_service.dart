import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/child_usage_model.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class GoogleSignInResult {
  const GoogleSignInResult({
    required this.message,
    required this.isSuccess,
    required this.needsOnboarding,
    this.uid,
  });

  final String message;
  final bool isSuccess;
  final bool needsOnboarding;
  final String? uid;
}

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirestoreService _firestoreService = FirestoreService();

  static Future<String> signUpWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Signup successful!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        return "The account already exists for that email.";
      }
      return "An error occurred. Please try again.";
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  static Future<String> signUpParentWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final familyCode = await _firestoreService.generateUniqueFamilyCode();
      final createdAt = DateTime.now();
      final parentName = '$firstName $lastName'.trim();

      final user = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: 'parent',
        familyId: uid,
        familyCode: familyCode,
        createdAt: createdAt,
        authProvider: 'password',
      );

      final family = FamilyModel(
        familyId: uid,
        parentUid: uid,
        parentName: parentName,
        familyCode: familyCode,
        childUids: const [],
        createdAt: createdAt,
      );

      await _firestoreService.saveUser(user);
      await _firestoreService.saveFamily(family);

      return "Sign-up successful!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        return "The account already exists for that email.";
      }
      return "An error occurred. Please try again.";
    } catch (e) {
      log("Parent sign-up failed: $e");
      return "An error occurred. Please try again.";
    }
  }

  static Future<String> handleSignUp(
    String email,
    String password,
  ) async {
    String result = await signUpWithEmail(
      email,
      password,
    );

    return result;
  }

  static Future<String> handleParentSignUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await signUpParentWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  static Future<String> signUpChildWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String familyCode,
  }) async {
    try {
      final family = await _firestoreService.getFamilyByCode(familyCode);
      if (family == null) {
        return "Family code not found.";
      }

      if (family.childUids.length >= 5) {
        return "This family already has the maximum number of children.";
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final createdAt = DateTime.now();
      final childUsage =
          ChildUsageModel.defaults.copyWith(
        screenTimeRemaining:
            family.adaptiveRuleSettings.dailyScreenTimeLimitMinutes,
        updatedAt: createdAt,
      );

      final childUser = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: 'child',
        familyId: family.familyId,
        familyCode: family.familyCode,
        createdAt: createdAt,
        authProvider: 'password',
        childUsage: childUsage,
      );

      final joinFamilyError = await _firestoreService.saveChildAndJoinFamily(
        childUser: childUser,
        familyId: family.familyId,
      );

      if (joinFamilyError != null) {
        return joinFamilyError;
      }

      return "Sign-up successful!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        return "The account already exists for that email.";
      }
      return "An error occurred. Please try again.";
    } catch (e) {
      log("Child sign-up failed: $e");
      return "An error occurred. Please try again.";
    }
  }

  static Future<String> handleChildSignUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String familyCode,
  }) async {
    return await signUpChildWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      familyCode: familyCode,
    );
  }

  static Future<String> signInWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "Sign-in successful!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return "The password provided is incorrect.";
      } else if (e.code == 'user-not-found') {
        return "No account found for that email.";
      }
      return "An error occurred. Please try again.";
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  static Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const GoogleSignInResult(
          message: "Google sign-in was cancelled.",
          isSuccess: false,
          needsOnboarding: false,
        );
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      log(userCredential.user.toString());
      final uid = userCredential.user!.uid;
      final hasProfile = await _firestoreService.userExists(uid);

      return GoogleSignInResult(
        message: hasProfile
            ? "Google sign-in successful!"
            : "Google sign-in successful. Please complete your profile.",
        isSuccess: true,
        needsOnboarding: !hasProfile,
        uid: uid,
      );
    } on FirebaseAuthException catch (e) {
      log("Google sign-in failed: ${e.code} - ${e.message}");
      return GoogleSignInResult(
        message: e.message ?? "Google sign-in failed. Please try again.",
        isSuccess: false,
        needsOnboarding: false,
      );
    } catch (e) {
      log(("Google sign-in failed: $e"));
      return const GoogleSignInResult(
        message: "Google sign-in failed. Please try again.",
        isSuccess: false,
        needsOnboarding: false,
      );
    }
  }

  static Future<String> completeGoogleParentOnboarding() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return "Please sign in with Google first.";
      }

      final uid = currentUser.uid;
      final hasProfile = await _firestoreService.userExists(uid);
      if (hasProfile) {
        return "Profile already exists.";
      }

      final email = currentUser.email ?? '';
      final nameParts = (currentUser.displayName ?? '').trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final familyCode = await _firestoreService.generateUniqueFamilyCode();
      final createdAt = DateTime.now();
      final parentName =
          currentUser.displayName?.trim() ?? '$firstName $lastName'.trim();

      final user = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: 'parent',
        familyId: uid,
        familyCode: familyCode,
        createdAt: createdAt,
        authProvider: 'google',
      );

      final family = FamilyModel(
        familyId: uid,
        parentUid: uid,
        parentName: parentName,
        familyCode: familyCode,
        childUids: const [],
        createdAt: createdAt,
      );

      await _firestoreService.saveUser(user);
      await _firestoreService.saveFamily(family);

      return "Profile setup successful!";
    } catch (e) {
      log("Google parent onboarding failed: $e");
      return "Profile setup failed. Please try again.";
    }
  }

  static Future<String> completeGoogleChildOnboarding({
    required String familyCode,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return "Please sign in with Google first.";
      }

      final uid = currentUser.uid;
      final hasProfile = await _firestoreService.userExists(uid);
      if (hasProfile) {
        return "Profile already exists.";
      }

      final family = await _firestoreService.getFamilyByCode(familyCode);
      if (family == null) {
        return "Family code not found.";
      }

      if (family.childUids.length >= 5) {
        return "This family already has the maximum number of children.";
      }

      final email = currentUser.email ?? '';
      final nameParts = (currentUser.displayName ?? '').trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final createdAt = DateTime.now();
      final childUsage =
          ChildUsageModel.defaults.copyWith(
        screenTimeRemaining:
            family.adaptiveRuleSettings.dailyScreenTimeLimitMinutes,
        updatedAt: createdAt,
      );

      final childUser = UserModel(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: 'child',
        familyId: family.familyId,
        familyCode: family.familyCode,
        createdAt: createdAt,
        authProvider: 'google',
        childUsage: childUsage,
      );

      final joinFamilyError = await _firestoreService.saveChildAndJoinFamily(
        childUser: childUser,
        familyId: family.familyId,
      );

      if (joinFamilyError != null) {
        return joinFamilyError;
      }

      return "Profile setup successful!";
    } catch (e) {
      log("Google child onboarding failed: $e");
      return "Profile setup failed. Please try again.";
    }
  }

  static Future<String> handleSignIn(
    String email,
    String password,
  ) async {
    return await signInWithEmail(
      email,
      password,
    );
  }

  static Future<String> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return "Password reset email sent. Please check your inbox.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        return "Please enter a valid email address.";
      } else if (e.code == 'user-not-found') {
        return "No account found for that email.";
      }
      return "An error occurred. Please try again.";
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  static Future<String> handlePasswordReset(String email) async {
    return await sendPasswordResetEmail(email);
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  static void showSnackBar(
    String message,
    BuildContext context, {
    bool isSuccess = false,
    Color? successColor,
  }) {
    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isSuccess
          ? successColor ?? const Color.fromARGB(135, 182, 57, 193)
          : const Color.fromARGB(98, 198, 27, 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
