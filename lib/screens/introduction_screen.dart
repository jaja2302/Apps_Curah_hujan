import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'package:animated_background/animated_background.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _IntroductionScreenState createState() => _IntroductionScreenState();
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/Loadingbase.json', // Replace with your loading Lottie file
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with SingleTickerProviderStateMixin {
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
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  void _onSkip() async {
    // Show the loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingScreen();
      },
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSkipped', true);

    // Simulate a delay to show the loading animation (optional)
    await Future.delayed(const Duration(seconds: 2));

    // ignore: use_build_context_synchronously
    Navigator.pop(context); // Close the loading screen
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(
            behaviour: RandomParticleBehaviour(
              options: const ParticleOptions(
                baseColor: Colors.blueAccent, // Changed to a cooler color
                spawnMinSpeed: 5.0, // Slower speed for a more relaxing effect
                spawnMaxSpeed: 20.0,
                spawnMinRadius:
                    8.0, // Slightly larger particles for better visibility
                spawnMaxRadius: 15.0,
                particleCount:
                    50, // Increased count for a more dynamic background
              ),
            ),
            vsync: this,
            child: Container(
              constraints: const BoxConstraints.expand(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      children: [
                        _buildPage(
                          lottieAnimation:
                              'assets/animations/Animation - 1724733997066.json',
                          description:
                              'Aplikasi ini digunakan untuk menginput data curah hujan',
                        ),
                        _buildPage(
                          lottieAnimation:
                              'assets/animations/Animation - 1704770335401.json',
                          description:
                              'Pilih Estate untuk menentukan lokasi data yang di input',
                        ),
                        _buildPage(
                          lottieAnimation:
                              'assets/animations/Animation - 1724742661507.json',
                          description:
                              'Masukan data yang sesuai fakta di lapangan',
                        ),
                      ],
                      onPageChanged: (index) {
                        setState(() {
                          // Handle page change if needed
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0), // Added vertical padding
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: 3, // Update this based on your page count
                      effect: const ExpandingDotsEffect(
                        activeDotColor: Color.fromARGB(255, 43, 186,
                            230), // Changed to white for better contrast
                        dotColor: Color.fromARGB(
                            137, 223, 71, 71), // Semi-transparent white dots
                        dotHeight: 12,
                        dotWidth: 12,
                        spacing: 12,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.transparent, // Set background to transparent
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0), // Adjusted padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _onSkip,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                                color: Color.fromARGB(255, 14, 14, 14),
                                fontSize: 16), // Changed text color to white
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_pageController.page == 2) {
                              _onSkip();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: const Text(
                            'Next',
                            style: TextStyle(
                                color: Color.fromARGB(255, 12, 12, 12),
                                fontSize: 16), // Changed text color to white
                          ),
                        ),
                      ],
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

  Widget _buildPage({
    required String description,
    String? lottieAnimation, // Optional parameter for Lottie animation
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          if (lottieAnimation != null)
            Lottie.asset(
              lottieAnimation,
              height: 200, // You can adjust the size as needed
              width: 200,
            ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(fontSize: 18.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
