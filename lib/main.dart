import 'package:flutter/material.dart';
import 'screens/introduction_screen.dart'; // Import layar pengenalan

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rainfall App',
      home: IntroductionScreen(), // Layar pertama yang ditampilkan
    );
  }
}
