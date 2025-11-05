import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class SavedRecordsScreen extends StatefulWidget {
  const SavedRecordsScreen({Key? key}) : super(key: key);

  @override
  _SavedRecordsScreenState createState() => _SavedRecordsScreenState();
}

class _SavedRecordsScreenState extends State<SavedRecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = false;

  // همگام‌سازی با MeterInputScreen - 14 ستون
  static const _scopes = [sheets.SheetsApi.spreadsheetsScope];
  static const _sheetId = '1xWPVqwhV4odegfT3ngCvYu8stLP74UAqzQY9IWaCyz0';
  static const _range = 'MeterData!A:N'; // A تا N (14 ستون)

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('pending_records') ?? [];
    setState(() {
      _records = stored
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _sendRecord(Map<String, dynamic> record) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showSnack('اینترنت قطع است، ارسال ممکن نیست');
      return;
    }

    setState(() => _loading = true);

    try {
      final credentialsJson = await rootBundle.loadString('assets/credentials.json');
      final credentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));
      final client = http.Client();
      final authClient = await clientViaServiceAccount(credentials, _scopes, baseClient: client);

      final sheetsApi = sheets.SheetsApi(authClient);

      // 14 ستون — شامل آب مصرفی کل
      final valueRange = sheets.ValueRange(values: [
        [
          record['date'],
          record['fileClass'],
          record['meterType'],
          record['totalWaterUsed'],     // جدید
          record['waterVolume'],
          record['calculatedFlow'],
          record['instantFlow'],
          record['meterStatus'],
          record['hasViolation'],
          record['violationType'],
          record['violationDesc'],
          record['userName'],
          record['userUnit'],
          record['location'],
        ]
      ]);

      await sheetsApi.spreadsheets.values.append(
        valueRange,
        _sheetId,
        _range,
        valueInputOption: 'RAW',
      );

      authClient.close();

      await _deleteRecordByIndex(record);
      _showSnack('رکورد با موفقیت ارسال شد');
      if (mounted) _loadRecords();

    } catch (e) {
      _showSnack('خطا در ارسال رکورد: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendAllRecords() async {
    if (_records.isEmpty) {
      _showSnack('هیچ رکوردی موجود نیست');
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showSnack('اینترنت قطع است، ارسال ممکن نیست');
      return;
    }

    setState(() => _loading = true);

    int successCount = 0;
    int totalRecords = _records.length;
    int errorCount = 0;

    for (var record in List<Map<String, dynamic>>.from(_records)) {
      try {
        await _sendRecord(record);
        successCount++;
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('خطا در ارسال رکورد ${record['fileClass']}: $e');
        errorCount++;
      }
    }

    if (mounted) {
      setState(() => _loading = false);
      _showSnack(
          '$successCount از $totalRecords رکورد با موفقیت ارسال شد${errorCount > 0 ? ' ($errorCount خطا)' : ''}'
      );
      _loadRecords();
    }
  }

  Future<void> _deleteRecordByIndex(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList('pending_records') ?? [];

    final uniqueKey = '${record['date']}_${record['fileClass']}';
    stored.removeWhere((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return '${decoded['date']}_${decoded['fileClass']}' == uniqueKey;
    });

    await prefs.setStringList('pending_records', stored);
    if (mounted) _loadRecords();
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    await _deleteRecordByIndex(record);
    _showSnack('رکورد ${record['fileClass']} حذف شد');
  }

  Future<void> _deleteAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_records');
    _showSnack('همه رکوردهای ذخیره‌شده حذف شدند');
    _loadRecords();
  }

  void _showEditDialog(Map<String, dynamic> record) {
    final dateController = TextEditingController(text: record['date']);
    final fileClassController = TextEditingController(text: record['fileClass']);
    final totalWaterUsedController = TextEditingController(text: record['totalWaterUsed'] ?? '');
    final waterVolumeController = TextEditingController(text: record['waterVolume']);
    final calculatedFlowController = TextEditingController(text: record['calculatedFlow']);
    final instantFlowController = TextEditingController(text: record['instantFlow']);
    final violationDescController = TextEditingController(text: record['violationDesc']);
    final locationController = TextEditingController(text: record['location']);

    String? meterType = record['meterType'];
    String? meterStatus = record['meterStatus'];
    bool hasViolation = record['hasViolation'] == 'بله';
    String? selectedViolationType = record['violationType'];

    final List<Map<String, String>> violationTypes = [
      {'value': '1', 'label': 'عدم نصب سر ریز مناسب'},
      {'value': '2', 'label': 'نصب منصوبات غیر مجاز'},
      {'value': '3', 'label': 'اضافه برداشت از مفاد پروانه'},
      {'value': '4', 'label': 'عدم نصب و یا حذف و دستکاری کنتور'},
      {'value': '5', 'label': 'کف شکنی، جابجایی و لایروبی بدون مجوز'},
      {'value': '6', 'label': 'انتقال آب به اراضی غیر آبخور اولیه چاه'},
      {'value': '7', 'label': 'تغییر کاربری مصرف'},
      {'value': '8', 'label': 'فعال نبودن آبیاری تحت فشار و تغییر عنوان'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('ویرایش رکورد ${record['fileClass']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: dateController, decoration: const InputDecoration(labelText: 'تاریخ'), readOnly: true),
                TextField(controller: fileClassController, decoration: const InputDecoration(labelText: 'کلاسه پرونده'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: meterType,
                  decoration: const InputDecoration(labelText: 'نوع کنتور'),
                  items: const [
                    DropdownMenuItem(value: 'هوشمند آب و برق', child: Text('هوشمند آب و برق')),
                    DropdownMenuItem(value: 'هوشمند حجمی', child: Text('هوشمند حجمی')),
                    DropdownMenuItem(value: 'سایر', child: Text('سایر')),
                  ],
                  onChanged: (v) => setDialogState(() => meterType = v),
                ),
                DropdownButtonFormField<String>(
                  value: meterStatus,
                  decoration: const InputDecoration(labelText: 'وضعیت کنتور', prefixIcon: Icon(Icons.settings)),
                  items: const [
                    DropdownMenuItem(value: 'سالم', child: Text('سالم')),
                    DropdownMenuItem(value: 'خراب', child: Text('خراب')),
                  ],
                  onChanged: (v) => setDialogState(() => meterStatus = v),
                ),
                // فیلد جدید
                TextField(
                  controller: totalWaterUsedController,
                  decoration: const InputDecoration(labelText: 'آب مصرفی کل (m³)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: waterVolumeController,
                  decoration: const InputDecoration(labelText: 'حجم آب باقیمانده (m³)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: calculatedFlowController,
                  decoration: const InputDecoration(labelText: 'دبی محاسبه‌شده (m³/s)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: instantFlowController,
                  decoration: const InputDecoration(labelText: 'دبی لحظه‌ای (m³/s)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'موقعیت'), maxLines: 2),
                Row(
                  children: [
                    Checkbox(
                      value: hasViolation,
                      onChanged: (v) => setDialogState(() {
                        hasViolation = v ?? false;
                        if (!hasViolation) {
                          selectedViolationType = null;
                          violationDescController.clear();
                        }
                      }),
                    ),
                    const Text('آیا تخلف دارد؟'),
                  ],
                ),
                if (hasViolation) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedViolationType,
                    decoration: const InputDecoration(labelText: 'نوع تخلف'),
                    items: violationTypes.map((v) => DropdownMenuItem(value: v['value'], child: Text(v['label']!))).toList(),
                    onChanged: (v) => setDialogState(() => selectedViolationType = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: violationDescController, decoration: const InputDecoration(labelText: 'توضیحات تخلف'), maxLines: 3),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: (fileClassController.text.isNotEmpty && meterType != null && meterStatus != null)
                  ? () async {
                if (hasViolation && selectedViolationType == null) {
                  _showSnack('لطفاً نوع تخلف را انتخاب کنید');
                  return;
                }

                final updatedRecord = {
                  'date': dateController.text,
                  'fileClass': fileClassController.text,
                  'meterType': meterType,
                  'totalWaterUsed': totalWaterUsedController.text,
                  'waterVolume': waterVolumeController.text,
                  'calculatedFlow': calculatedFlowController.text,
                  'instantFlow': instantFlowController.text,
                  'meterStatus': meterStatus,
                  'hasViolation': hasViolation ? 'بله' : 'خیر',
                  'violationType': selectedViolationType ?? '',
                  'violationDesc': violationDescController.text,
                  'userName': record['userName'],
                  'userUnit': record['userUnit'],
                  'location': locationController.text,
                };

                await _deleteRecordByIndex(record);
                final prefs = await SharedPreferences.getInstance();
                List<String> records = prefs.getStringList('pending_records') ?? [];
                records.add(jsonEncode(updatedRecord));
                await prefs.setStringList('pending_records', records);

                Navigator.pop(context);
                _showSnack('رکورد با موفقیت ویرایش شد');
                _loadRecords();
              }
                  : null,
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف رکورد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('آیا از حذف رکورد ${record['fileClass']} مطمئن هستید؟'),
            if (record['meterStatus'] == 'خراب')
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('این کنتور خراب است', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteRecord(record); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف همه رکوردهای ذخیره‌شده'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('آیا از حذف ${_records.length} رکورد مطمئن هستید؟'),
            const SizedBox(height: 12),
            const Text('این عملیات برگشت‌پذیر نیست!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('رکوردهای حذف‌شده قابل بازیابی نیستند', style: TextStyle(color: Colors.red[700]))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          TextButton(
            onPressed: () async { Navigator.pop(context); await _deleteAllRecords(); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف همه'),
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('جزئیات رکورد ${record['fileClass']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('تاریخ', record['date']),
              _buildDetailRow('کلاسه پرونده', record['fileClass']),
              _buildDetailRow('نوع کنتور', record['meterType']),
              _buildDetailRow('آب مصرفی کل', record['totalWaterUsed'] ?? '—'), // جدید
              _buildDetailRow('حجم آب باقیمانده', record['waterVolume']),
              _buildDetailRow('دبی محاسبه‌شده', record['calculatedFlow']),
              _buildDetailRow('دبی لحظه‌ای', record['instantFlow']),
              _buildDetailRow('وضعیت کنتور', record['meterStatus'] ?? 'نامشخص'),
              if (record['hasViolation'] == 'بله') ...[
                _buildDetailRow('وضعیت تخلف', 'بله'),
                if (record['violationType']?.isNotEmpty == true)
                  _buildDetailRow('نوع تخلف', _getViolationTypeLabel(record['violationType'])),
                if (record['violationDesc']?.isNotEmpty == true)
                  _buildDetailRow('توضیحات تخلف', record['violationDesc']),
              ] else
                _buildDetailRow('وضعیت تخلف', 'خیر'),
              _buildDetailRow('کاربر', record['userName']),
              _buildDetailRow('واحد', record['userUnit']),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))],
      ),
    );
  }

  String _getViolationTypeLabel(String? violationType) {
    final map = {
      '1': 'عدم نصب سر ریز مناسب',
      '2': 'نصب منصوبات غیر مجاز',
      '3': 'اضافه برداشت از مفاد پروانه',
      '4': 'عدم نصب و یا حذف و دستکاری کنتور',
      '5': 'کف شکنی، جابجایی و لایروبی بدون مجوز',
      '6': 'انتقال آب به اراضی غیر آبخور اولیه چاه',
      '7': 'تغییر کاربری مصرف',
      '8': 'فعال نبودن آبیاری تحت فشار و تغییر عنوان',
    };
    return map[violationType] ?? 'نامشخص';
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Expanded(child: Text(value?.toString() ?? 'نامشخص', style: TextStyle(fontSize: 14, color: label.contains('تخلف') ? Colors.orange[700] : null))),
        ],
      ),
    );
  }

  Color _getStatusColor(Map<String, dynamic> record) {
    if (record['meterStatus'] == 'خراب') return Colors.red[100]!;
    if (record['hasViolation'] == 'بله') return Colors.orange[100]!;
    return Colors.green[100]!;
  }

  IconData _getStatusIcon(Map<String, dynamic> record) {
    if (record['meterStatus'] == 'خراب') return Icons.error_outline;
    if (record['hasViolation'] == 'بله') return Icons.warning_amber_outlined;
    return Icons.check_circle_outline;
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _records.any((r) => r['location']?.isNotEmpty == true);

    return Scaffold(
      appBar: AppBar(
        title: Text('رکوردهای ذخیره‌شده (${_records.length})'),
        backgroundColor: const Color(0xFF1E90FF),
        actions: [
          if (_records.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _showDeleteAllDialog, tooltip: 'حذف همه'),
        ],
      ),
      body: _records.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('هیچ رکورد ذخیره‌شده‌ای وجود ندارد', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('رکوردهای آفلاین در اینجا نمایش داده می‌شوند', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      )
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('کل', _records.length.toString(), Icons.list),
                _buildStatCard('سالم', _records.where((r) => r['meterStatus'] == 'سالم').length.toString(), Icons.settings),
                _buildStatCard('خراب', _records.where((r) => r['meterStatus'] == 'خراب').length.toString(), Icons.error_outline),
                _buildStatCard('تخلف', _records.where((r) => r['hasViolation'] == 'بله').length.toString(), Icons.warning),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _records.length,
              itemBuilder: (context, i) {
                final r = _records[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(r),
                      child: Icon(_getStatusIcon(r), color: _getStatusColor(r) == Colors.red[100] ? Colors.red[800] : _getStatusColor(r) == Colors.orange[100] ? Colors.orange[800] : Colors.green[800], size: 20),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text('${r['fileClass']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        if (r['meterType'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12)),
                            child: Text(r['meterType'].toString().substring(0, 3), style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        if (r['meterStatus'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: r['meterStatus'] == 'سالم' ? Colors.green[100] : Colors.red[100], borderRadius: BorderRadius.circular(10)),
                              child: Text(r['meterStatus'] == 'سالم' ? 'سالم' : 'خراب', style: TextStyle(color: r['meterStatus'] == 'سالم' ? Colors.green[800] : Colors.red[800], fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تاریخ: ${r['date']}'),
                        Text('آب مصرفی کل: ${r['totalWaterUsed'] ?? '—'} m³'), // جدید
                        Text('دبی محاسبه‌شده: ${r['calculatedFlow']} m³/s'),
                        if (hasLocation && r['location']?.isNotEmpty == true)
                          Text('موقعیت: ${r['location']}', style: TextStyle(fontSize: 12, color: Colors.green[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (r['hasViolation'] == 'بله') ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                              const SizedBox(width: 4),
                              Text('تخلف: ${_getViolationTypeLabel(r['violationType'])}', style: TextStyle(color: Colors.orange[600], fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (r['violationDesc']?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('توضیحات: ${r['violationDesc']}', style: TextStyle(color: Colors.orange[500], fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Wrap(
                      spacing: 4,
                      children: [
                        IconButton(icon: Icon(Icons.send, color: Colors.green, size: 20), onPressed: () => _sendRecord(r), tooltip: 'ارسال', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        IconButton(icon: Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showEditDialog(r), tooltip: 'ویرایش', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        IconButton(icon: Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _showDeleteDialog(r), tooltip: 'حذف', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ),
                    onTap: () => _showRecordDetails(r),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _records.isNotEmpty && !_loading
          ? FloatingActionButton.extended(
        onPressed: _sendAllRecords,
        backgroundColor: const Color(0xFF1E90FF),
        icon: const Icon(Icons.send),
        label: Text('ارسال همه (${_records.length})'),
      )
          : null,
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))]),
          child: Icon(icon, color: Colors.blue[600], size: 20),
        ),
        const SizedBox(height: 4),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}