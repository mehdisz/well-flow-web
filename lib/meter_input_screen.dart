import 'package:flutter/material.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:coordinate_converter/coordinate_converter.dart';
import 'package:url_launcher/url_launcher.dart';

class MeterInputScreen extends StatefulWidget {
  final String? userName;
  final String? userUnit;

  const MeterInputScreen({this.userName, this.userUnit});

  @override
  _MeterInputScreenState createState() => _MeterInputScreenState();
}

class _MeterInputScreenState extends State<MeterInputScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fileClassController = TextEditingController();
  final TextEditingController _totalWaterUsedController = TextEditingController();
  final TextEditingController _waterVolumeController = TextEditingController();
  final TextEditingController _calculatedFlowController = TextEditingController();
  final TextEditingController _instantFlowController = TextEditingController();
  final TextEditingController _violationDescController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _meterType;
  String? _meterStatus;
  bool _hasViolation = false;
  String? _selectedViolationType;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;
  bool _isLoading = false;

  static const _scopes = [sheets.SheetsApi.spreadsheetsScope];
  static const _sheetId = '1xWPVqwhV4odegfT3ngCvYu8stLP74UAqzQY9IWaCyz0';
  static const _range = 'MeterData!A:M';

  final List<Map<String, String>> _violationTypes = [
    {'value': '1', 'label': 'عدم نصب سر ریز مناسب'},
    {'value': '2', 'label': 'نصب منصوبات غیر مجاز'},
    {'value': '3', 'label': 'اضافه برداشت از مفاد پروانه'},
    {'value': '4', 'label': 'عدم نصب و یا حذف و دستکاری کنتور'},
    {'value': '5', 'label': 'کف شکنی، جابجایی و لایروبی بدون مجوز'},
    {'value': '6', 'label': 'انتقال آب به اراضی غیر آبخور اولیه چاه'},
    {'value': '7', 'label': 'تغییر کاربری مصرف'},
    {'value': '8', 'label': 'فعال نبودن آبیاری تحت فشار و تغییر عنوان'},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.now();
    _updateDateTime();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final loc = await _getCurrentLocation();
      setState(() => _locationController.text = loc);
    } catch (e) {
      setState(() => _locationController.text = 'خطا در دریافت مکان');
    }
  }

  Future<String> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS خاموش است');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('مجوز مکان داده نشد');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('مجوز مکان برای همیشه رد شد');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );

    final dd = DDCoordinates(latitude: pos.latitude, longitude: pos.longitude);
    final utm = UTMCoordinates.fromDD(dd);
    final hemisphere = utm.isSouthernHemisphere ? 'S' : 'N';
    return '${utm.zoneNumber}$hemisphere ${utm.x.toStringAsFixed(0)}E ${utm.y.abs().toStringAsFixed(0)}N';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateDateTime();
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _updateDateTime();
      });
    }
  }

  void _updateDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } else {
      _dateController.text = '';
    }
  }

  void _showViolationTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('انتخاب نوع تخلف'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _violationTypes.length,
                  itemBuilder: (context, index) {
                    final violation = _violationTypes[index];
                    return RadioListTile<String>(
                      title: Text(violation['label']!),
                      value: violation['value']!,
                      groupValue: _selectedViolationType,
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedViolationType = value;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
                ElevatedButton(
                  onPressed: _selectedViolationType != null
                      ? () {
                    setState(() {
                      _violationDescController.clear();
                    });
                    Navigator.pop(context);
                  }
                      : null,
                  child: const Text('تایید'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecordOffline(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList('pending_records') ?? [];
    records.add(jsonEncode(record));
    await prefs.setStringList('pending_records', records);
  }

  Future<void> _sendRecordOnline(Map<String, dynamic> record) async {
    final credentialsJson = await rootBundle.loadString('assets/credentials.json');
    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));
    final client = http.Client();
    final authClient = await clientViaServiceAccount(credentials, _scopes, baseClient: client);

    final sheetsApi = sheets.SheetsApi(authClient);
    final valueRange = sheets.ValueRange(values: [[
      record['date'],
      record['fileClass'],
      record['meterType'],
      record['totalWaterUsed'],
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
    ]]);

    await sheetsApi.spreadsheets.values.append(valueRange, _sheetId, _range,
        valueInputOption: 'RAW');
    authClient.close();
  }

  Future<void> _saveMeterData() async {
    if (_fileClassController.text.isEmpty || _meterType == null || _meterStatus == null) {
      _showSnack('لطفاً کلاسه پرونده، نوع کنتور و وضعیت کنتور را وارد کنید');
      return;
    }

    final record = {
      'date': _dateController.text,
      'fileClass': _fileClassController.text,
      'meterType': _meterType,
      'totalWaterUsed': _totalWaterUsedController.text,
      'waterVolume': _waterVolumeController.text,
      'calculatedFlow': _calculatedFlowController.text,
      'instantFlow': _instantFlowController.text,
      'meterStatus': _meterStatus,
      'hasViolation': _hasViolation ? 'بله' : 'خیر',
      'violationType': _selectedViolationType ?? '',
      'violationDesc': _violationDescController.text,
      'userName': widget.userName,
      'userUnit': widget.userUnit,
      'location': _locationController.text,
    };

    setState(() => _isLoading = true);

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await _saveRecordOffline(record);
      _showSnack('اینترنت قطع است! رکورد آفلاین ذخیره شد.');
    } else {
      try {
        await _sendRecordOnline(record);
        _showSnack('داده‌ها با موفقیت ارسال شدند');
      } catch (e) {
        await _saveRecordOffline(record);
        _showSnack('ارسال ناموفق! رکورد آفلاین ذخیره شد.');
      }
    }

    _clearFields();
    setState(() => _isLoading = false);
  }

  void _clearFields() {
    _fileClassController.clear();
    _totalWaterUsedController.clear();
    _waterVolumeController.clear();
    _calculatedFlowController.clear();
    _instantFlowController.clear();
    _violationDescController.clear();
    _locationController.clear();
    _meterType = null;
    _meterStatus = null;
    _selectedViolationType = null;
    _hasViolation = false;
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _updateDateTime();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchFileClassInfo() async {
    final fileClass = _fileClassController.text.trim();
    if (fileClass.isEmpty) {
      _showSnack('لطفاً کلاسه پرونده را وارد کنید');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credentialsJson = await rootBundle.loadString('assets/credentials.json');
      final credentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));
      final client = http.Client();
      final authClient = await clientViaServiceAccount(credentials, _scopes, baseClient: client);
      final sheetsApi = sheets.SheetsApi(authClient);

      const infoRange = 'Info!A:G';
      final response = await sheetsApi.spreadsheets.values.get(_sheetId, infoRange);
      final rows = response.values;
      if (rows == null || rows.isEmpty) {
        _showSnack('اطلاعاتی در شیت Info یافت نشد');
        return;
      }

      final match = rows.firstWhere(
            (row) => row.isNotEmpty && row[0].toString().trim() == fileClass,
        orElse: () => [],
      );

      if (match.isEmpty) {
        _showSnack('کلاسه پرونده یافت نشد');
      } else {
        final easting = match.length > 1 ? match[1].toString() : '';
        final northing = match.length > 2 ? match[2].toString() : '';
        final q1 = match.length > 3 ? match[3].toString() : '';
        final q2 = match.length > 4 ? match[4].toString() : '';
        final q3 = match.length > 5 ? match[5].toString() : '';
        final usageType = match.length > 6 ? match[6].toString() : '';

        final utmString = '${easting}E ${northing}N';

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('اطلاعات پرونده'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مختصات: $utmString'),
                const Divider(),
                Text('دبی اولیه: $q1'),
                Text('دبی اصلاحی: $q2'),
                Text('دبی پروانه: $q3'),
                const Divider(),
                Text('نوع مصرف: $usageType',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ],
          ),
        );
      }
      authClient.close();
    } catch (e) {
      _showSnack('خطا در خواندن داده‌ها: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendPendingRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList('pending_records') ?? [];
    if (records.isEmpty) {
      _showSnack('هیچ رکورد ذخیره‌شده‌ای وجود ندارد');
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showSnack('اینترنت قطع است، ارسال ممکن نیست');
      return;
    }

    final toRemove = [];
    for (int i = 0; i < records.length; i++) {
      final record = jsonDecode(records[i]) as Map<String, dynamic>;
      try {
        await _sendRecordOnline(record);
        toRemove.add(i);
      } catch (_) {}
    }
    toRemove.sort((b, a) => a.compareTo(b));
    for (var index in toRemove) {
      records.removeAt(index);
    }
    await prefs.setStringList('pending_records', records);

    _showSnack('${toRemove.length} رکورد با موفقیت ارسال شد');
  }

  // 🔹 تابع اصلاح‌شده: URL به فرمت صحیح Google Earth Web تغییر کرد
  Future<void> _openInGoogleEarthApp() async {
    try {
      final locationText = _locationController.text.trim();
      if (locationText.isEmpty || locationText.contains('خطا') || locationText.contains('GPS')) {
        _showSnack('موقعیت معتبر نیست. لطفاً ابتدا موقعیت را دریافت کنید.');
        return;
      }

      final parts = locationText.split(' ');
      if (parts.length < 3) {
        _showSnack('فرمت موقعیت نامعتبر است');
        return;
      }

      final String zoneText = parts[0];
      final int zoneNumber = int.parse(zoneText.substring(0, zoneText.length - 1));
      final bool isSouthern = zoneText.endsWith('S');
      final double easting = double.parse(parts[1].replaceAll('E', ''));
      final double northing = double.parse(parts[2].replaceAll('N', ''));

      final utm = UTMCoordinates(
        zoneNumber: zoneNumber,
        x: easting,
        y: northing,
        isSouthernHemisphere: isSouthern,
      );
      final dd = utm.toDD();

      // 🔹 فرمت URL صحیح برای Google Earth Web (بدون /search/)
      final String earthUrl = 'https://earth.google.com/web/@${dd.latitude},${dd.longitude}';
      final Uri uri = Uri.parse(earthUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnack('لینک در Google Earth Web باز شد. برای اپ، Share > "Open in Earth" بزنید.');
      } else {
        _showSnack('خطا در باز کردن لینک. مرورگر را چک کنید یا اینترنت را بررسی کنید.');
      }
    } catch (e) {
      _showSnack('خطا در تبدیل مختصات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وارد کردن اطلاعات کنتور'),
        backgroundColor: const Color(0xFF1E90FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _resendPendingRecords,
            tooltip: 'ارسال رکوردهای ذخیره‌شده',
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === بخش اسکرول‌شونده ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // تاریخ و ساعت
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'تاریخ و ساعت'),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.calendar_today), onPressed: _selectDate),
                      IconButton(icon: const Icon(Icons.access_time), onPressed: _selectTime),
                    ]),

                    const SizedBox(height: 12),

                    // موقعیت
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'موقعیت (UTM)'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: () async {
                          try {
                            final loc = await _getCurrentLocation();
                            setState(() => _locationController.text = loc);
                          } catch (e) {
                            _showSnack(e.toString());
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 12),

                    // دکمه Google Earth (متن به‌روزرسانی شد)
                    ElevatedButton.icon(
                      onPressed: _openInGoogleEarthApp,
                      icon: const Icon(Icons.public, color: Colors.white),
                      label: const Text('View in Google Earth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Note: The link will open in a browser. For the Earth app, tap Share > "Open in Earth."',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // کلاسه پرونده
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _fileClassController,
                          decoration: const InputDecoration(labelText: 'کلاسه پرونده'),
                          keyboardType: TextInputType.number,
                          maxLength: 7,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: 'دریافت اطلاعات پرونده از Google Sheets',
                        onPressed: _fetchFileClassInfo,
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // نوع کنتور
                    DropdownButtonFormField<String>(
                      value: _meterType,
                      decoration: const InputDecoration(labelText: 'نوع کنتور'),
                      items: const [
                        DropdownMenuItem(value: 'هوشمند آب و برق', child: Text('هوشمند آب و برق')),
                        DropdownMenuItem(value: 'هوشمند حجمی', child: Text('هوشمند حجمی')),
                        DropdownMenuItem(value: 'سایر', child: Text('سایر')),
                      ],
                      onChanged: (v) => setState(() => _meterType = v),
                    ),

                    const SizedBox(height: 16),

                    // وضعیت کنتور
                    DropdownButtonFormField<String>(
                      value: _meterStatus,
                      decoration: const InputDecoration(
                        labelText: 'وضعیت کنتور',
                        prefixIcon: Icon(Icons.settings),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'سالم', child: Text('سالم')),
                        DropdownMenuItem(value: 'خراب', child: Text('خراب')),
                      ],
                      onChanged: (v) => setState(() => _meterStatus = v),
                    ),

                    const SizedBox(height: 16),

                    // فیلدهای عددی
                    TextField(
                      controller: _totalWaterUsedController,
                      decoration: const InputDecoration(labelText: 'آب مصرفی کل (m³)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _waterVolumeController,
                      decoration: const InputDecoration(labelText: 'حجم آب باقیمانده (m³)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _calculatedFlowController,
                      decoration: const InputDecoration(labelText: 'دبی محاسبه‌شده (L/s)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _instantFlowController,
                      decoration: const InputDecoration(labelText: 'دبی لحظه‌ای (L/s)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 20),

                    // تخلف
                    Row(children: [
                      Checkbox(
                        value: _hasViolation,
                        onChanged: (v) {
                          setState(() {
                            _hasViolation = v ?? false;
                            if (!(_hasViolation ?? false)) {
                              _selectedViolationType = null;
                              _violationDescController.clear();
                            }
                          });
                        },
                      ),
                      const Icon(Icons.warning, color: Colors.orange),
                      const Text('آیا تخلف دارد؟'),
                    ]),

                    if (_hasViolation) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.list_alt, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text('نوع تخلف:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _showViolationTypeDialog,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedViolationType != null ? Colors.green : Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _selectedViolationType != null
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedViolationType != null
                                            ? _violationTypes
                                            .firstWhere((v) => v['value'] == _selectedViolationType)
                                            .values
                                            .last
                                            : 'لطفاً نوع تخلف را انتخاب کنید',
                                        style: TextStyle(
                                          color: _selectedViolationType != null
                                              ? Colors.green[800]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Colors.orange),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _violationDescController,
                        decoration: const InputDecoration(
                          labelText: 'توضیحات تخلف',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // === فوتر ثابت با دکمه ارسال ===
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveMeterData,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF1E90FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ارسال',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}