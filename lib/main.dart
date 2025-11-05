import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  if (!kIsWeb) {
// Firebase فقط روی موبایل فعال می‌شود
    try {
// اگر Firebase فایل‌ها موجود باشند، uncomment کنید
// await Firebase.initializeApp(
//   options: DefaultFirebaseOptions.currentPlatform,
// );
    } catch (e) {
      print('Firebase init skipped on web: $e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شرکت آب منطقه‌ای',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansArabicTextTheme(
          Theme.of(context).textTheme,
        ),
        fontFamily: GoogleFonts.notoSansArabic().fontFamily,
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    );
  }
}