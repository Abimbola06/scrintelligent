import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scrintelligent/features/authScreen/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Scrintelligent',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 182, 57, 193)),
          useMaterial3: true,
        ),
        // home: const MyApp(title: 'Basic Proifle App'),);
        home: const SplashScreen());
  }
}
