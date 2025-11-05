import 'dart:math';
import 'package:flutter/material.dart';

class PipeLossScreen extends StatefulWidget {
  @override
  _PipeLossScreenState createState() => _PipeLossScreenState();
}

class _PipeLossScreenState extends State<PipeLossScreen> {
  final TextEditingController _lController = TextEditingController();
  final TextEditingController _qController = TextEditingController();
  final TextEditingController _cController = TextEditingController(text: '140');
  final TextEditingController _dController = TextEditingController();
  double? _headLoss;

  void _calculate() {
    double l = double.tryParse(_lController.text) ?? 0;
    double q = double.tryParse(_qController.text) ?? 0;
    double c = double.tryParse(_cController.text) ?? 140;
    double d = double.tryParse(_dController.text) ?? 0;
    if (d > 0 && c > 0) {
      setState(() {
        _headLoss = (10.67 * l * pow(q, 1.852)) /
            (pow(c, 1.852) * pow(d, 4.87));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاسبه افت لوله (هیزن ویلیامز)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _lController,
              decoration: const InputDecoration(labelText: 'طول لوله L (m)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _qController,
              decoration: const InputDecoration(labelText: 'دبی Q (m³/s)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _cController,
              decoration: const InputDecoration(labelText: 'ضریب C'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _dController,
              decoration: const InputDecoration(labelText: 'قطر D (m)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('محاسبه'),
            ),
            const SizedBox(height: 16),
            if (_headLoss != null)
              Text(': $_headLoss m',
                  style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
