import 'package:flutter/material.dart';

const Color _childThemeColor = Color.fromRGBO(192, 117, 19, 1);

class ChildSocialScreen extends StatelessWidget {
  const ChildSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Text(
            "Social",
            style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Family-safe messages and social features will appear here.",
            style: TextStyle(
              color: Color(0xFF6F5F4C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.forum_rounded,
                  color: _childThemeColor,
                  size: 58,
                ),
                SizedBox(height: 16),
                Text(
                  "Family messages coming soon",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "For now, this screen helps Scrintelligent classify social-style activity safely.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
