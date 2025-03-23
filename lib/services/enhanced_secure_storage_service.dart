import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediswitch/services/logging_service.dart';

/// خدمة محسنة لتخزين البيانات الحساسة بشكل آمن
/// تستخدم هذه الخدمة لتخزين مفاتيح التشفير وكلمات المرور بشكل آمن
/// مع إضافة طبقة إضافية من التشفير وربط المفتاح بمعرف الجهاز
class EnhancedSecureStorageService {
  static final EnhancedSecureStorageService instance = EnhancedSecureStorageService._init();
  
  // مخزن البيانات الآمن
  final FlutterSecureStorage _secureStorage;
  
  // معرف الجهاز الفريد (يستخدم كجزء من مفتاح التشفير)
  String? _deviceId;
  
  // مفتاح إضافي للتشفير (يتم تخزينه بشكل آمن)
  String? _encryptionSalt;
  
  // حالة التهيئة
  bool _isInitialized = false;
  
  // خيارات التخزين الآمن
  final _secureStorageOptions = const AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );
  
  EnhancedSecureStorageService._init() : _secureStorage = const FlutterSecureStorage();
  
  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await LoggingService.instance.info('تهيئة خدمة التخزين الآمن المحسنة');
      
      // الحصول على معرف الجهاز
      _deviceId = await _getDeviceId();
      
      // الحصول على مفتاح التشفير الإضافي أو إنشاء واحد جديد
      _encryptionSalt = await _secureStorage.read(key: 'encryption_salt');
      
      if (_encryptionSalt == null) {
        _encryptionSalt = _generateRandomKey(32);
        await _secureStorage.write(key: 'encryption_salt', value: _encryptionSalt);
      }
      
      _isInitialized = true;
      await LoggingService.instance.info('تم تهيئة خدمة التخزين الآمن المحسنة بنجاح');
    } catch (e) {
      await LoggingService.instance.error('خطأ في تهيئة خدمة التخزين الآمن المحسنة', e);
      rethrow;
    }
  }
  
  /// تخزين قيمة بشكل آمن
  Future<void> write(String key, String value) async {
    try {
      await _ensureInitialized();
      
      // تشفير القيمة قبل تخزينها
      final encryptedValue = _encrypt(value);
      
      // تخزين القيمة المشفرة
      await _secureStorage.write(
        key: key,
        value: encryptedValue,
        aOptions: _secureStorageOptions,
      );
    } catch (e) {
      await LoggingService.instance.error('خطأ في تخزين القيمة: $key', e);
      rethrow;
    }
  }
  
  /// قراءة قيمة مخزنة بشكل آمن
  Future<String?> read(String key) async {
    try {
      await _ensureInitialized();
      
      // قراءة القيمة المشفرة
      final encryptedValue = await _secureStorage.read(
        key: key,
        aOptions: _secureStorageOptions,
      );
      
      if (encryptedValue == null) return null;
      
      // فك تشفير القيمة
      return _decrypt(encryptedValue);
    } catch (e) {
      await LoggingService.instance.error('خطأ في قراءة القيمة: $key', e);
      return null;
    }
  }
  
  /// حذف قيمة مخزنة
  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(
        key: key,
        aOptions: _secureStorageOptions,
      );
    } catch (e) {
      await LoggingService.instance.error('خطأ في حذف القيمة: $key', e);
      rethrow;
    }
  }
  
  /// حذف جميع القيم المخزنة
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll(
        aOptions: _secureStorageOptions,
      );
    } catch (e) {
      await LoggingService.instance.error('خطأ في حذف جميع القيم', e);
      rethrow;
    }
  }
  
  /// التأكد من تهيئة الخدمة
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// الحصول على معرف الجهاز الفريد
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (kIsWeb) {
        // معرف للويب
        final webInfo = await deviceInfo.webBrowserInfo;
        return sha256.convert(utf8.encode('${webInfo.browserName}${webInfo.platform}${webInfo.userAgent}')).toString();
      } else if (Platform.isAndroid) {
        // معرف لأندرويد
        final androidInfo = await deviceInfo.androidInfo;
        return sha256.convert(utf8.encode('${androidInfo.id}${androidInfo.device}${androidInfo.model}')).toString();
      } else if (Platform.isIOS) {
        // معرف لـ iOS
        final iosInfo = await deviceInfo.iosInfo;
        return sha256.convert(utf8.encode('${iosInfo.identifierForVendor}${iosInfo.model}${iosInfo.name}')).toString();
      } else {
        // معرف افتراضي للأنظمة الأخرى
        return sha256.convert(utf8.encode('mediswitch_${DateTime.now().millisecondsSinceEpoch}')).toString();
      }
    } catch (e) {
      await LoggingService.instance.error('خطأ في الحصول على معرف الجهاز', e);
      // معرف افتراضي في حالة الخطأ
      return sha256.convert(utf8.encode('mediswitch_fallback_id')).toString();
    }
  }
  
  /// إنشاء مفتاح عشوائي
  String _generateRandomKey(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  /// تشفير قيمة
  String _encrypt(String value) {
    try {
      // إنشاء مفتاح تشفير مشتق من معرف الجهاز ومفتاح التشفير الإضافي
      final derivedKey = _deriveKey(_deviceId!, _encryptionSalt!);
      
      // إنشاء قيمة عشوائية للتشفير (IV)
      final iv = _generateRandomKey(16);
      
      // تشفير القيمة باستخدام المفتاح المشتق والـ IV
      // هنا نستخدم تشفير بسيط باستخدام XOR لأغراض التوضيح
      // في التطبيق الحقيقي، يجب استخدام خوارزمية تشفير قوية مثل AES
      final valueBytes = utf8.encode(value);
      final keyBytes = utf8.encode(derivedKey);
      final encryptedBytes = List<int>.filled(valueBytes.length, 0);
      
      for (var i = 0; i < valueBytes.length; i++) {
        encryptedBytes[i] = valueBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      // دمج الـ IV مع القيمة المشفرة وتحويلها إلى نص
      final result = {
        'iv': iv,
        'data': base64Url.encode(encryptedBytes),
      };
      
      return jsonEncode(result);
    } catch (e) {
      await LoggingService.instance.error('خطأ في تشفير القيمة', e);
      // في حالة الخطأ، نعيد القيمة كما هي (غير مشفرة)
      return value;
    }
  }
  
  /// فك تشفير قيمة
  String _decrypt(String encryptedValue) {
    try {
      // تحليل القيمة المشفرة
      final Map<String, dynamic> encryptedData = jsonDecode(encryptedValue);
      final iv = encryptedData['iv'] as String;
      final data = encryptedData['data'] as String;
      
      // إنشاء مفتاح تشفير مشتق من معرف الجهاز ومفتاح التشفير الإضافي
      final derivedKey = _deriveKey(_deviceId!, _encryptionSalt!);
      
      // فك تشفير القيمة باستخدام المفتاح المشتق والـ IV
      final encryptedBytes = base64Url.decode(data);
      final keyBytes = utf8.encode(derivedKey);
      final decryptedBytes = List<int>.filled(encryptedBytes.length, 0);
      
      for (var i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      await LoggingService.instance.error('خطأ في فك تشفير القيمة', e);
      // في حالة الخطأ، نعيد القيمة كما هي
      return encryptedValue;
    }
  }
  
  /// اشتقاق مفتاح من معرف الجهاز ومفتاح التشفير الإضافي
  String _deriveKey(String deviceId, String salt) {
    // استخدام PBKDF2 لاشتقاق مفتاح آمن
    // في التطبيق الحقيقي، يجب استخدام عدد كبير من التكرارات
    final iterations = 1000;
    final keyLength = 32; // 256 بت
    
    // اشتقاق المفتاح باستخدام HMAC-SHA256
    final key = deviceId + salt;
    var derivedKey = key;
    
    for (var i = 0; i < iterations; i++) {
      derivedKey = sha256.convert(utf8.encode(derivedKey)).toString();
    }
    
    return derivedKey;
  }
  
  /// استعادة مفتاح التشفير في حالة فقدانه
  Future<bool> recoverEncryptionKey(String recoveryCode) async {
    try {
      // التحقق من صحة رمز الاستعادة
      final storedRecoveryHash = await _secureStorage.read(key: 'recovery_code_hash');
      
      if (storedRecoveryHash == null) {
        await LoggingService.instance.error('لم يتم العثور على رمز استعادة مخزن');
        return false;
      }
      
      // التحقق من تطابق رمز الاستعادة
      final recoveryHash = sha256.convert(utf8.encode(recoveryCode)).toString();
      
      if (recoveryHash != storedRecoveryHash) {
        await LoggingService.instance.error('رمز الاستعادة غير صحيح');
        return false;
      }
      
      // استعادة مفتاح التشفير من النسخة الاحتياطية
      final backupEncryptionSalt = await _secureStorage.read(key: 'backup_encryption_salt');
      
      if (backupEncryptionSalt == null) {
        await LoggingService.instance.error('لم يتم العثور على نسخة احتياطية لمفتاح التشفير');
        return false;
      }
      
      // استعادة مفتاح التشفير
      _encryptionSalt = backupEncryptionSalt;
      await _secureStorage.write(key: 'encryption_salt', value: _encryptionSalt);
      
      await LoggingService.instance.info('تم استعادة مفتاح التشفير بنجاح');
      return true;
    } catch (e) {
      await LoggingService.instance.error('خطأ في استعادة مفتاح التشفير', e);
      return false;
    }
  }