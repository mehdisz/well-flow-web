import 'package:flutter/material.dart';
import 'calculation_screens/qanat_flow_screen.dart';
import 'calculation_screens/well_flow_screen.dart';
import 'calculation_screens/pipe_loss_screen.dart';
import 'calculation_screens/power_consumption_screen.dart';
import 'calculation_screens/min_ownership_screen.dart';

class ExpertCalculationsScreen extends StatelessWidget {
  const ExpertCalculationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاسبات کارشناسی')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavButton(
              context,
              'اندازه‌گیری دبی قنات (روش جسم شناور)',
              QanatFlowScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavButton(
              context,
              'اندازه‌گیری دبی چاه (روش جت)',
              WellFlowScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavButton(
              context,
              'محاسبه افت لوله (هیزن ویلیامز)',
              PipeLossScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavButton(
              context,
              'محاسبه برق مصرفی/سوخت بر حسب دبی و ارتفاع',
              PowerConsumptionScreen(),
            ),
            const SizedBox(height: 12),
            _buildNavButton(
              context,
              'حداقل مالکیت لازم برای تامین آب از چاه کشاورزی',
              MinOwnershipScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String title, Widget screen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(title, textAlign: TextAlign.center),
      ),
    );
  }
}
