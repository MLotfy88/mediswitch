import 'dart:io';
import 'dart:convert';
import 'package:mediswitch/services/excel_import_service.dart';
import 'package:mediswitch/services/logging_service.dart';
import 'package:mediswitch/services/backup_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تحديث البيانات من ملفات Excel/CSV وتحديثات التطبيق
class UpdateService {
  static final UpdateService instance = UpdateService._init();
  
  // المعرف الفريد للإصدار الحالي من قاعدة البيانات
  String? _currentDatabaseVersion;
  
  // تاريخ آخر تحديث
  DateTime? _lastUpdateCheck;
  
  // الفاصل الزمني بين التحديثات (7 أيام افتراضيًا)
  static const int DEFAULT_UPDATE_INTERVAL_DAYS = 7;
  
  // عنوان URL للتحقق من التحديثات
  static const String UPDATE_CHECK_URL = 'https://api.mediswitch.app/updates/check';
  
  // عنوان URL لتنزيل ملف التحديث
  static const String UPDATE_DOWNLOAD_URL = 'https://api.mediswitch.app/updates/download';
  
  UpdateService._init();
  
  /// تهيئة خدمة التحديث
  Future<void> initialize() async {
    try {
      await _loadSavedState();
      await LoggingService.instance.info('تم تهيئة خدمة التحديث');
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء تهيئة خدمة التحديث', e);
    }
  }
  
  /// تحميل الحالة المحفوظة
  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل إصدار قاعدة البيانات الحالي
      _currentDatabaseVersion = prefs.getString('current_database_version');
      
      // تحميل تاريخ آخر تحديث
      final lastUpdateTimestamp = prefs.getInt('last_update_check');
      if (lastUpdateTimestamp != null) {
        _lastUpdateCheck = DateTime.fromMillisecondsSinceEpoch(lastUpdateTimestamp);
      }
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء تحميل حالة التحديث', e);
    }
  }
  
  /// حفظ الحالة الحالية
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ إصدار قاعدة البيانات الحالي
      if (_currentDatabaseVersion != null) {
        await prefs.setString('current_database_version', _currentDatabaseVersion!);
      }
      
      // حفظ تاريخ آخر تحديث
      if (_lastUpdateCheck != null) {
        await prefs.setInt('last_update_check', _lastUpdateCheck!.millisecondsSinceEpoch);
      }
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء حفظ حالة التحديث', e);
    }
  }
  
  /// التحقق من وجود تحديثات جديدة
  Future<Map<String, dynamic>> checkForUpdates({bool forceCheck = false}) async {
    try {
      // التحقق مما إذا كان الوقت قد حان للتحقق من التحديثات
      final now = DateTime.now();
      
      if (!forceCheck && _lastUpdateCheck != null) {
        final daysSinceLastCheck = now.difference(_lastUpdateCheck!).inDays;
        
        if (daysSinceLastCheck < DEFAULT_UPDATE_INTERVAL_DAYS) {
          return {
            'has_update': false,
            'message': 'تم التحقق من التحديثات مؤخرًا',
            'days_until_next_check': DEFAULT_UPDATE_INTERVAL_DAYS - daysSinceLastCheck
          };
        }
      }
      
      // تحديث تاريخ آخر تحقق
      _lastUpdateCheck = now;
      await _saveState();
      
      // إرسال طلب للتحقق من التحديثات
      final response = await http.post(
        Uri.parse(UPDATE_CHECK_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_version': _currentDatabaseVersion ?? 'unknown',
          'app_version': '1.0.0', // يجب استبداله بإصدار التطبيق الفعلي
          'platform': Platform.operatingSystem,
          'device_id': await _getDeviceId()
        })
      );
      
      if (response.statusCode != 200) {
        throw Exception('فشل التحقق من التحديثات: ${response.statusCode}');
      }
      
      final updateInfo = jsonDecode(response.body);
      
      // تسجيل نتيجة التحقق من التحديثات
      if (updateInfo['has_update']) {
        await LoggingService.instance.info('تم العثور على تحديث جديد: ${updateInfo['version']}');
      } else {
        await LoggingService.instance.info('لا توجد تحديثات جديدة');
      }
      
      return updateInfo;
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء التحقق من التحديثات', e);
      
      return {
        'has_update': false,
        'message': 'حدث خطأ أثناء التحقق من التحديثات: $e',
        'error': e.toString()
      };
    }
  }
  
  /// تنزيل وتثبيت التحديث
  Future<Map<String, dynamic>> downloadAndInstallUpdate(String updateUrl, String version) async {
    try {
      await LoggingService.instance.info('بدء تنزيل التحديث: $version');
      
      // إنشاء نسخة احتياطية قبل التحديث
      await BackupService.instance.createBackup(customName: 'pre_update_backup');
      
      // تنزيل ملف التحديث
      final response = await http.get(Uri.parse(updateUrl));
      
      if (response.statusCode != 200) {
        throw Exception('فشل تنزيل التحديث: ${response.statusCode}');
      }
      
      // حفظ الملف المؤقت
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = join(tempDir.path, 'update_$version.csv');
      
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(response.bodyBytes);
      
      // استيراد البيانات من الملف
      final importResult = await ExcelImportService.instance.importFromCsv(tempFilePath);
      
      // حذف الملف المؤقت بعد الاستيراد
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (!importResult['success']) {
        throw Exception('فشل استيراد البيانات: ${importResult['message']}');
      }
      
      // تحديث إصدار قاعدة البيانات الحالي
      _currentDatabaseVersion = version;
      await _saveState();
      
      await LoggingService.instance.info('تم تثبيت التحديث بنجاح: $version');
      
      return {
        'success': true,
        'message': 'تم تثبيت التحديث بنجاح',
        'version': version,
        'imported_count': importResult['imported_count']
      };
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء تنزيل وتثبيت التحديث', e);
      
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تنزيل وتثبيت التحديث: $e',
        'error': e.toString()
      };
    }
  }
  
  /// استيراد البيانات من ملف محلي
  Future<Map<String, dynamic>> importFromLocalFile(String filePath) async {
    try {
      await LoggingService.instance.info('بدء استيراد البيانات من ملف محلي: $filePath');
      
      // إنشاء نسخة احتياطية قبل الاستيراد
      await BackupService.instance.createBackup(customName: 'pre_import_backup');
      
      // التحقق من نوع الملف
      final fileExtension = extension(filePath).toLowerCase();
      Map<String, dynamic> importResult;
      
      if (fileExtension == '.xlsx' || fileExtension == '.xls') {
        // استيراد من ملف Excel
        importResult = await ExcelImportService.instance.importFromExcel(filePath);
      } else if (fileExtension == '.csv') {
        // استيراد من ملف CSV
        importResult = await ExcelImportService.instance.importFromCsv(filePath);
      } else {
        throw Exception('نوع الملف غير مدعوم: $fileExtension');
      }
      
      if (!importResult['success']) {
        throw Exception('فشل استيراد البيانات: ${importResult['message']}');
      }
      
      // تحديث إصدار قاعدة البيانات الحالي
      _currentDatabaseVersion = DateTime.now().toIso8601String();
      await _saveState();
      
      await LoggingService.instance.info('تم استيراد البيانات بنجاح: ${importResult['imported_count']} دواء');
      
      return importResult;
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء استيراد البيانات من ملف محلي', e);
      
      return {
        'success': false,
        'message': 'حدث خطأ أثناء استيراد البيانات: $e',
        'error': e.toString()
      };
    }
  }
  
  /// التحقق من صحة ملف قبل الاستيراد
  Future<Map<String, dynamic>> validateFile(String filePath) async {
    try {
      await LoggingService.instance.info('التحقق من صحة الملف: $filePath');
      
      // استخدام خدمة استيراد Excel للتحقق من صحة الملف
      final validationResult = await ExcelImportService.instance.validateFile(filePath);
      
      return validationResult;
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء التحقق من صحة الملف', e);
      
      return {
        'valid': false,
        'message': 'حدث خطأ أثناء التحقق من صحة الملف: $e',
        'error': e.toString()
      };
    }
  }
  
  /// الحصول على معرف الجهاز
  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');
      
      if (deviceId == null) {
        // إنشاء معرف جديد
        final random = List<int>.generate(16, (i) => DateTime.now().millisecondsSinceEpoch % 255);
        deviceId = base64Url.encode(random);
        
        // حفظ المعرف
        await prefs.setString('device_id', deviceId);
      }
      
      return deviceId;
    } catch (e) {
      await LoggingService.instance.error('خطأ أثناء الحصول على معرف الجهاز', e);
      return 'unknown_device';
    }
  }
  
  /// جدولة التحقق التلقائي من التحديثات
  Future<bool> scheduleAutomaticUpdateCheck() async {
    try {
      final now = DateTime.now();
      
      // التحقق مما إذا كان الوقت قد حان للتحقق من التحديثات
      if (_lastUpdateCheck != null) {
        final daysSinceLastCheck = now.difference(_lastUpdateCheck!).inDays;
        
        if (daysSinceLastCheck >= DEFAULT_UPDATE_INTERVAL_DAYS) {
          // التحقق من التحديثات
          final updateInfo = await checkForUpdates();
          
          return updateInfo['has_update'] ?? false;
        }
      } else {
        // إذا لم يتم التحقق من قبل، قم بالتحقق الآن
        final updateInfo = await checkForUpdates();
        
        return updateInfo['has_update'] ?? false;
      }