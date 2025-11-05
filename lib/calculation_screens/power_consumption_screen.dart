import 'package:flutter/material.dart';

class PowerConsumptionScreen extends StatefulWidget {
  @override
  _PowerConsumptionScreenState createState() =>
      _PowerConsumptionScreenState();
}

class _PowerConsumptionScreenState extends State<PowerConsumptionScreen> {
  final TextEditingController _qController = TextEditingController();
  final TextEditingController _hController = TextEditingController();
  final TextEditingController _efficiencyController =
  TextEditingController(text: '0.8');
  double? _power;

  void _calculate() {
    double q = double.tryParse(_qController.text) ?? 0;
    double h = double.tryParse(_hController.text) ?? 0;
    double eta = double.tryParse(_efficiencyController.text) ?? 0.8;
    if (eta > 0) {
      setState(() {
        _power = (q * 1000 * 9.81 * h) / (3600 * eta);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاسبه برق مصرفی/سوخت')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _qController,
              decoration: const InputDecoration(labelText: 'دبی Q (m³/h)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _hController,
              decoration: const InputDecoration(labelText: 'ارتفاع H (m)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _efficiencyController,
              decoration: const InputDecoration(labelText: 'بازده η'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('محاسبه'),
            ),
            const SizedBox(height: 16),
            if (_power != null)
              Text('قدرت مصرفی: $_power kW',
                  style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
