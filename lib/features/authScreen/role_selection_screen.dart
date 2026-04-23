import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'family_code_screen.dart';
import 'signup_screen.dart';
import '../parentHomeScreen/parent_dashboard_screen.dart';

enum RoleSelectionFlow { manualSignup, googleOnboarding }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({
    super.key,
    this.flow = RoleSelectionFlow.manualSignup,
  });

  final RoleSelectionFlow flow;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isGoogleLoading = false;

  bool get _isGoogleFlow => widget.flow == RoleSelectionFlow.googleOnboarding;

  void _openSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignupScreen(role: SignupRole.parent),
      ),
    );
  }

  Future<void> _completeGoogleParentOnboarding() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final result = await AuthService.completeGoogleParentOnboarding();

    if (!mounted) return;
    setState(() {
      _isGoogleLoading = false;
    });

    AuthService.showSnackBar(
      result,
      context,
      isSuccess: result == "Profile setup successful!",
    );

    if (result == "Profile setup successful!") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const ParentDashboardScreen(),
        ),
        (route) => false,
      );
    }
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 116, 112, 112),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const parentColor = Color.fromARGB(255, 182, 57, 193);
    const childColor = Color.fromRGBO(192, 117, 19, 1);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Choose Your Role",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Select how you want to use Scrintelligent.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color.fromARGB(255, 116, 112, 112),
                ),
              ),
              const SizedBox(height: 40),
              _buildRoleCard(
                context: context,
                icon: Icons.family_restroom,
                color: parentColor,
                title: "Parent",
                subtitle:
                    "Create your account and manage your child's activities.",
                onTap: _isGoogleLoading
                    ? () {}
                    : _isGoogleFlow
                        ? _completeGoogleParentOnboarding
                        : _openSignup,
              ),
              const SizedBox(height: 18),
              _buildRoleCard(
                context: context,
                icon: Icons.child_care,
                color: childColor,
                title: "Child",
                subtitle: "Join with a family code from your parent.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyCodeScreen(
                        flow: _isGoogleFlow
                            ? FamilyCodeFlow.googleOnboarding
                            : FamilyCodeFlow.manualSignup,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
