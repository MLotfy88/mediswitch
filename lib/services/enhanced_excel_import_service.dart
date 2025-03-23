import 'dart:io';
import 'package:excel/excel.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:mediswitch/services/logging_service.dart';
import 'package:mediswitch/services/backup_service.dart';
import 'package:path/path.dart';
import 'package:csv/csv.dart';

/// خدمة محسنة لاستيراد البيانات من ملفات Excel/CSV
class EnhancedExcelImportService {
  static final EnhancedExcelImportService instance = EnhancedExcelImportService._init();
  
  // الأعمدة المطلوبة في ملف البيانات
  static const List<String> requiredColumns = [
    'trade_name', 'arabic_name', 'price', 'active', 
    'main_category', 'main_category_ar', 'dosage_form', 'dosage_form_ar'
  ];
  
  // الأعمدة الاختيارية في ملف البيانات
  static const List<String> optionalColumns = [
    'old_price', 'category', 'category_ar', 'company', 
    'unit', 'usage', 'usage_ar', 'description', 'last_price_update'
  ];
  
  // عدد الصفوف للمعاينة
  static const int previewRowCount = 10;
  
  EnhancedExcelImportService._init();
  
  /// الحصول على معاينة البيانات من ملف Excel/CSV
  Future<Map<String, dynamic>> getDataPreview(String filePath) async {
    try {
      await LoggingService.instance.info('جاري تحميل معاينة البيانات من الملف: $filePath');
      
      final fileExtension = extension(filePath).toLowerCase();
      List<List<dynamic>> data;
      
      if (fileExtension == '.csv') {
        // استيراد من ملف CSV
        final file = File(filePath);
        final csvString = await file.readAsString();
        data = const CsvToListConverter().convert(csvString);
      } else if (fileExtension == '.xlsx' || fileExtension == '.xls') {
        // استيراد من ملف Excel
        final bytes = await File(filePath).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        
        // الحصول على ورقة العمل الأولى
        final sheet = excel.tables.keys.first;
        final table = excel.tables[sheet];
        
        if (table == null || table.rows.isEmpty) {
          return {
            'success': false,
            'message': 'ملف Excel فارغ أو لا يحتوي على بيانات',
            'preview_data': null
          };
        }
        
        // تحويل بيانات Excel إلى مصفوفة
        data = [];
        for (final row in table.rows) {
          final rowData = row.map((cell) => cell?.value).toList();
          data.add(rowData);
        }
      } else {
        return {
          'success': false,
          'message': 'تنسيق الملف غير مدعوم. الرجاء استخدام ملفات CSV أو Excel (.xlsx, .xls)',
          'preview_data': null
        };
      }
      
      if (data.isEmpty) {
        return {
          'success': false,
          'message': 'الملف فارغ أو لا يحتوي على بيانات',
          'preview_data': null
        };
      }
      
      // التحقق من وجود الأعمدة المطلوبة
      final headers = data[0].map((header) => header?.toString().toLowerCase() ?? '').toList();
      final columnMapping = _mapColumns(headers);
      
      // التحقق من وجود جميع الأعمدة المطلوبة
      final missingColumns = requiredColumns.where((col) => !columnMapping.containsKey(col)).toList();
      
      if (missingColumns.isNotEmpty) {
        return {
          'success': false,
          'message': 'الأعمدة التالية مفقودة: ${missingColumns.join(', ')}',
          'preview_data': data.take(previewRowCount).toList(),
          'missing_columns': missingColumns,
          'headers': headers
        };
      }
      
      // إعادة معاينة البيانات (عدد محدود من الصفوف)
      final previewData = data.take(previewRowCount).toList();
      
      return {
        'success': true,
        'message': 'تم تحميل معاينة البيانات بنجاح',
        'preview_data': previewData,
        'column_mapping': columnMapping,
        'total_rows': data.length - 1, // طرح صف العناوين
        'headers': headers
      };
    } catch (e) {
      await LoggingService.instance.error('خطأ في تحميل معاينة البيانات', e);
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحميل معاينة البيانات: $e',
        'preview_data': null
      };
    }
  }
  
  /// استيراد البيانات من ملف Excel/CSV
  Future<Map<String, dynamic>> importFromExcel(String filePath, {bool clearExistingData = true}) async {
    try {
      await LoggingService.instance.info('بدء استيراد البيانات من الملف: $filePath');
      
      // الحصول على معاينة البيانات أولاً للتحقق من صحة الملف
      final previewResult = await getDataPreview(filePath);
      
      if (!previewResult['success']) {
        return previewResult;
      }
      
      final columnMapping = previewResult['column_mapping'] as Map<String, int>;
      final fileExtension = extension(filePath).toLowerCase();
      List<List<dynamic>> data;
      
      if (fileExtension == '.csv') {
        // استيراد من ملف CSV
        final file = File(filePath);
        final csvString = await file.readAsString();
        data = const CsvToListConverter().convert(csvString);
      } else if (fileExtension == '.xlsx' || fileExtension == '.xls') {
        // استيراد من ملف Excel
        final bytes = await File(filePath).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        
        // الحصول على ورقة العمل الأولى
        final sheet = excel.tables.keys.first;
        final table = excel.tables[sheet];
        
        if (table == null || table.rows.isEmpty) {
          return {
            'success': false,
            'message': 'ملف Excel فارغ أو لا يحتوي على بيانات',
            'imported_count': 0
          };
        }
        
        // تحويل بيانات Excel إلى مصفوفة
        data = [];
        for (final row in table.rows) {
          final rowData = row.map((cell) => cell?.value).toList();
          data.add(rowData);
        }
      } else {
        return {
          'success': false,
          'message': 'تنسيق الملف غير مدعوم. الرجاء استخدام ملفات CSV أو Excel (.xlsx, .xls)',
          'imported_count': 0
        };
      }
      
      // إنشاء نسخة احتياطية قبل التحديث
      await BackupService.instance.createBackup(customName: 'pre_import_backup');
      
      // الحصول على قاعدة البيانات
      final db = await DatabaseService.instance.database;
      
      // مسح البيانات الموجودة إذا كان مطلوبًا
      if (clearExistingData) {
        await db.delete('medications');
      }
      
      // تحويل البيانات إلى قائمة من الأدوية
      final medications = <Map<String, dynamic>>[];
      int importedCount = 0;
      int errorCount = 0;
      final List<String> errorMessages = [];
      
      // بدءًا من الصف الثاني (بعد العناوين)
      for (int i = 1; i < data.length; i++) {
        final row = data[i];
        
        // تخطي الصفوف الفارغة
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().isEmpty)) {
          continue;
        }
        
        try {
          // إنشاء كائن الدواء باستخدام خريطة الأعمدة
          final medication = _createMedicationFromRow(row, columnMapping);
          medications.add(medication);
          importedCount++;
        } catch (e) {
          errorCount++;
          errorMessages.add('خطأ في الصف ${i + 1}: $e');
          await LoggingService.instance.error('خطأ في استيراد الصف ${i + 1}', e);
          
          // تحديد عدد الأخطاء المسموح بها
          if (errorCount > 10) {
            errorMessages.add('تم تجاوز الحد الأقصى للأخطاء المسموح بها. تم إيقاف الاستيراد.');
            break;
          }
        }
      }
      
      // إدخال البيانات في قاعدة البيانات
      await db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final medication in medications) {
          batch.insert('medications', medication);
        }
        
        await batch.commit(noResult: true);
      });
      
      await LoggingService.instance.info('تم استيراد البيانات بنجاح: $importedCount سجل');
      
      return {
        'success': true,
        'message': 'تم استيراد البيانات بنجاح',
        'imported_count': importedCount,
        'error_count': errorCount,
        'error_messages': errorMessages,
        'total_rows': data.length - 1 // طرح صف العناوين
      };
    } catch (e) {
      await LoggingService.instance.error('خطأ في استيراد البيانات', e);
      return {
        'success': false,
        'message': 'حدث خطأ أثناء استيراد البيانات: $e',
        'imported_count': 0
      };
    }
  }
  
  /// إنشاء خريطة للأعمدة بناءً على العناوين
  Map<String, int> _mapColumns(List<dynamic> headers) {
    final Map<String, int> columnMapping = {};
    
    // قائمة بالأسماء البديلة المحتملة للأعمدة
    final Map<String, List<String>> columnAliases = {
      'trade_name': ['trade_name', 'trade name', 'tradename', 'name', 'english_name', 'english name'],
      'arabic_name': ['arabic_name', 'arabic name', 'arabicname', 'name_ar', 'name ar', 'arabic'],
      'old_price': ['old_price', 'old price', 'oldprice', 'previous_price', 'previous price'],
      'price': ['price', 'current_price', 'current price', 'new_price', 'new price'],
      'active': ['active', 'active_ingredient', 'active ingredient', 'ingredient', 'substance'],
      'main_category': ['main_category', 'main category', 'maincategory', 'primary_category', 'primary category'],
      'main_category_ar': ['main_category_ar', 'main category ar', 'maincategory_ar', 'primary_category_ar'],
      'category': ['category', 'subcategory', 'sub_category', 'sub category'],
      'category_ar': ['category_ar', 'category ar', 'subcategory_ar', 'sub_category_ar'],
      'company': ['company', 'manufacturer', 'producer', 'brand'],
      'dosage_form': ['dosage_form', 'dosage form', 'form', 'drug_form', 'drug form'],
      'dosage_form_ar': ['dosage_form_ar', 'dosage form ar', 'form_ar', 'drug_form_ar'],
      'unit': ['unit', 'dosage_unit', 'dosage unit', 'measurement_unit', 'measurement unit'],
      'usage': ['usage', 'indication', 'use', 'uses', 'purpose'],
      'usage_ar': ['usage_ar', 'usage ar', 'indication_ar', 'use_ar', 'uses_ar', 'purpose_ar'],
      'description': ['description', 'desc', 'details', 'info', 'information'],
      'last_price_update': ['last_price_update', 'price_update', 'price update', 'update_date', 'update date']
    };
    
    // البحث عن الأعمدة باستخدام الأسماء البديلة
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toString().toLowerCase().trim();
      
      columnAliases.forEach((columnName, aliases) {
        if (aliases.contains(header)) {
          columnMapping[columnName] = i;