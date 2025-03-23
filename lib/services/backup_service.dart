import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';

/// خدمة النسخ الاحتياطي واستعادة البيانات
class BackupService {
  static final BackupService instance = BackupService._init();
  
  BackupService._init();
  
  /// إنشاء نسخة احتياطية مشفرة
  Future<Map<String, dynamic>> createBackup({String? customName, bool compress = true}) async {
    try {
      // استخدام خدمة قاعدة البيانات لإنشاء نسخة احتياطية
      final backupCreated = await DatabaseService.instance.createBackup(customName: customName);
      
      if (!backupCreated) {
        return {
          'success': false,
          'message': 'فشل إنشاء النسخة الاحتياطية',
          'backup_path': null
        };
      }
      
      // الحصول على قائمة النسخ الاحتياطية
      final backups = await DatabaseService.instance.getBackups();
      
      if (backups.isEmpty) {
        return {
          'success': false,
          'message': 'لم يتم العثور على نسخ احتياطية',
          'backup_path': null
        };
      }
      
      // الحصول على أحدث نسخة احتياطية
      final latestBackup = backups.first;
      final metadataPath = '$latestBackup.meta';
      
      // قراءة بيانات التعريف
      Map<String, dynamic> metadata = {};
      final metadataFile = File(metadataPath);
      
      if (await metadataFile.exists()) {
        metadata = jsonDecode(await metadataFile.readAsString());
      }
      
      // ضغط النسخة الاحتياطية إذا كان مطلوبًا
      String finalBackupPath = latestBackup;
      
      if (compress) {
        finalBackupPath = await _compressBackup(latestBackup, metadataPath);
      }
      
      return {
        'success': true,
        'message': 'تم إنشاء النسخة الاحتياطية بنجاح',
        'backup_path': finalBackupPath,
        'metadata': metadata
      };
    } catch (e) {
      debugPrint('خطأ أثناء إنشاء النسخة الاحتياطية: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء إنشاء النسخة الاحتياطية: $e',
        'backup_path': null
      };
    }
  }
  
  /// استعادة البيانات من نسخة احتياطية
  Future<Map<String, dynamic>> restoreBackup(String backupPath) async {
    try {
      // التحقق من نوع ملف النسخة الاحتياطية
      final fileExtension = extension(backupPath).toLowerCase();
      
      // إذا كان الملف مضغوطًا، قم بفك الضغط أولاً
      if (fileExtension == '.zip') {
        final extractedPath = await _extractBackup(backupPath);
        if (extractedPath == null) {
          return {
            'success': false,
            'message': 'فشل فك ضغط ملف النسخة الاحتياطية',
          };
        }
        backupPath = extractedPath;
      }
      
      // استعادة البيانات باستخدام خدمة قاعدة البيانات
      final restored = await DatabaseService.instance.restoreFromBackup(backupPath);
      
      if (!restored) {
        return {
          'success': false,
          'message': 'فشل استعادة البيانات من النسخة الاحتياطية',
        };
      }
      
      return {
        'success': true,
        'message': 'تم استعادة البيانات بنجاح',
      };
    } catch (e) {
      debugPrint('خطأ أثناء استعادة البيانات: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء استعادة البيانات: $e',
      };
    }
  }
  
  /// مشاركة النسخة الاحتياطية
  Future<bool> shareBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      
      if (!await file.exists()) {
        return false;
      }
      
      // مشاركة الملف
      await Share.shareXFiles([XFile(backupPath)], text: 'نسخة احتياطية من تطبيق MediSwitch');
      
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء مشاركة النسخة الاحتياطية: $e');
      return false;
    }
  }
  
  /// الحصول على قائمة النسخ الاحتياطية مع البيانات الوصفية
  Future<List<Map<String, dynamic>>> getBackupsWithMetadata() async {
    try {
      final backupPaths = await DatabaseService.instance.getBackups();
      final backupsWithMetadata = <Map<String, dynamic>>[];
      
      for (final backupPath in backupPaths) {
        final metadataPath = '$backupPath.meta';
        final metadataFile = File(metadataPath);
        
        Map<String, dynamic> metadata = {
          'name': basename(backupPath),
          'timestamp': File(backupPath).lastModifiedSync().millisecondsSinceEpoch,
          'size': await File(backupPath).length(),
        };
        
        if (await metadataFile.exists()) {
          try {
            final metadataJson = jsonDecode(await metadataFile.readAsString());
            metadata.addAll(metadataJson);
          } catch (e) {
            debugPrint('خطأ أثناء قراءة بيانات التعريف: $e');
          }
        }
        
        backupsWithMetadata.add({
          'path': backupPath,
          'metadata': metadata,
        });
      }
      
      // ترتيب النسخ الاحتياطية حسب التاريخ (الأحدث أولاً)
      backupsWithMetadata.sort((a, b) {
        final aTimestamp = a['metadata']['timestamp'] as int;
        final bTimestamp = b['metadata']['timestamp'] as int;
        return bTimestamp.compareTo(aTimestamp);
      });
      
      return backupsWithMetadata;
    } catch (e) {
      debugPrint('خطأ أثناء الحصول على قائمة النسخ الاحتياطية: $e');
      return [];
    }
  }
  
  /// الحصول على قائمة النسخ الاحتياطية
  Future<List<String>> getBackups() async {
    try {
      return await DatabaseService.instance.getBackups();
    } catch (e) {
      debugPrint('خطأ أثناء الحصول على قائمة النسخ الاحتياطية: $e');
      return [];
    }
  }
  
  /// حذف نسخة احتياطية
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      final metadataFile = File('$backupPath.meta');
      
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء حذف النسخة الاحتياطية: $e');
      return false;
    }
  }
  
  /// ضغط ملف النسخة الاحتياطية والبيانات الوصفية
  Future<String> _compressBackup(String backupPath, String metadataPath) async {
    try {
      final archive = Archive();
      
      // إضافة ملف قاعدة البيانات إلى الأرشيف
      final dbFile = File(backupPath);
      final dbBytes = await dbFile.readAsBytes();
      final dbFileName = basename(backupPath);
      final dbArchiveFile = ArchiveFile(dbFileName, dbBytes.length, dbBytes);
      archive.addFile(dbArchiveFile);
      
      // إضافة ملف البيانات الوصفية إلى الأرشيف
      final metaFile = File(metadataPath);
      if (await metaFile.exists()) {
        final metaBytes = await metaFile.readAsBytes();
        final metaFileName = basename(metadataPath);
        final metaArchiveFile = ArchiveFile(metaFileName, metaBytes.length, metaBytes);
        archive.addFile(metaArchiveFile);
      }
      
      // ضغط الأرشيف
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      
      if (zipData == null) {
        throw Exception('فشل ضغط ملفات النسخة الاحتياطية');
      }
      
      // حفظ الملف المضغوط
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupDir = join(documentsDirectory.path, 'backups');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipPath = join(backupDir, 'mediswitch_backup_$timestamp.zip');
      
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipData);
      
      return zipPath;
    } catch (e) {
      debugPrint('خطأ أثناء ضغط النسخة الاحتياطية: $e');
      // إذا فشل الضغط، نعيد مسار الملف الأصلي
      return backupPath;
    }
  }
  
  /// فك ضغط ملف النسخة الاحتياطية
  Future<String?> _extractBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      
      // فك ضغط الأرشيف
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // البحث عن ملف قاعدة البيانات في الأرشيف
      final dbFile = archive.findFile((file) => file.name.endsWith('.db'));
      
      if (dbFile == null) {
        throw Exception('لم يتم العثور على ملف قاعدة البيانات في النسخة الاحتياطية');
      }
      
      // استخراج ملف قاعدة البيانات
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupDir = join(documentsDirectory.path, 'backups');
      final extractDir = join(backupDir, 'extracted_${DateTime.now().millisecondsSinceEpoch}');
      
      // إنشاء مجلد الاستخراج إذا لم يكن موجودًا
      final extractDirFolder = Directory(extractDir);
      if (!await extractDirFolder.exists()) {
        await extractDirFolder.create(recursive: true);
      }
      
      // استخراج ملف قاعدة البيانات
      final extractedDbPath = join(extractDir, dbFile.name);
      final extractedDbFile = File(extractedDbPath);
      await extractedDbFile.writeAsBytes(dbFile.content as List<int>);
      
      // استخراج ملف البيانات الوصفية إذا كان موجودًا
      final metaFile = archive.findFile((file) => file.name.endsWith('.meta'));
      
      if (metaFile != null) {
        final extractedMetaPath = join(extractDir, metaFile.name);
        final extractedMetaFile = File(extractedMetaPath);
        await extractedMetaFile.writeAsBytes(metaFile.content as List<int>);
      }
      
      return extractedDbPath;
    } catch (e) {
      debugPrint('خطأ أثناء فك ضغط النسخة الاحتياطية: $e');
      return null;
    }
  }
  
  /// تنظيف النسخ الاحتياطية القديمة
  Future<bool> cleanupOldBackups({int keepCount = 5}) async {
    try {
      final backups = await getBackupsWithMetadata();
      
      // إذا كان عدد النسخ الاحتياطية أقل من أو يساوي العدد المطلوب الاحتفاظ به
      if (backups.length <= keepCount) {
        return true;
      }
      
      // حذف النسخ الاحتياطية القديمة
      final backupsToDelete = backups.sublist(keepCount);
      
      for (final backup in backupsToDelete) {
        await deleteBackup(backup['path']);
      }
      
      return true;
    } catch (e) {
      debugPrint('خطأ أثناء تنظيف النسخ الاحتياطية القديمة: $e');
      return false;
    }
  }
  
  /// جدولة النسخ الاحتياطي التلقائي
  Future<bool> scheduleAutomaticBackup({int intervalDays = 7}) async {
    try {
      // الحصول على تاريخ آخر نسخة احتياطية
      final backups = await getBackupsWithMetadata();
      
      if (backups.isEmpty) {
        // إنشاء نسخة احتياطية جديدة إذا لم تكن هناك نسخ احتياطية سابقة
        await createBackup(customName: 'نسخة احتياطية تلقائية');
        return true;
      }
      
      final lastBackup = backups.first;
      final lastBackupTimestamp = lastBackup['metadata']['timestamp'] as int;
      final lastBackupDate = DateTime.fromMillisecondsSinceEpoch(lastBackupTimestamp);
      final now = DateTime.now();
      
      // حساب الفرق بين التاريخ الحالي وتاريخ آخر نسخة احتياطية
      final difference = now.difference(lastBackupDate).inDays;
      
      // إنشاء نسخة احتياطية جديدة إذا مر عدد الأيام المحدد
      if (difference >= intervalDays) {
        await createBackup(customName: 'نسخة احتياطية تلقائية');
        
        // تنظيف النسخ الاحتياطية القديمة
        await cleanupOldBackups();
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('خطأ أثناء جدولة النسخ الاحتياطي التلقائي: $e');
      return false;
    }
  }
  
  /// التحقق من حالة النسخ الاحتياطية
  Future<Map<String, dynamic>> checkBackupStatus() async {
    try {
      final backups = await getBackupsWithMetadata();
      
      if (backups.isEmpty) {
        return {
          'has_backups': false,
          'last_backup_date': null,
          'backup_count': 0,
          'total_size': 0,
          'message': 'لا توجد نسخ احتياطية'
        };
      }
      
      final lastBackup = backups.first;
      final lastBackupTimestamp = lastBackup['metadata']['timestamp'] as int;
      final lastBackupDate = DateTime.fromMillisecondsSinceEpoch(lastBackupTimestamp);
      
      // حساب الحجم الإجمالي للنسخ الاحتياطية
      int totalSize = 0;
      for (final backup in backups) {
        totalSize += (backup['metadata']['size'] as int? ?? 0);
      }
      
      return {
        'has_backups': true,
        'last_backup_date': lastBackupDate.toIso8601String(),
        'backup_count': backups.length,
        'total_size': totalSize,
        'message': 'آخر نسخة احتياطية: ${lastBackupDate.toString()}'
      };
    } catch (e) {
      debugPrint('خطأ أثناء التحقق من حالة النسخ الاحتياطية: $e');
      return {
        'has_backups': false,
        'last_backup_date': null,
        'backup_count': 0,
        'total_size': 0,
        'message': 'حدث خطأ أثناء التحقق من حالة النسخ الاحتياطية: $e'
      };
    }
  }