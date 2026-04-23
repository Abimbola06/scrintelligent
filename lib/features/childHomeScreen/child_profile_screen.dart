import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../authScreen/signin_screen.dart';

const Color _childThemeColor = Color.fromRGBO(192, 117, 19, 1);
const Color _childThemeLightColor = Color.fromRGBO(250, 241, 229, 1);

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _firestoreService = FirestoreService();
  late final Future<UserModel?> _childProfileFuture;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _childProfileFuture =
        uid == null ? Future.value(null) : _firestoreService.getUser(uid);
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _childThemeLightColor,
      appBar: AppBar(
        backgroundColor: _childThemeColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FutureBuilder<UserModel?>(
                future: _childProfileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final name = _displayName(profile, user);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: _childThemeLightColor,
                          child: Icon(
                            Icons.person,
                            color: _childThemeColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? "Loading profile..."
                                    : name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.email ?? user?.email ?? "",
                                style: const TextStyle(
                                  color: Color(0xFF777777),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.star_outline),
                      title: const Text("My progress"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: const Text("Safety settings"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoggingOut ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(98, 198, 27, 11),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: _isLoggingOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.logout),
                  label: Text(_isLoggingOut ? "Logging out..." : "Logout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(UserModel? profile, User? user) {
    final fullName =
        '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final authName = user?.displayName?.trim() ?? '';
    return authName.isEmpty ? "Child Profile" : authName;
  }
}
