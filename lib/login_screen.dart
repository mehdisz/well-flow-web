// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'home_screen.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  static const _scopes = [sheets.SheetsApi.spreadsheetsScope];
  static const _sheetId = '1xWPVqwhV4odegfT3ngCvYu8stLP74UAqzQY9IWaCyz0';
  static const _range = 'Sheet1!A:D';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    // چک خالی بودن فیلدها
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('لطفاً نام کاربری و رمز عبور را وارد کنید');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. چک آفلاین (اولویت اول)
      final savedUsername = prefs.getString('savedUsername');
      final savedPassword = prefs.getString('savedPassword');

      if (savedUsername == _usernameController.text.trim() &&
          savedPassword == _passwordController.text) {
        final userName = prefs.getString('savedUserName') ?? 'کاربر';
        final userUnit = prefs.getString('savedUserUnit') ?? 'واحد';

        await prefs.setBool('isLoggedIn', true);
        _navigateToHome(userName, userUnit);
        return;
      }

      // 2. چک اتصال اینترنت
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _showSnackBar('عدم اتصال به اینترنت و اطلاعات ذخیره شده مطابقت ندارد');
        return;
      }

      // 3. لاگین آنلاین
      await _performOnlineLogin(prefs);

    } catch (e) {
      _showSnackBar('خطا در ارتباط با سرور: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performOnlineLogin(SharedPreferences prefs) async {
    final credentialsJson = await rootBundle.loadString('assets/credentials.json');
    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));
    final client = http.Client();
    final authClient = await clientViaServiceAccount(credentials, _scopes, baseClient: client);

    try {
      final sheetsApi = sheets.SheetsApi(authClient);
      final response = await sheetsApi.spreadsheets.values.get(_sheetId, _range);

      final values = response.values;
      String? userName;
      String? userUnit;

      if (values != null && values.isNotEmpty) {
        for (var row in values) {
          if (row.length >= 4 &&
              (row[0]?.toString().trim() ?? '') == _usernameController.text.trim() &&
              (row[1]?.toString().trim() ?? '') == _passwordController.text) {
            userName = row[2]?.toString().trim();
            userUnit = row[3]?.toString().trim();
            break;
          }
        }
      }

      if (userName != null && userUnit != null) {
        // ذخیره اطلاعات برای استفاده آفلاین
        await prefs.setString('savedUsername', _usernameController.text.trim());
        await prefs.setString('savedPassword', _passwordController.text); // هش در آینده
        await prefs.setString('savedUserName', userName);
        await prefs.setString('savedUserUnit', userUnit);
        await prefs.setBool('isLoggedIn', true);

        _navigateToHome(userName, userUnit);
      } else {
        _showSnackBar('نام کاربری یا رمز عبور نادرست است');
      }
    } finally {
      authClient.close();
    }
  }

  void _navigateToHome(String userName, String userUnit) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(userName: userName, userUnit: userUnit),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF004080)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/images/logo.png",
                          height: 100,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "ورود به سامانه شرکت آب منطقه‌ای",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004080),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person, color: Color(0xFF004080)),
                            labelText: 'نام کاربری',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFF004080)),
                            labelText: 'رمز عبور',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: const Color(0xFF1E90FF),
                            ),
                            onPressed: _isLoading ? null : _checkLogin,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'ورود',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "توسعه‌دهنده: م. صالحی زاده | نسخه: 3.5",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}