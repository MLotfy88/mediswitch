import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

/// خدمة استيراد البيانات من ملفات Excel/CSV
class ExcelImportService {
  static final ExcelImportService instance = ExcelImportService._init();
  
  ExcelImportService._init();
  
  /// الحصول على معاينة البيانات من ملف Excel/CSV
  Future<Map<String, dynamic>> getDataPreview(String filePath) async {
    try {
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
          final rowData = row.map((cell) {
            if (cell?.value is CellValue) {
              final cellValue = cell!.value as CellValue;
              if (cellValue.cellType == CellType.number) {
                if (cellValue.value is num) {
                  return (cellValue.value as num).toDouble();
                } else {
                  return double.tryParse(cellValue.value.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? cellValue.value.toString();
                }
              } else {
                return cellValue.value.toString();
              }
            } else {
              return cell?.value;
            }
          }).toList();
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
      final requiredColumns = [
        'trade_name', 'arabic_name', 'price', 'active', 
        'main_category', 'main_category_ar', 'dosage_form', 'dosage_form_ar'
      ];
      
      final headers = data[0].map((header) => header?.toString().toLowerCase() ?? '').toList();
      
      // التحقق من وجود جميع الأعمدة المطلوبة
      final missingColumns = requiredColumns.where((col) => !headers.contains(col)).toList();
      
      if (missingColumns.isNotEmpty) {
        return {
          'success': false,
          'message': 'الأعمدة التالية مفقودة: ${missingColumns.join(', ')}',
          'preview_data': data.take(10).toList(),
          'missing_columns': missingColumns,
          'headers': headers
        };
      }
      
      // إعادة معاينة البيانات (عدد محدود من الصفوف)
      final previewData = data.take(10).toList();
      
      return {
        'success': true,
        'message': 'تم تحميل معاينة البيانات بنجاح',
        'preview_data': previewData,
        'total_rows': data.length - 1, // طرح صف العناوين
        'headers': headers
      };
    } catch (e) {
      debugPrint('خطأ في تحميل معاينة البيانات: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تحميل معاينة البيانات: $e',
        'preview_data': null
      };
    }
  }
  
  /// استيراد البيانات من ملف Excel
  Future<Map<String, dynamic>> importFromExcel(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      // التحقق من وجود الأعمدة المطلوبة
      final requiredColumns = [
        'trade_name', 'arabic_name', 'price', 'active', 
        'main_category', 'main_category_ar', 'dosage_form', 'dosage_form_ar'
      ];
      
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
      
      // التحقق من وجود الأعمدة المطلوبة في الصف الأول (العناوين)
      final headers = table.rows[0].map((cell) => cell?.value.toString().toLowerCase() ?? '').toList();
      
      // التحقق من وجود جميع الأعمدة المطلوبة
      final missingColumns = requiredColumns.where((col) => !headers.contains(col)).toList();
      
      if (missingColumns.isNotEmpty) {
        return {
          'success': false,
          'message': 'الأعمدة التالية مفقودة: ${missingColumns.join(', ')}',
          'imported_count': 0,
          'missing_columns': missingColumns
        };
      }
      
      // إنشاء نسخة احتياطية قبل التحديث
      await DatabaseService.instance.createBackup(customName: 'pre_import_backup');
      
      // تحويل البيانات إلى قائمة من الأدوية
      final medications = <Map<String, dynamic>>[];
      
      // بدءًا من الصف الثاني (بعد العناوين)
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        
        // تخطي الصفوف الفارغة
        if (row.isEmpty || row.every((cell) => cell == null || (cell.value == null) || cell.value.toString().isEmpty)) {
          continue;
        }
        
        // إنشاء كائن الدواء
        final medication = <String, dynamic>{};
        
        // ملء البيانات من الصف
        for (int j = 0; j < headers.length; j++) {
          if (j < row.length) {
            final header = headers[j];
            final value = row[j]?.value;
            
            // معالجة القيم الخاصة (مثل الأسعار)
            if (header == 'price' || header == 'old_price') {
              // تحويل السعر إلى رقم
              double? price;
              if (value != null) {
                if (value is num) {
                  price = value.toDouble();
                } else                // Convert CellValue to double
                if (value.cellType == CellType.number) {
                  try {
                    // تحويل القيمة العددية بشكل آمن
                    if (value.value is num) {
                      price = (value.value as num).toDouble();
                    } else {
                      // محاولة تحويل النص إلى رقم
                      price = double.tryParse(value.value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
                    }
                  } catch (e) {
                    // في حالة فشل التحويل، نحاول تحويل النص
                    price = double.tryParse(value.value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
                  }
                } else {
                  // محاولة تحويل النص إلى رقم
                  price = double.tryParse(value.value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
                }
              
              }
              medication[header] = price ?? 0.0;
            } else {
              // القيم النصية العادية
              medication[header] = value?.toString() ?? '';
            }
          }
        }
        
        // إضافة حقول إضافية إذا كانت مفقودة
        medication['is_favorite'] = 0;
        medication['last_price_update'] = DateTime.now().toIso8601String();
        
        medications.add(medication);
      }
      
      // حفظ البيانات في قاعدة البيانات
      final db = await DatabaseService.instance.database;
      
      // بدء المعاملة لتحسين الأداء
      await db.transaction((txn) async {
        // مسح البيانات القديمة
        await txn.delete('medications');
        
        // إدراج البيانات الجديدة
        final batch = txn.batch();
        
        for (final medication in medications) {
          batch.insert('medications', medication);
        }
        
        await batch.commit(noResult: true);
      });
      
      // تسجيل نجاح العملية
      debugPrint('تم استيراد ${medications.length} دواء بنجاح');
      
      return {
        'success': true,
        'message': 'تم استيراد ${medications.length} دواء بنجاح',
        'imported_count': medications.length
      };
    } catch (e) {
      debugPrint('خطأ أثناء استيراد البيانات: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء استيراد البيانات: $e',
        'imported_count': 0
      };
    }
  }
  
  /// استيراد البيانات من ملف CSV
  Future<Map<String, dynamic>> importFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (csvTable.isEmpty) {
        return {
          'success': false,
          'message': 'ملف CSV فارغ أو لا يحتوي على بيانات',
          'imported_count': 0
        };
      }
      
      // التحقق من وجود الأعمدة المطلوبة
      final requiredColumns = [
        'trade_name', 'arabic_name', 'price', 'active', 
        'main_category', 'main_category_ar', 'dosage_form', 'dosage_form_ar'
      ];
      
      // الحصول على العناوين من الصف الأول
      final headers = csvTable[0].map((header) => header.toString().toLowerCase()).toList();
      
      // التحقق من وجود جميع الأعمدة المطلوبة
      final missingColumns = requiredColumns.where((col) => !headers.contains(col)).toList();
      
      if (missingColumns.isNotEmpty) {
        return {
          'success': false,
          'message': 'الأعمدة التالية مفقودة: ${missingColumns.join(', ')}',
          'imported_count': 0,
          'missing_columns': missingColumns
        };
      }
      
      // إنشاء نسخة احتياطية قبل التحديث
      await DatabaseService.instance.createBackup(customName: 'pre_import_backup');
      
      // تحويل البيانات إلى قائمة من الأدوية
      final medications = <Map<String, dynamic>>[];
      
      // بدءًا من الصف الثاني (بعد العناوين)
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        
        // تخطي الصفوف الفارغة
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().isEmpty)) {
          continue;
        }
        
        // إنشاء كائن الدواء
        final medication = <String, dynamic>{};
        
        // ملء البيانات من الصف
        for (int j = 0; j < headers.length; j++) {
          if (j < row.length) {
            final header = headers[j];
            final value = row[j];
            
            // معالجة القيم الخاصة (مثل الأسعار)
            if (header == 'price' || header == 'old_price') {
              // تحويل السعر إلى رقم
              double? price;
              if (value != null) {
                if (value is num) {
                  price = value.toDouble();
                } else {
                  // محاولة تحويل النص إلى رقم
                  price = double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
                }
              }
              medication[header] = price ?? 0.0;
            } else {
              // القيم النصية العادية
              medication[header] = value?.toString() ?? '';
            }
          }
        }
        
        // إضافة حقول إضافية إذا كانت مفقودة
        medication['is_favorite'] = 0;
        medication['last_price_update'] = DateTime.now().toIso8601String();
        
        medications.add(medication);
      }
      
      // حفظ البيانات في قاعدة البيانات
      final db = await DatabaseService.instance.database;
      
      // بدء المعاملة لتحسين الأداء
      await db.transaction((txn) async {
        // مسح البيانات القديمة
        await txn.delete('medications');
        
        // إدراج البيانات الجديدة
        final batch = txn.batch();
        
        for (final medication in medications) {
          batch.insert('medications', medication);
        }
        
        await batch.commit(noResult: true);
      });
      
      // تسجيل نجاح العملية
      debugPrint('تم استيراد ${medications.length} دواء بنجاح');
      
      return {
        'success': true,
        'message': 'تم استيراد ${medications.length} دواء بنجاح',
        'imported_count': medications.length
      };
    } catch (e) {
      debugPrint('خطأ أثناء استيراد البيانات: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء استيراد البيانات: $e',
        'imported_count': 0
      };
    }
  }
  
  /// التحقق من صحة ملف Excel/CSV
  Future<Map<String, dynamic>> validateFile(String filePath) async {
    try {
      final fileExtension = extension(filePath).toLowerCase();
      
      if (fileExtension == '.xlsx' || fileExtension == '.xls') {
        return await _validateExcelFile(filePath);
      } else if (fileExtension == '.csv') {
        return await _validateCsvFile(filePath);
      } else {
        return {
          'valid': false,
          'message': 'نوع الملف غير مدعوم. الأنواع المدعومة هي: .xlsx, .xls, .csv',
        };
      }
    } catch (e) {
      return {
        'valid': false,
        'message': 'حدث خطأ أثناء التحقق من الملف: $e',
      };
    }
  }
  
  /// التحقق من صحة ملف Excel
  Future<Map<String, dynamic>> _validateExcelFile(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      // التحقق من وجود الأعمدة المطلوبة
      final requiredColumns = [
        'trade_name', 'arabic_name', 'price', 'active', 
        'main_category', 'main_category_ar', 'dosage_form', 'dosage_form_ar'
      ];
      
      // الحصول على ورقة العمل الأولى
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet];
      
      if (table == null || table.rows.isEmpty) {
        return {
          'valid': false,
          'message': 'ملف Excel فارغ أو لا يحتوي على بيانات',
        };
      }
      
      // التحقق من وجود الأعمدة المطلوبة في الصف الأول (العناوين)
      final headers = table.rows[0].map((cell) => cell?.value.toString().toLowerCase() ?? '').toList();
      
      // التحقق من وجود جميع الأعمدة المطلوبة
      final missingColumns = requiredColumns.where((col) => !headers.contains(col)).toList();
      
      if (missingColumns.isNotEmpty) {
        return {
          'valid': false,
          'message': 'الأعمدة التالية مفقودة: ${missingColumns.join(', ')}',
          'missing_columns': missingColumns
        };
      }
      
      // التحقق من عدد الصفوف
      final rowCount = table.rows.length - 1; // استبعاد صف العناوين
      
      // التحقق من صحة البيانات في بعض الأعمدة المهمة
      int validRows = 0;
      int invalidRows = 0;
      List<int> invalidRowIndices = [];
      
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        
        // تخطي الصفوف الفارغة
        if (row.isEmpty || row.every((cell) => cell == null || (cell.value == null) || cell.value.toString().isEmpty)) {
          continue;
        }
        
        bool isRowValid = true;
        
        // التحقق من وجود اسم الدواء
        final tradeNameIndex = headers.indexOf('trade_name');
        if (tradeNameIndex >= 0 && (tradeNameIndex >= row.length || row[tradeNameIndex]?.value == null || row[tradeNameIndex]!.value.toString().isEmpty)) {
          isRowValid = false;
        }
        
        // التحقق من صحة السعر
        final priceIndex = headers.indexOf('price');
        if (priceIndex >= 0 && priceIndex < row.length && row[priceIndex]?.value != null) {
          final priceValue = row[priceIndex]!.value;
          if (priceValue is num) {
            // القيمة عددية، صالحة
          } else if (priceValue is CellValue) {
            // التعامل مع CellValue
            if (priceValue.cellType == CellType.number) {
              if (priceValue.value is! num && double.tryParse(priceValue.value.toString().replaceAll(RegExp(r'[^\d.]'), '')) == null) {
                isRowValid = false;
              }
            } else if (double.tryParse(priceValue.value.toString().replaceAll(RegExp(r'[^\d.]'), '')) == null) {
              isRowValid = false;
            }
          } else if (double.tryParse(priceValue.toString().replaceAll(RegExp(r'[^\d.]'), '')) == null) {
            isRowValid = false;
          }
        }
        
        if (isRowValid) {
          validRows++;
        } else {
          invalidRows++;
          if (invalidRowIndices.length < 10) { // نحتفظ بأول 10 صفوف غير صالحة فقط
            invalidRowIndices.add(i);
          }
        }
      }
      
      return {
        'valid': invalidRows == 0,
        'message': invalidRows == 0 
            ? 'الملف صالح ويحتوي على $validRows صف من البيانات' 
            : 'الملف يحتوي على $invalidRows صف غير صالح من أصل ${validRows + invalidRows}',
        'total_rows': validRows + invalidRows,
        'valid_rows': validRows,
        'invalid_rows': invalidRows,
        'invalid_row_indices': invalidRowIndices,
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'حدث خطأ أثناء التحقق من ملف Excel: $e',
      };
    }
  }
  
  /// التحقق من صحة ملف CSV
  Future<Map<String, dynamic>> _validateCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      if (csvTable.isEmpty) {
        return {
          'valid': false,
          'message': 'ملف CSV فارغ أو لا يحتوي على بيانات',
        };
      }
      
      // التحقق من وجود الأعمدة المطلوبة
      final requiredColumns = [
        'trade_name', 'arabic_name', 'price', 'active', 
        'main_category', 'main_category_ar', 'dosage_form', 'dosage_form_ar'
      ];
      
      // الحصول على العناوين من الصف الأول
      final headers = csvTable[0].map((header) => header.toString().toLowerCase()).toList();
      
      // التحقق من وجود جميع الأعمدة المطلوبة
      final missingColumns = requiredColumns.where((col) => !headers.contains(col)).toList();
      
      if (missingColumns.isNotEmpty) {
        return {
          'valid': false,
          'message': 'الأعمدة التالية مفقودة: ${missingColumns.join(', ')}',
          'missing_columns': missingColumns
        };
      }
      
      // التحقق من عدد الصفوف
      final rowCount = csvTable.length - 1; // استبعاد صف العناوين
      
      // التحقق من صحة البيانات في بعض الأعمدة المهمة
      int validRows = 0;
      int invalidRows = 0;
      List<int> invalidRowIndices = [];
      
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        
        // تخطي الصفوف الفارغة
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().isEmpty)) {
          continue;
        }
        
        bool isRowValid = true;
        
        // التحقق من وجود اسم الدواء
        final tradeNameIndex = headers.indexOf('trade_name');
        if (tradeNameIndex >= 0 && (tradeNameIndex >= row.length || row[tradeNameIndex] == null || row[tradeNameIndex].toString().isEmpty)) {
          isRowValid = false;
        }
        
        // التحقق من صحة السعر
        final priceIndex = headers.indexOf('price');
        if (priceIndex >= 0 && priceIndex < row.length && row[priceIndex] != null) {
          final priceValue = row[priceIndex];
          if (priceValue is! num && double.tryParse(priceValue.toString().replaceAll(RegExp(r'[^\d.]'), '')) == null) {
            isRowValid = false;
          }
        }
        
        if (isRowValid) {
          validRows++;
        } else {
          invalidRows++;
          if (invalidRowIndices.length < 10) { // نحتفظ بأول 10 صفوف غير صالحة فقط
            invalidRowIndices.add(i);
          }
        }
      }
      
      return {
        'valid': invalidRows == 0,
        'message': invalidRows == 0 
            ? 'الملف صالح ويحتوي على $validRows صف من البيانات' 
            : 'الملف يحتوي على $invalidRows صف غير صالح من أصل ${validRows + invalidRows}',
        'total_rows': validRows + invalidRows,
        'valid_rows': validRows,
        'invalid_rows': invalidRows,
        'invalid_row_indices': invalidRowIndices,
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'حدث خطأ أثناء التحقق من ملف CSV: $e',
      };
    }