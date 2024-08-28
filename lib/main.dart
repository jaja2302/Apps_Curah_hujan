import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/introduction_screen.dart'; // Import layar pengenalan
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/history.dart'; // Import your History model

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(HistoryAdapter()); // Register your adapter
    await Hive.openBox<History>('historyBox'); // Open the Hive box
  } catch (e) {
    if (kDebugMode) {
      print("Hive initialization error: $e");
    }
  }

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
