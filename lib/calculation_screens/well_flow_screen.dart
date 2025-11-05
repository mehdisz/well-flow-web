import 'package:flutter/material.dart';

class WellFlowScreen extends StatefulWidget {
  @override
  _WellFlowScreenState createState() => _WellFlowScreenState();
}

class _WellFlowScreenState extends State<WellFlowScreen> {
  final TextEditingController _dController = TextEditingController();
  final TextEditingController _lController = TextEditingController();
  final TextEditingController _hController = TextEditingController();
  bool _isInInch = true; // true = inch, false = cm
  double? _flowRate;

  void _calculate() {
    double d = double.tryParse(_dController.text) ?? 0;
    double L = double.tryParse(_lController.text) ?? 0;
    double H = double.tryParse(_hController.text) ?? 0;

    // تبدیل d به سانتیمتر در صورت ورودی برحسب اینچ
    double d_cm = _isInInch ? d * 2.54 : d;
    double d_inch = _isInInch ? d : d / 2.54;

    setState(() {
      _flowRate = (d_inch * d_inch / 50) * L * ((d_cm - H) / d_cm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاسبه دبی چاه به روش جت')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dController,
                    decoration: InputDecoration(
                      labelText: _isInInch
                          ? 'قطر لوله d (اینچ)'
                          : 'قطر لوله d (سانتی‌متر)',
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isInInch,
                  onChanged: (val) => setState(() => _isInInch = val),
                ),
                Text(_isInInch ? 'inch' : 'cm'),
              ],
            ),
            TextField(
              controller: _lController,
              decoration: const InputDecoration(labelText: 'طول پرش L (cm)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _hController,
              decoration:
              const InputDecoration(labelText: 'ارتفاع خالی لوله H (cm)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('محاسبه'),
            ),
            const SizedBox(height: 16),
            if (_flowRate != null)
              Text(
                'دبی: ${_flowRate!.toStringAsFixed(2)} L/s',
                style: Theme.of(context).textTheme.titleMedium,
              ),
          ],
        ),
      ),
    );
  }
}
