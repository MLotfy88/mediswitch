import 'package:mediswitch/services/database_service.dart';

// هذا الملف يحتوي على دوال مساعدة لقاعدة البيانات
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init();
  
  // الحصول على أشكال الدواء المتاحة
  Future<List<String>> getDosageForms() async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT dosage_form_ar
        FROM medications
        WHERE dosage_form_ar IS NOT NULL AND dosage_form_ar != ''
        ORDER BY dosage_form_ar ASC
      ''');
      
      return result.map((row) => row['dosage_form_ar'] as String).toList();
    } catch (e) {
      // في حالة حدوث خطأ، نعيد قائمة افتراضية
      return ['أقراص', 'شراب', 'حقن', 'كريم', 'مرهم', 'قطرة'];
    }
  }
}