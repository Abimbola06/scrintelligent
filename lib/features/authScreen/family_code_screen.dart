import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'child_activation_screen.dart';
import 'signup_screen.dart';

enum FamilyCodeFlow { manualSignup, googleOnboarding }

class FamilyCodeScreen extends StatefulWidget {
  const FamilyCodeScreen({
    super.key,
    this.flow = FamilyCodeFlow.manualSignup,
  });

  final FamilyCodeFlow flow;

  @override
  State<FamilyCodeScreen> createState() => _FamilyCodeScreenState();
}

class _FamilyCodeScreenState extends State<FamilyCodeScreen> {
  static const Color _childColor = Color.fromRGBO(192, 117, 19, 1);

  final _formKey = GlobalKey<FormState>();
  final _familyCodeController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _familyCodeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      final familyCode = _familyCodeController.text.trim().toUpperCase();

      if (widget.flow == FamilyCodeFlow.googleOnboarding) {
        setState(() {
          _isLoading = true;
        });

        final result = await AuthService.completeGoogleChildOnboarding(
          familyCode: familyCode,
        );

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        AuthService.showSnackBar(
          result,
          context,
          isSuccess: result == "Profile setup successful!",
          successColor: _childColor,
        );

        if (result == "Profile setup successful!") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const ChildActivationScreen(),
            ),
            (route) => false,
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final family = await _firestoreService.getFamilyByCode(familyCode);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (family == null) {
        AuthService.showSnackBar(
          "Family code not found.",
          context,
        );
        return;
      }

      if (family.childUids.length >= 5) {
        AuthService.showSnackBar(
          "This family already has the maximum number of children.",
          context,
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupScreen(
            role: SignupRole.child,
            familyCode: familyCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                const Icon(
                  Icons.family_restroom,
                  size: 72,
                  color: _childColor,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Enter Family Code",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Ask your parent for the family code to connect your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color.fromARGB(255, 116, 112, 112),
                  ),
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _familyCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: "Family Code",
                    prefixIcon: Icon(Icons.code),
                    labelStyle: TextStyle(fontSize: 14),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  validator: (value) {
                    final code = value?.trim() ?? "";
                    if (code.isEmpty) {
                      return "Family code is required";
                    }
                    if (code.length != 8) {
                      return "Family code must be 8 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 35),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: _childColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Next",
                            style: TextStyle(fontSize: 12),
                          ),
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
