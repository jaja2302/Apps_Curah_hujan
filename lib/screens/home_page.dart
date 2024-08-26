import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'introduction_screen.dart'; // Adjust the import based on your file structure

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Input Rainfall Data Here!',
              style: TextStyle(fontSize: 24.0),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('hasSkipped'); // Clear the skip status
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IntroductionScreen(),
                  ),
                );
              },
              child: Text('Reset to Introduction Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
