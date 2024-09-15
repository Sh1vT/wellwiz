import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/login/login_page.dart';
import 'package:wellwiz/features/profile/profile.dart';
import 'package:wellwiz/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initialiseUser();
  }

  Future<void> initialiseUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) { 
    return MaterialApp(
      title: 'WellWiz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      
      home: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_user == null)
              ? const LoginScreen()
              : const BotScreen(),
    );
  }
}
