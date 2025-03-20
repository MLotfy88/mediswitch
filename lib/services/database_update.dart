import 'package:flutter/foundation.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseUpdate {
  static final DatabaseUpdate instance = DatabaseUpdate._init();
  
  DatabaseUpdate._init();
  
  /// تحديث قاعدة البيانات لإضافة الجداول الجديدة المطلوبة لميزات مقارنة الجرعات وحاسبة الجرعة
  Future<void> updateDatabase() async {
    try {
      final db = await DatabaseService.instance.database;
      
      // التحقق من وجود جدول dose_equivalents
      final doseEquivalentsTableExists = await _checkIfTableExists(db, 'dose_equivalents');
      if (!doseEquivalentsTableExists) {
        await _createDoseEquivalentsTable(db);
      }
      
      // التحقق من وجود جدول weight_dose_calculators
      final weightDoseCalculatorsTableExists = await _checkIfTableExists(db, 'weight_dose_calculators');
      if (!weightDoseCalculatorsTableExists) {
        await _createWeightDoseCalculatorsTable(db);
      }
      
      debugPrint('تم تحديث قاعدة البيانات بنجاح');
    } catch (e) {
      debugPrint('خطأ في تحديث قاعدة البيانات: $e');
    }
  }
  
  /// التحقق من وجود جدول في قاعدة البيانات
  Future<bool> _checkIfTableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    return result.isNotEmpty;
  }
  
  /// إنشاء جدول مكافئات الجرعات
  Future<void> _createDoseEquivalentsTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER';
    const realType = 'REAL';
    const textType = 'TEXT';
    
    await db.execute('''
    CREATE TABLE dose_equivalents (
      id $idType,
      medication_id $intType NOT NULL,
      equivalent_medication_id $intType NOT NULL,
      conversion_factor $realType NOT NULL,
      unit $textType NOT NULL,
      notes $textType,
      efficacy_percentage $realType DEFAULT 100.0,
      toxicity_percentage $realType DEFAULT 0.0,
      FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE,
      FOREIGN KEY (equivalent_medication_id) REFERENCES medications (id) ON DELETE CASCADE
    )
    ''');
    
    // إنشاء فهارس للبحث السريع
    await db.execute('CREATE INDEX idx_medication_id ON dose_equivalents(medication_id)');
    await db.execute('CREATE INDEX idx_equivalent_medication_id ON dose_equivalents(equivalent_medication_id)');
  }
  
  /// إنشاء جدول حاسبات الجرعة حسب الوزن
  Future<void> _createWeightDoseCalculatorsTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER';
    const realType = 'REAL';
    const textType = 'TEXT';
    
    await db.execute('''
    CREATE TABLE weight_dose_calculators (
      id $idType,
      medication_id $intType NOT NULL,
      min_dose_per_kg $realType NOT NULL,
      max_dose_per_kg $realType NOT NULL,
      unit $textType NOT NULL,
      min_age_months $intType DEFAULT 0,
      max_age_months $intType DEFAULT 1200,
      min_weight_kg $realType DEFAULT 0,
      max_weight_kg $realType DEFAULT 500,
      max_daily_doses $intType DEFAULT 4,
      notes $textType,
      warning_threshold $textType DEFAULT 'none',
      FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
    )
    ''');
    
    // إنشاء فهرس للبحث السريع
    await db.execute('CREATE INDEX idx_medication_id_weight ON weight_dose_calculators(medication_id)');
  }
  
  /// إضافة مكافئ جرعة جديد
  Future<int> insertDoseEquivalent(Map<String, dynamic> doseEquivalent) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('dose_equivalents', doseEquivalent);
  }
  
  /// الحصول على مكافئات الجرعات لدواء معين
  Future<List<Map<String, dynamic>>> getDoseEquivalents(int medicationId) async {
    final db = await DatabaseService.instance.database;
    return await db.query(
      'dose_equivalents',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
  }
  
  /// إضافة حاسبة جرعة حسب الوزن جديدة
  Future<int> insertWeightDoseCalculator(Map<String, dynamic> weightDoseCalculator) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('weight_dose_calculators', weightDoseCalculator);
  }
  
  /// الحصول على حاسبة الجرعة حسب الوزن لدواء معين
  Future<Map<String, dynamic>?> getWeightDoseCalculator(int medicationId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'weight_dose_calculators',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}