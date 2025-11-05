import 'package:flutter/material.dart';

class MinOwnershipScreen extends StatefulWidget {
  @override
  _MinOwnershipScreenState createState() => _MinOwnershipScreenState();
}

class _MinOwnershipScreenState extends State<MinOwnershipScreen> {
  final TextEditingController _dController = TextEditingController(); // نیاز سالانه m³/y
  final TextEditingController _qController = TextEditingController(); // دبی چاه L/s
  final TextEditingController _hController = TextEditingController(); // ساعت کارکرد Hr
  final TextEditingController _fController = TextEditingController(); // مدار آبیاری day

  double? _minOwnership;

  void _calculate() {
    double d = double.tryParse(_dController.text) ?? 0;
    double q = double.tryParse(_qController.text) ?? 0;
    double h = double.tryParse(_hController.text) ?? 0;
    double f = double.tryParse(_fController.text) ?? 0;

    if (q > 0 && h > 0) {
      setState(() {
        _minOwnership = (d / (q * h * 3.6)) * 24;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text('محاسبه حداقل مالکیت برای تأمین آب از چاه')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dController,
              decoration:
              const InputDecoration(labelText: 'نیاز واحد در سال d (m³/y)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _qController,
              decoration:
              const InputDecoration(labelText: 'آب‌دهی چاه Q (L/s)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _hController,
              decoration: const InputDecoration(
                  labelText: 'ساعت کارکرد مجاز چاه h (Hr)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _fController,
              decoration: const InputDecoration(
                  labelText: 'مدار آبیاری مزرعه F (day)'),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('محاسبه'),
            ),
            const SizedBox(height: 16),
            if (_minOwnership != null)
              Text(
                'حداقل مالکیت: ${_minOwnership!.toStringAsFixed(1)} ساعت',
                style: Theme.of(context).textTheme.titleMedium,
              ),
          ],
        ),
      ),
    );
  }
}
