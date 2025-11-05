// home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meter_input_screen.dart';
import 'expert_calculations_screen.dart';
import 'saved_records.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final String userUnit;

  const HomeScreen({required this.userName, required this.userUnit, Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    // یا: await prefs.clear(); // اگر می‌خواهید همه چیز پاک شود

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحه اصلی'),
        backgroundColor: const Color(0xFF1E90FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'خروج',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF004080)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('خوش آمدید', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text(userName, style: const TextStyle(fontSize: 18, color: Colors.white)),
            Text(userUnit, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 30),

            // مدیریت رکوردهای آفلاین
            _buildButton(
              context,
              icon: Icons.storage,
              label: 'مدیریت رکوردهای آفلاین',
              color: const Color(0xFF1E90FF),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedRecordsScreen())),
            ),
            const SizedBox(height: 20),

            // وارد کردن اطلاعات کنتور
            _buildButton(
              context,
              icon: Icons.edit,
              label: 'وارد کردن اطلاعات کنتور',
              color: Colors.blueAccent,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MeterInputScreen(userName: userName, userUnit: userUnit)),
              ),
            ),
            const SizedBox(height: 20),

            // محاسبات کارشناسی
            _buildButton(
              context,
              icon: Icons.calculate,
              label: 'محاسبات کارشناسی',
              color: Colors.blueGrey,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertCalculationsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 50)),
      onPressed: onPressed,
    );
  }
}