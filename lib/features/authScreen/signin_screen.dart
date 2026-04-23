import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:scrintelligent/features/authScreen/welcome_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/validators.dart';
import '../../widgets/password_text_form_field.dart';
import '../childHomeScreen/child_blocked_screen.dart';
import '../childHomeScreen/child_dashboard_screen.dart';
import '../parentHomeScreen/parent_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';
// import 'dart:developer';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await AuthService.handleSignIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final isSuccess = result == "Sign-in successful!";
      AuthService.showSnackBar(
        result,
        context,
        isSuccess: isSuccess,
      );
      if (!isSuccess) {
        passwordController.clear();
        return;
      }

      await _navigateToDashboardByRole();
    }
  }

  Future<void> _navigateToDashboardByRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final user = await _firestoreService.getUser(uid);
    if (!mounted) return;

    Widget? dashboard;

    if (user?.role == 'parent') {
      dashboard = const ParentDashboardScreen();
    } else if (user?.role == 'child') {
      await _firestoreService.resetChildUsageIfNewDay(uid);
      final usage = await _firestoreService.getChildUsage(uid);
      if (!mounted) return;

      if ((usage?.screenTimeRemaining ?? 0) <= 0) {
        dashboard = const ChildBlockedScreen();
      } else {
        dashboard = const ChildDashboardScreen();
      }
    }

    if (dashboard == null) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => dashboard!,
      ),
      (route) => false,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() {
      _isGoogleLoading = false;
    });

    AuthService.showSnackBar(
      result.message,
      context,
      isSuccess: result.isSuccess,
    );

    if (result.isSuccess && result.needsOnboarding) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RoleSelectionScreen(
            flow: RoleSelectionFlow.googleOnboarding,
          ),
        ),
      );
      return;
    }

    if (result.isSuccess) {
      await _navigateToDashboardByRole();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 350,
                    height: 300,
                    child: Image.asset(
                      "assets/images/signin_page.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      prefixIcon: Icon(
                        Icons.email,
                        color: Colors.black54,
                        size: 14.0,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  PasswordTextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Colors.black54,
                        size: 14.0,
                      ),
                    ),
                    iconColor: Colors.black,
                    iconSize: 14.0,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text("Forgot Password?",
                            style: TextStyle(fontSize: 11)),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor:
                            const Color.fromARGB(180, 182, 57, 193),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color.fromARGB(255, 182, 57, 193),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              " Login",
                              style: TextStyle(fontSize: 12),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(
                          color: Color.fromRGBO(192, 117, 19, 1),
                        ),
                        foregroundColor: const Color.fromRGBO(192, 117, 19, 1),
                      ),
                      child: _isGoogleLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color.fromRGBO(192, 117, 19, 1),
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("assets/images/google_logo.png"),
                                const SizedBox(width: 10),
                                const Text(
                                  "Google Sign In",
                                  style: TextStyle(fontSize: 12),
                                )
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(fontSize: 12)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign up now",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(180, 182, 57, 193),
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
