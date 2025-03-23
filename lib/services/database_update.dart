import 'package:flutter/foundation.dart';
import 'package:mediswitch/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseUpdate {
  static final DatabaseUpdate instance = DatabaseUpdate._init();
  
  DatabaseUpdate._init();
  
  /// تحديث قاعدة البيانات لإضافة الجداول الجديدة المطلوبة لميزات مقارنة الجرعات وحاسبة الجرعة والتفاعلات الدوائية
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
      
      // التحقق من وجود جدول drug_interactions
      final drugInteractionsTableExists = await _checkIfTableExists(db, 'drug_interactions');
      if (!drugInteractionsTableExists) {
        await _createDrugInteractionsTable(db);
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
  
  /// إنشاء جدول التفاعلات الدوائية
  Future<void> _createDrugInteractionsTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER';
    const textType = 'TEXT';
    
    await db.execute('''
    CREATE TABLE drug_interactions (
      id $idType,
      medication_id $intType NOT NULL,
      interacting_medication_id $intType NOT NULL,
      severity_level $textType NOT NULL,
      effect $textType NOT NULL,
      effect_ar $textType NOT NULL,
      mechanism $textType NOT NULL,
      mechanism_ar $textType NOT NULL,
      management $textType NOT NULL,
      management_ar $textType NOT NULL,
      reference $textType,
      FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE,
      FOREIGN KEY (interacting_medication_id) REFERENCES medications (id) ON DELETE CASCADE
    )
    ''');
    
    // إنشاء فهارس للبحث السريع
    await db.execute('CREATE INDEX idx_medication_id_interaction ON drug_interactions(medication_id)');
    await db.execute('CREATE INDEX idx_interacting_medication_id ON drug_interactions(interacting_medication_id)');
    await db.execute('CREATE INDEX idx_severity_level ON drug_interactions(severity_level)');
  }
  
  /// إضافة تفاعل دوائي جديد
  Future<int> insertDrugInteraction(Map<String, dynamic> drugInteraction) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('drug_interactions', drugInteraction);
  }
  
  /// الحصول على التفاعلات الدوائية لدواء معين
  Future<List<Map<String, dynamic>>> getDrugInteractions(int medicationId) async {
    final db = await DatabaseService.instance.database;
    return await db.query(
      'drug_interactions',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
  }
  
  /// البحث عن التفاعلات الدوائية بين دواءين
  Future<List<Map<String, dynamic>>> findInteractionsBetweenMedications(
    int medicationId1, 
    int medicationId2
  ) async {
    final db = await DatabaseService.instance.database;
    return await db.rawQuery('''
      SELECT * FROM drug_interactions 
      WHERE (medication_id = ? AND interacting_medication_id = ?) 
      OR (medication_id = ? AND interacting_medication_id = ?)
    ''', [medicationId1, medicationId2, medicationId2, medicationId1]);
  }
  
  /// تحديث تفاعل دوائي موجود
  Future<int> updateDrugInteraction(Map<String, dynamic> drugInteraction) async {
    final db = await DatabaseService.instance.database;
    return await db.update(
      'drug_interactions',
      drugInteraction,
      where: 'id = ?',
      whereArgs: [drugInteraction['id']],
    );
  }
  
  /// حذف تفاعل دوائي
  Future<int> deleteDrugInteraction(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete(
      'drug_interactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// الحصول على قائمة الأدوية التي لها تفاعلات دوائية
  Future<List<Map<String, dynamic>>> getMedicationsWithInteractions() async {
    final db = await DatabaseService.instance.database;
    return await db.rawQuery('''
      SELECT DISTINCT m.* FROM medications m
      INNER JOIN drug_interactions di ON m.id = di.medication_id
      ORDER BY m.trade_name ASC
    ''');
  }
  
  /// الحصول على التفاعلات الدوائية حسب مستوى الخطورة
  Future<List<Map<String, dynamic>>> getDrugInteractionsBySeverity(String severityLevel) async {
    final db = await DatabaseService.instance.database;
    return await db.query(
      'drug_interactions',
      where: 'severity_level = ?',
      whereArgs: [severityLevel],
    );
  }
}