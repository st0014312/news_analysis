import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          _buildPage(
            context,
            title: 'Welcome to Our App',
            description: 'Discover amazing features and stay connected.',
            imagePath: 'assets/images/onboarding1.png',
          ),
          _buildPage(
            context,
            title: 'Stay Updated',
            description: 'Get the latest news and updates tailored for you.',
            imagePath: 'assets/images/onboarding2.png',
          ),
          _buildPage(
            context,
            title: 'Join the Community',
            description: 'Be part of a vibrant and supportive community.',
            imagePath: 'assets/images/onboarding3.png',
            isLastPage: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required String title,
    required String description,
    required String imagePath,
    bool isLastPage = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, height: 300),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        if (isLastPage)
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Get Started'),
          ),
      ],
    );
  }
}
