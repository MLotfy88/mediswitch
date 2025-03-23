import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// خدمة تسجيل الأحداث لتتبع الأخطاء وتحسين الأداء
class LoggingService {
  static final LoggingService instance = LoggingService._init();
  
  // مستويات التسجيل
  static const int LEVEL_DEBUG = 0;
  static const int LEVEL_INFO = 1;
  static const int LEVEL_WARNING = 2;
  static const int LEVEL_ERROR = 3;
  static const int LEVEL_CRITICAL = 4;
  
  // الحد الأقصى لحجم ملف السجل بالبايت (5 ميجابايت)
  static const int MAX_LOG_SIZE = 5 * 1024 * 1024;
  
  // عدد ملفات السجل القديمة للاحتفاظ بها
  static const int MAX_LOG_FILES = 5;
  
  // مسار ملف السجل الحالي
  String? _logFilePath;
  
  // مستوى التسجيل الحالي
  int _currentLogLevel = LEVEL_INFO;
  
  // تمكين/تعطيل التسجيل
  bool _loggingEnabled = true;
  
  LoggingService._init();
  
  /// تهيئة خدمة التسجيل
  Future<void> initialize({int logLevel = LEVEL_INFO, bool enabled = true}) async {
    _currentLogLevel = logLevel;
    _loggingEnabled = enabled;
    
    if (_loggingEnabled) {
      await _initLogFile();
      await _cleanupOldLogs();
      
      // تسجيل بدء التطبيق
      await info('===== بدء تشغيل التطبيق =====');
      await info('إصدار التطبيق: 1.0.0');
      await info('نظام التشغيل: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    }
  }
  
  /// تهيئة ملف السجل
  Future<void> _initLogFile() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final logsDir = join(documentsDirectory.path, 'logs');
      
      // إنشاء مجلد السجلات إذا لم يكن موجودًا
      final logsDirFolder = Directory(logsDir);
      if (!await logsDirFolder.exists()) {
        await logsDirFolder.create(recursive: true);
      }
      
      // إنشاء ملف سجل جديد بتاريخ اليوم
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _logFilePath = join(logsDir, 'mediswitch_$dateStr.log');
      
      // التحقق من حجم ملف السجل الحالي
      final logFile = File(_logFilePath!);
      if (await logFile.exists()) {
        final fileSize = await logFile.length();
        if (fileSize > MAX_LOG_SIZE) {
          // إذا كان حجم الملف كبيرًا، قم بإنشاء ملف جديد
          final timestamp = now.millisecondsSinceEpoch;
          _logFilePath = join(logsDir, 'mediswitch_${dateStr}_$timestamp.log');
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء تهيئة ملف السجل: $e');
    }
  }
  
  /// تنظيف ملفات السجل القديمة
  Future<void> _cleanupOldLogs() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final logsDir = join(documentsDirectory.path, 'logs');
      
      final logsDirFolder = Directory(logsDir);
      if (!await logsDirFolder.exists()) {
        return;
      }
      
      // الحصول على قائمة ملفات السجل
      final logFiles = await logsDirFolder
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .toList();
      
      // ترتيب الملفات حسب تاريخ التعديل (الأقدم أولاً)
      logFiles.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });
      
      // حذف الملفات القديمة إذا كان عددها أكبر من الحد الأقصى
      if (logFiles.length > MAX_LOG_FILES) {
        final filesToDelete = logFiles.sublist(0, logFiles.length - MAX_LOG_FILES);
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء تنظيف ملفات السجل القديمة: $e');
    }
  }
  
  /// تسجيل رسالة تصحيح
  Future<void> debug(String message) async {
    if (_loggingEnabled && _currentLogLevel <= LEVEL_DEBUG) {
      await _writeLog('DEBUG', message);
    }
  }
  
  /// تسجيل رسالة معلومات
  Future<void> info(String message) async {
    if (_loggingEnabled && _currentLogLevel <= LEVEL_INFO) {
      await _writeLog('INFO', message);
    }
  }
  
  /// تسجيل رسالة تحذير
  Future<void> warning(String message) async {
    if (_loggingEnabled && _currentLogLevel <= LEVEL_WARNING) {
      await _writeLog('WARNING', message);
    }
  }
  
  /// تسجيل رسالة خطأ
  Future<void> error(String message, [dynamic error, StackTrace? stackTrace]) async {
    if (_loggingEnabled && _currentLogLevel <= LEVEL_ERROR) {
      String logMessage = message;
      
      if (error != null) {
        logMessage += '\nError: $error';
      }
      
      if (stackTrace != null) {
        logMessage += '\nStackTrace: $stackTrace';
      }
      
      await _writeLog('ERROR', logMessage);
    }
  }
  
  /// تسجيل رسالة خطأ حرج
  Future<void> critical(String message, [dynamic error, StackTrace? stackTrace]) async {
    if (_loggingEnabled && _currentLogLevel <= LEVEL_CRITICAL) {
      String logMessage = message;
      
      if (error != null) {
        logMessage += '\nError: $error';
      }
      
      if (stackTrace != null) {
        logMessage += '\nStackTrace: $stackTrace';
      }
      
      await _writeLog('CRITICAL', logMessage);
    }
  }
  
  /// كتابة رسالة في ملف السجل
  Future<void> _writeLog(String level, String message) async {
    try {
      if (_logFilePath == null) {
        await _initLogFile();
      }
      
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
      
      final logMessage = '[$timestamp] [$level] $message\n';
      
      final logFile = File(_logFilePath!);
      await logFile.writeAsString(logMessage, mode: FileMode.append);
      
      // طباعة الرسالة في وحدة التحكم أيضًا للتصحيح
      debugPrint(logMessage);
      
      // التحقق من حجم ملف السجل
      final fileSize = await logFile.length();
      if (fileSize > MAX_LOG_SIZE) {
        await _initLogFile(); // إنشاء ملف سجل جديد
      }
    } catch (e) {
      debugPrint('خطأ أثناء كتابة السجل: $e');
    }
  }
  
  /// الحصول على محتوى ملف السجل الحالي
  Future<String> getCurrentLogContent() async {
    try {
      if (_logFilePath == null) {
        return '';
      }
      
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        return '';
      }
      
      return await logFile.readAsString();
    } catch (e) {
      debugPrint('خطأ أثناء قراءة ملف السجل: $e');
      return '';
    }
  }
  
  /// مشاركة ملف السجل الحالي
  Future<bool> shareCurrentLog() async {
    try {
      if (_logFilePath == null) {
        return false;
      }
      
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        return false;
      }
      
      // استخدام حزمة share_plus لمشاركة الملف
      await Share.shareXFiles([XFile(_logFilePath!)], text: 'سجل تطبيق MediSwitch');
      
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء مشاركة ملف السجل: $e');
      return false;
    }
  }
  
  /// حذف جميع ملفات السجل
  Future<bool> clearAllLogs() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final logsDir = join(documentsDirectory.path, 'logs');
      
      final logsDirFolder = Directory(logsDir);
      if (!await logsDirFolder.exists()) {
        return true;
      }
      
      // حذف جميع ملفات السجل
      await for (final entity in logsDirFolder.list()) {
        if (entity is File && entity.path.endsWith('.log')) {
          await entity.delete();
        }
      }
      
      // إعادة تهيئة ملف السجل
      await _initLogFile();
      
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء حذف ملفات السجل: $e');
      return false;
    }
  }
  
  /// تسجيل استخدام ميزة في التطبيق
  Future<void> logFeatureUsage(String featureName) async {
    await info('استخدام ميزة: $featureName');
  }
  
  /// تسجيل أداء عملية
  Future<void> logPerformance(String operation, int durationMs) async {
    await info('أداء العملية: $operation - استغرقت $durationMs مللي ثانية');
  }
  
  /// تسجيل خطأ في الشبكة
  Future<void> logNetworkError(String url, int statusCode, String message) async {
    await error('خطأ في الشبكة: $url - الحالة: $statusCode - الرسالة: $message');
  }
}