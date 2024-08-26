import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart'; // Import your home page
import 'package:animated_background/animated_background.dart';

class IntroductionScreen extends StatefulWidget {
  @override
  _IntroductionScreenState createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  bool isSkipped = false;

  @override
  void initState() {
    super.initState();
    _checkSkipStatus();
  }

  void _checkSkipStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? hasSkipped = prefs.getBool('hasSkipped');
    if (hasSkipped ?? false) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  void _onSkip() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSkipped', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: Colors.red,
                spawnMinSpeed: 15.0,
                spawnMaxSpeed: 90.0,
                spawnMinRadius: 5.0,
                spawnMaxRadius: 5.0,
                particleCount: 10,
              ),
            ),
            vsync: this,
            child: Container(
              // Ensure the PageView fills the screen
              constraints: BoxConstraints.expand(),
              // color: Colors.lightBlue[100], // Background color like blue clouds
              child: PageView(
                controller: _pageController,
                children: [
                  _buildPage(
                    title: 'Selamat Datang',
                    description: 'Aplikasi ini digunakan untuk menginput data curah hujan',
                  ),
                  _buildPage(
                    title: 'Input Estate',
                    description: 'Pilih Estate untuk menentukan lokasi data yang di input ',
                  ),
                  _buildPage(
                    title: 'Input Data Harian',
                    description: 'Masukan data yang sesuai fakta di lapangan',
                  ),
                ],
                onPageChanged: (index) {
                  setState(() {
                    // Handle page change if needed
                  });
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_pageController.page == 2) {
                        _onSkip();
                      } else {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      'Next',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(fontSize: 18.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
