import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mediswitch/services/backup_service.dart';
import 'package:mediswitch/services/logging_service.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

/// شاشة إدارة النسخ الاحتياطي واستعادة البيانات
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  // قائمة النسخ الاحتياطية المتاحة
  List<String> _backupFiles = [];
  
  // حالة العملية الحالية
  bool _isLoading = false;
  bool _isCreatingBackup = false;
  bool _isRestoringBackup = false;
  String _statusMessage = '';
  
  // معلومات النسخة الاحتياطية المحددة
  String? _selectedBackupPath;
  Map<String, dynamic>? _selectedBackupMetadata;
  
  @override
  void initState() {
    super.initState();
    _loadBackups();
  }
  
  /// تحميل قائمة النسخ الاحتياطية المتاحة
  Future<void> _loadBackups() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'جاري تحميل النسخ الاحتياطية...';
      });
      
      final backups = await BackupService.instance.getBackups();
      
      setState(() {
        _backupFiles = backups;
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'خطأ في تحميل النسخ الاحتياطية: $e';
      });
      await LoggingService.instance.error('خطأ في تحميل النسخ الاحتياطية', e);
    }
  }
  
  /// إنشاء نسخة احتياطية جديدة
  Future<void> _createBackup() async {
    try {
      setState(() {
        _isCreatingBackup = true;
        _statusMessage = 'جاري إنشاء نسخة احتياطية جديدة...';
      });
      
      final result = await BackupService.instance.createBackup(
        customName: 'manual_backup_${DateTime.now().millisecondsSinceEpoch}',
        compress: true,
      );
      
      setState(() {
        _isCreatingBackup = false;
        
        if (result['success']) {
          _statusMessage = 'تم إنشاء النسخة الاحتياطية بنجاح';
          // إعادة تحميل قائمة النسخ الاحتياطية
          _loadBackups();
        } else {
          _statusMessage = result['message'] ?? 'حدث خطأ أثناء إنشاء النسخة الاحتياطية';
        }
      });
    } catch (e) {
      setState(() {
        _isCreatingBackup = false;
        _statusMessage = 'خطأ في إنشاء النسخة الاحتياطية: $e';
      });
      await LoggingService.instance.error('خطأ في إنشاء النسخة الاحتياطية', e);
    }
  }
  
  /// استعادة البيانات من نسخة احتياطية
  Future<void> _restoreBackup(String backupPath) async {
    try {
      // عرض تأكيد قبل الاستعادة
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد استعادة البيانات'),
          content: const Text(
            'سيتم استبدال جميع البيانات الحالية بالبيانات من النسخة الاحتياطية المحددة. هل أنت متأكد من الاستمرار؟',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('استعادة'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      setState(() {
        _isRestoringBackup = true;
        _statusMessage = 'جاري استعادة البيانات من النسخة الاحتياطية...';
      });
      
      final result = await BackupService.instance.restoreBackup(backupPath);
      
      setState(() {
        _isRestoringBackup = false;
        
        if (result['success']) {
          _statusMessage = 'تم استعادة البيانات بنجاح';
        } else {
          _statusMessage = result['message'] ?? 'حدث خطأ أثناء استعادة البيانات';
        }
      });
    } catch (e) {
      setState(() {
        _isRestoringBackup = false;
        _statusMessage = 'خطأ في استعادة البيانات: $e';
      });
      await LoggingService.instance.error('خطأ في استعادة البيانات', e);
    }
  }
  
  /// مشاركة النسخة الاحتياطية
  Future<void> _shareBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(backupPath)],
          text: 'نسخة احتياطية من تطبيق MediSwitch',
        );
      } else {
        setState(() {
          _statusMessage = 'ملف النسخة الاحتياطية غير موجود';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في مشاركة النسخة الاحتياطية: $e';
      });
      await LoggingService.instance.error('خطأ في مشاركة النسخة الاحتياطية', e);
    }
  }
  
  /// حذف نسخة احتياطية
  Future<void> _deleteBackup(String backupPath) async {
    try {
      // عرض تأكيد قبل الحذف
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text(
            'هل أنت متأكد من حذف هذه النسخة الاحتياطية؟ لا يمكن التراجع عن هذه العملية.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        
        // حذف ملف البيانات التعريفية إذا كان موجودًا
        final metadataFile = File('$backupPath.meta');
        if (await metadataFile.exists()) {
          await metadataFile.delete();
        }
        
        setState(() {
          _statusMessage = 'تم حذف النسخة الاحتياطية بنجاح';
          if (_selectedBackupPath == backupPath) {
            _selectedBackupPath = null;
            _selectedBackupMetadata = null;
          }
        });
        
        // إعادة تحميل قائمة النسخ الاحتياطية
        await _loadBackups();
      } else {
        setState(() {
          _statusMessage = 'ملف النسخة الاحتياطية غير موجود';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في حذف النسخة الاحتياطية: $e';
      });
      await LoggingService.instance.error('خطأ في حذف النسخة الاحتياطية', e);
    }
  }
  
  /// تحميل معلومات النسخة الاحتياطية
  Future<void> _loadBackupMetadata(String backupPath) async {
    try {
      final metadataFile = File('$backupPath.meta');
      if (await metadataFile.exists()) {
        final metadataString = await metadataFile.readAsString();
        final metadata = Map<String, dynamic>.from(jsonDecode(metadataString));
        
        setState(() {
          _selectedBackupPath = backupPath;
          _selectedBackupMetadata = metadata;
        });
      } else {
        setState(() {
          _selectedBackupPath = backupPath;
          _selectedBackupMetadata = {
            'timestamp': File(backupPath).lastModifiedSync().millisecondsSinceEpoch,
            'name': path.basename(backupPath),
            'version': 'غير معروف',
            'app_version': 'غير معروف',
            'encrypted': false,
          };
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في تحميل معلومات النسخة الاحتياطية: $e';
      });
      await LoggingService.instance.error('خطأ في تحميل معلومات النسخة الاحتياطية', e);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'النسخ الاحتياطي واستعادة البيانات' : 'Backup & Restore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBackups,
            tooltip: isArabic ? 'تحديث القائمة' : 'Refresh List',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // زر إنشاء نسخة احتياطية جديدة
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: Text(isArabic ? 'إنشاء نسخة احتياطية جديدة' : 'Create New Backup'),
              onPressed: _isCreatingBackup || _isRestoringBackup ? null : _createBackup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // رسالة الحالة
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('خطأ') || _statusMessage.contains('فشل')
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains('خطأ') || _statusMessage.contains('فشل')
                          ? Icons.error
                          : Icons.check_circle,
                      color: _statusMessage.contains('خطأ') || _statusMessage.contains('فشل')
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // عنوان قائمة النسخ الاحتياطية
            Text(
              isArabic ? 'النسخ الاحتياطية المتاحة' : 'Available Backups',
              style: theme.textTheme.titleLarge,
            ),
            
            const SizedBox(height: 8),
            
            // قائمة النسخ الاحتياطية
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _backupFiles.isEmpty
                      ? Center(
                          child: Text('لا توجد نسخ احتياطية متاحة', style: theme.textTheme.bodyLarge),