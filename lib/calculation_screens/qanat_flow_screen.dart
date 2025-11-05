import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class QanatFlowScreen extends StatefulWidget {
  @override
  _QanatFlowScreenState createState() => _QanatFlowScreenState();
}

class _QanatFlowScreenState extends State<QanatFlowScreen> {
  final TextEditingController _hController = TextEditingController();
  final TextEditingController _lController = TextEditingController();
  final TextEditingController _tController = TextEditingController();
  final TextEditingController _wController = TextEditingController();
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _b1Controller = TextEditingController();
  final TextEditingController _b2Controller = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  final TextEditingController _dController = TextEditingController();

  String _selectedShape = 'مستطیل';
  double? _flowRate;
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds++;
        _tController.text = _seconds.toString();
      });
    });
  }

  void _stopTimer() {
    _isRunning = false;
    _timer?.cancel();
  }

  void _resetTimer() {
    _isRunning = false;
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _tController.text = '';
    });
  }

  void _calculate() {
    double H = double.tryParse(_hController.text) ?? 0; // cm
    double L = double.tryParse(_lController.text) ?? 0; // m
    double T = double.tryParse(_tController.text) ?? 0; // s
    if (H <= 0 || L <= 0 || T <= 0) return;

    double Hm = H / 100.0; // تبدیل به متر
    double A = 0;

    switch (_selectedShape) {
      case 'مستطیل':
        double W = double.tryParse(_wController.text) ?? 0; // m
        A = W * Hm;
        break;
      case 'بیضوی':
        double a = double.tryParse(_aController.text) ?? 0; // cm
        A = pi * (a / 200) * (Hm / 2);
        break;
      case 'ذوزنقه':
        double b1 = double.tryParse(_b1Controller.text) ?? 0; // m
        double b2 = double.tryParse(_b2Controller.text) ?? 0; // m
        A = ((b1 + b2) / 2) * Hm;
        break;
      case 'مثلث':
        double b = double.tryParse(_bController.text) ?? 0; // m
        A = 0.5 * b * Hm;
        break;
      case 'نیم‌دایره':
        double d = double.tryParse(_dController.text) ?? 0; // cm
        double dm = d / 100;
        A = pi * pow(dm / 2, 2) / 2;
        break;
    }

    double Q = A * 0.08 * (L / T); // L/s
    setState(() {
      _flowRate = Q;
    });
  }

  Widget _buildShapeFields() {
    switch (_selectedShape) {
      case 'مستطیل':
        return TextField(
          controller: _wController,
          decoration: const InputDecoration(labelText: 'عرض مستطیل (m)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        );
      case 'بیضوی':
        return TextField(
          controller: _aController,
          decoration: const InputDecoration(labelText: 'قطر بزرگ (cm)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        );
      case 'ذوزنقه':
        return Column(children: [
          TextField(
            controller: _b1Controller,
            decoration: const InputDecoration(labelText: 'قاعده بزرگ (m)'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _b2Controller,
            decoration: const InputDecoration(labelText: 'قاعده کوچک (m)'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ]);
      case 'مثلث':
        return TextField(
          controller: _bController,
          decoration: const InputDecoration(labelText: 'قاعده مثلث (m)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        );
      case 'نیم‌دایره':
        return TextField(
          controller: _dController,
          decoration: const InputDecoration(labelText: 'قطر نیم‌دایره (cm)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محاسبه دبی قنات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedShape,
              items: ['مستطیل', 'بیضوی', 'ذوزنقه', 'مثلث', 'نیم‌دایره']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedShape = val!),
            ),
            TextField(
              controller: _hController,
              decoration: const InputDecoration(labelText: 'ارتفاع جریان (cm)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            _buildShapeFields(),
            TextField(
              controller: _lController,
              decoration: const InputDecoration(labelText: 'طول مقطع اندازه‌گیری (m)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tController,
                    decoration: const InputDecoration(labelText: 'زمان (s)'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _startTimer, child: const Text('Start')),
                const SizedBox(width: 4),
                ElevatedButton(onPressed: _stopTimer, child: const Text('Stop')),
                const SizedBox(width: 4),
                ElevatedButton(onPressed: _resetTimer, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('محاسبه'),
            ),
            const SizedBox(height: 20),
            if (_flowRate != null)
              Text('دبی: ${_flowRate!.toStringAsFixed(1)} لیتر بر ثانیه',
                  style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
