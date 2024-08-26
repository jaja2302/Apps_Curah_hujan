import 'package:flutter/material.dart';
import 'screens/introduction_screen.dart'; // Import layar pengenalan

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Rainfall App',
      home: IntroductionScreen(), // Layar pertama yang ditampilkan
    );
  }
}
