// splash_screen.dart
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // حداقل زمان نمایش اسپلش

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      final userName = prefs.getString('savedUserName') ?? 'کاربر';
      final userUnit = prefs.getString('savedUserUnit') ?? 'واحد';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userName: userName, userUnit: userUnit),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 3000,
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/splash_logo.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 20),
          const Text(
            'سامانه شرکت آب منطقه‌ای',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'نسخه 1.5 | توسعه‌دهنده: م. صالحی زاده',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      nextScreen: const SizedBox(), // ما خودمان نویگیت می‌کنیم
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: const Color(0xFF1E90FF),
      splashIconSize: 280,
      disableNavigation: true, // مهم: غیرفعال کردن نویگیت خودکار
    );
  }
}