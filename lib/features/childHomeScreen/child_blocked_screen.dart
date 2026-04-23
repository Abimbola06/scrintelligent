import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../authScreen/signin_screen.dart';

const Color _childThemeColor = Color.fromRGBO(192, 117, 19, 1);
const Color _childThemeLightColor = Color.fromRGBO(250, 241, 229, 1);

class ChildBlockedScreen extends StatefulWidget {
  const ChildBlockedScreen({super.key});

  @override
  State<ChildBlockedScreen> createState() => _ChildBlockedScreenState();
}

class _ChildBlockedScreenState extends State<ChildBlockedScreen> {
  bool _isSigningOut = false;

  Future<void> _returnToSignIn() async {
    setState(() {
      _isSigningOut = true;
    });

    await AuthService.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const SigninScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _childThemeLightColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 112,
                width: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _childThemeColor.withOpacity(0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_clock,
                  color: _childThemeColor,
                  size: 58,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Screen time finished",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "You've used your Scrintelligent time for today. Come back tomorrow when your time limit resets.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6F5F4C),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSigningOut ? null : _returnToSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _childThemeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSigningOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Back to sign in"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
