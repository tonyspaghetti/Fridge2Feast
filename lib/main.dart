import 'package:flutter/material.dart';
import 'start.dart';

void main() {
  runApp(const Fridge2FeastApp());
}

class Fridge2FeastApp extends StatelessWidget {
  const Fridge2FeastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}