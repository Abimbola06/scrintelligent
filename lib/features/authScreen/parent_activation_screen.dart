import 'package:flutter/material.dart';

import '../parentHomeScreen/parent_dashboard_screen.dart';

class ParentActivationScreen extends StatefulWidget {
  const ParentActivationScreen({super.key});

  @override
  State<ParentActivationScreen> createState() => _ParentActivationScreenState();
}

class _ParentActivationScreenState extends State<ParentActivationScreen> {
  static const Color _parentThemeColor = Color.fromARGB(180, 182, 57, 193);

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const ParentDashboardScreen(),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(60, 182, 57, 193),
              Color.fromARGB(180, 182, 57, 193),
              Color.fromARGB(230, 182, 57, 193),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 104,
                  width: 104,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _parentThemeColor.withOpacity(0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: _parentThemeColor,
                    size: 62,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Congratulations, account created",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Your parent dashboard is ready.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
