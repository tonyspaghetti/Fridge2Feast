import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'start.dart';

// decides which screen to show when app opens
void main() {
  runApp(const Fridge2FeastApp());
}

class Fridge2FeastApp extends StatelessWidget {
  const Fridge2FeastApp({super.key});

  Future<Widget> _getStartPage() async {
    final prefs = await SharedPreferences.getInstance();

    final hasCompletedSetup = prefs.getBool('hasCompletedSetup') ?? false;
    final fullName = prefs.getString('fullName') ?? 'Chef';

    if (hasCompletedSetup) {
      return HomeScreen(fullName: fullName);
    }

    return const StartScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _getStartPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                ),
              ),
            );
          }

          return snapshot.data ?? const StartScreen();
        },
      ),
    );
  }
}