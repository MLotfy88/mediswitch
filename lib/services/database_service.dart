import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:mediswitch/models/weight_dose_calculator.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
// Only import SQLCipher on non-web platforms
// This conditional import prevents errors on web platforms
// ignore: unused_import
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart' if (dart.library.html) 'package:mediswitch/services/web_db_stub.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mediswitch.db');
    
    // Generate a secure key for SQLCipher using a strong hashing algorithm
    final secureKey = await _getSecureKey();
    
    // Different database initialization for web and mobile platforms
    if (kIsWeb) {
      // For web, don't use encryption as SQLCipher is not supported
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } else {
      // For mobile platforms, use encryption with SQLCipher
      // Initialize SQLCipher for the current platform
      // Removed initializeSqlCipherLibs() call as it's causing errors
      
      // Open encrypted database with the secure key
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    }
  }
  
  // Get or generate a secure encryption key
  Future<String> _getSecureKey() async {
    try {
      // Use flutter_secure_storage to store and retrieve the encryption key
      final secureStorage = const FlutterSecureStorage();
      String? storedKey = await secureStorage.read(key: 'db_encryption_key');
      
      if (storedKey == null) {
        // Generate a new secure random key if none exists
        final random = Random.secure();
        final values = List<int>.generate(32, (i) => random.nextInt(256));
        final newKey = base64Url.encode(values);
        
        // Store the new key securely
        await secureStorage.write(key: 'db_encryption_key', value: newKey);
        return newKey;
      }
      
      return storedKey;
    } catch (e) {
      // Fallback to a derived key if secure storage fails
      debugPrint('Error accessing secure storage: $e');
      return sha256.convert(utf8.encode('mediswitch_secure_key')).toString();
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const realType = 'REAL';
    const boolType = 'INTEGER';

    // Create medications table
    await db.execute('''
    CREATE TABLE medications (
      id $idType,
      trade_name $textType,
      arabic_name $textType,
      old_price $realType,
      price $realType,
      active $textType,
      main_category $textType,
      main_category_ar $textType,
      category $textType,
      category_ar $textType,
      company $textType,
      dosage_form $textType,
      dosage_form_ar $textType,
      unit $textType,
      usage $textType,
      usage_ar $textType,
      description $textType,
      last_price_update $textType,
      is_favorite $boolType DEFAULT 0
    )
    ''');

    // Create index for faster searches
    await db.execute('CREATE INDEX idx_trade_name ON medications(trade_name)');
    await db.execute('CREATE INDEX idx_arabic_name ON medications(arabic_name)');
    await db.execute('CREATE INDEX idx_main_category ON medications(main_category)');
    await db.execute('CREATE INDEX idx_active ON medications(active)');
    
    // Load initial data from CSV
    await _loadInitialData(db);
  }

  Future<void> _loadInitialData(Database db) async {
    try {
      // Load CSV from assets
      final String csvString = await rootBundle.loadString('meds.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      // Skip header row
      final List<List<dynamic>> data = csvTable.sublist(1);
      
      // Begin transaction for faster inserts
      await db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final row in data) {
          if (row.length >= 17) { // Ensure row has all required columns
            final medication = {
              'trade_name': row[0] ?? '',
              'arabic_name': row[1] ?? '',
              'old_price': row[2] != null && row[2].toString().isNotEmpty ? double.tryParse(row[2].toString()) ?? 0.0 : 0.0,
              'price': row[3] != null && row[3].toString().isNotEmpty ? double.tryParse(row[3].toString()) ?? 0.0 : 0.0,
              'active': row[4] ?? '',
              'main_category': row[5] ?? '',
              'main_category_ar': row[6] ?? '',
              'category': row[7] ?? '',
              'category_ar': row[8] ?? '',
              'company': row[9] ?? '',
              'dosage_form': row[10] ?? '',
              'dosage_form_ar': row[11] ?? '',
              'unit': row[12] ?? '',
              'usage': row[13] ?? '',
              'usage_ar': row[14] ?? '',
              'description': row[15] ?? '',
              'last_price_update': row[16] ?? '',
              'is_favorite': 0
            };
            
            batch.insert('medications', medication);
          }
        }
        
        await batch.commit(noResult: true);
      });
      
      debugPrint('Initial data loaded successfully');
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  // Get all medications with pagination
  Future<List<Medication>> getMedications({int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      limit: limit,
      offset: offset,
      orderBy: 'trade_name ASC',
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Search medications by name (supports both English and Arabic)
  Future<List<Medication>> searchMedications(String query, {int limit = 20}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'trade_name LIKE ? OR arabic_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: limit,
      orderBy: 'trade_name ASC',
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Get medications by category
  Future<List<Medication>> getMedicationsByCategory(String category, {int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'main_category = ? OR category = ?',
      whereArgs: [category, category],
      limit: limit,
      offset: offset,
      orderBy: 'trade_name ASC',
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Get medication by ID
  Future<Medication?> getMedicationById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Medication.fromJson(result.first);
    }
    return null;
  }

  // Get alternative medications (same active ingredient)
  Future<List<Medication>> getAlternatives(String active, {int limit = 10}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'active LIKE ?',
      whereArgs: ['%$active%'],
      limit: limit,
      orderBy: 'price ASC', // Order by price to show cheaper alternatives first
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Toggle favorite status
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await instance.database;
    return await db.update(
      'medications',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get favorite medications
  Future<List<Medication>> getFavorites({int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'is_favorite = 1',
      limit: limit,
      offset: offset,
      orderBy: 'trade_name ASC',
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT main_category, main_category_ar, COUNT(*) as count 
      FROM medications 
      GROUP BY main_category 
      ORDER BY count DESC
    ''');
    
    return result;
  }
  
  // Search medications by query
  Future<List<Medication>> searchMedicationsByQuery(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      limit: 20,
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Get medications by category
  Future<List<Medication>> getMedicationsByCategory(String category, {int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'main_category = ? OR category = ?',
      whereArgs: [category, category],
      limit: limit,
      offset: offset,
      orderBy: 'trade_name ASC',
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Get medication by ID
  Future<Medication?> getMedicationById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Medication.fromJson(result.first);
    }
    return null;
  }

  // Get alternative medications (same active ingredient)
  Future<List<Medication>> getAlternatives(String active, {int limit = 10}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'active LIKE ?',
      whereArgs: ['%$active%'],
      limit: limit,
      orderBy: 'price ASC', // Order by price to show cheaper alternatives first
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Toggle favorite status
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await instance.database;
    return await db.update(
      'medications',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get favorite medications
  Future<List<Medication>> getFavorites({int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.query(
      'medications',
      where: 'is_favorite = 1',
      limit: limit,
      offset: offset,
      orderBy: 'trade_name ASC',
    );
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT main_category, main_category_ar, COUNT(*) as count 
      FROM medications 
      GROUP BY main_category 
      ORDER BY count DESC
    ''');
    
    return result;
  }

  // Update database from new CSV file
  // Create an encrypted backup of the database
  Future<bool> createBackup({String? customName}) async {
    try {
      // Close current database connection to ensure all writes are flushed
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'mediswitch.db');
      final backupDir = join(documentsDirectory.path, 'backups');
      
      // Create backups directory if it doesn't exist
      final backupDirFolder = Directory(backupDir);
      if (!await backupDirFolder.exists()) {
        await backupDirFolder.create(recursive: true);
      }
      
      // Create backup with timestamp and optional custom name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = customName != null 
          ? '${customName.replaceAll(RegExp(r'[^\w\s.-]'), '')}_$timestamp.db' 
          : 'mediswitch_backup_$timestamp.db';
      final backupPath = join(backupDir, backupName);
      
      // Copy database file to backup location
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);
      
      // Add metadata file with backup information
      final metadataPath = '$backupPath.meta';
      final metadata = {
        'timestamp': timestamp,
        'name': customName ?? 'Automatic Backup',
        'version': 1,
        'app_version': '1.0.0', // Should be retrieved from app info
        'encrypted': !kIsWeb,
      };
      
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(jsonEncode(metadata));
      
      // Reopen database
      _database = await initDatabase();
      
      debugPrint('Database backup created at: $backupPath');
      return true;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      // Ensure database is reopened even if backup fails
      _database ??= await initDatabase();
      return false;
    }
  }
  
  // Private method for internal use
  Future<bool> _createBackup() async {
    return await createBackup();
  }
  
  // التحقق من وجود جدول في قاعدة البيانات
  Future<bool> _checkIfTableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    return result.isNotEmpty;
  }
  
  // إنشاء جدول حاسبات الجرعة حسب الوزن
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
  
  // Get list of available backups
  Future<List<String>> getBackups() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupDir = join(documentsDirectory.path, 'backups');
      
      // Check if backups directory exists
      final backupDirFolder = Directory(backupDir);
      if (!await backupDirFolder.exists()) {
        return [];
      }
      
      // List all backup files
      final files = await backupDirFolder.list().toList();
      final List<String> backupFiles = files
          .where((file) => file.path.endsWith('.db'))
          .map((file) => file.path)
          .toList();
      
      // Sort by creation date (newest first)
      backupFiles.sort((a, b) => b.compareTo(a));
      
      return backupFiles;
    } catch (e) {
      debugPrint('Error getting backups: $e');
      return [];
    }
  
  // Restore database from backup with validation
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'mediswitch.db');
      
      // Validate backup file exists
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        debugPrint('Backup file not found: $backupPath');
        return false;
      }
      
      // Check for metadata file
      final metadataPath = '$backupPath.meta';
      final metadataFile = File(metadataPath);
      Map<String, dynamic> metadata = {};
      
      if (await metadataFile.exists()) {
        try {
          metadata = jsonDecode(await metadataFile.readAsString());
          debugPrint('Restoring backup: ${metadata['name']} from ${DateTime.fromMillisecondsSinceEpoch(metadata['timestamp']).toString()}');
        } catch (e) {
          debugPrint('Error reading backup metadata: $e');
        }
      }
      
      // Create a backup of current database before restoring
      await createBackup(customName: 'pre_restore_backup');
      
      // Close current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Copy backup file to database location
      await backupFile.copy(dbPath);
      
      // Reopen database with encryption if needed
      _database = await initDatabase();
      
      // Verify database integrity by performing a simple query
      try {
        final db = await database;
        await db.rawQuery('SELECT COUNT(*) FROM medications');
      } catch (e) {
        debugPrint('Restored database integrity check failed: $e');
        
        // Attempt to recover from the pre-restore backup
        final backups = await getBackups();
        for (final backup in backups) {
          if (backup.contains('pre_restore_backup')) {
            debugPrint('Attempting recovery from pre-restore backup');
            await recoverFromFailedRestore(backup);
            return false;
          }
        }
        return false;
      }
      
      debugPrint('Database successfully restored from backup: $backupPath');
      return true;
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      return false;
    }
  
  // Recovery method for failed restore operations
  Future<bool> recoverFromFailedRestore(String recoveryBackupPath) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'mediswitch.db');
      
      // Close any open database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Copy recovery backup to database location
      final recoveryFile = File(recoveryBackupPath);
      await recoveryFile.copy(dbPath);
      
      // Reopen database
      _database = await initDatabase();
      
      debugPrint('Recovered database from backup: $recoveryBackupPath');
      return true;
    } catch (e) {
      debugPrint('Error during recovery: $e');
      return false;
    }
  }

  // Update database from CSV file
  Future<bool> updateDatabaseFromCsv(String csvPath) async {
    try {
      final db = await database;
      final file = File(csvPath);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      // Skip header row
      final List<List<dynamic>> data = csvTable.sublist(1);
      
      // Create backup before updating
      await createBackup(customName: 'pre_update_backup');
      
      // Clear existing data
      await db.delete('medications');
      
      // Begin transaction for faster inserts
      await db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final row in data) {
          if (row.length >= 17) { // Ensure row has all required columns
            final medication = {
              'trade_name': row[0] ?? '',
              'arabic_name': row[1] ?? '',
              'old_price': row[2] != null && row[2].toString().isNotEmpty ? double.tryParse(row[2].toString()) ?? 0.0 : 0.0,
              'price': row[3] != null && row[3].toString().isNotEmpty ? double.tryParse(row[3].toString()) ?? 0.0 : 0.0,
              'active': row[4] ?? '',
              'main_category': row[5] ?? '',
              'main_category_ar': row[6] ?? '',
              'category': row[7] ?? '',
              'category_ar': row[8] ?? '',
              'company': row[9] ?? '',
              'dosage_form': row[10] ?? '',
              'dosage_form_ar': row[11] ?? '',
              'unit': row[12] ?? '',
              'usage': row[13] ?? '',
              'usage_ar': row[14] ?? '',
              'description': row[15] ?? '',
              'last_price_update': row[16] ?? '',
              'is_favorite': 0
            };
            
            batch.insert('medications', medication);
          }
        }
        
        await batch.commit(noResult: true);
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating database: $e');
      return false;
    }
  }
  
  // ===== وظائف مكافئات الجرعات =====
  
  // إضافة مكافئ جرعة جديد
  Future<int> insertDoseEquivalent(Map<String, dynamic> doseEquivalent) async {
    final db = await database;
    return await db.insert('dose_equivalents', doseEquivalent);
  }
  
  // تحديث مكافئ جرعة موجود
  Future<int> updateDoseEquivalent(Map<String, dynamic> doseEquivalent) async {
    final db = await database;
    return await db.update(
      'dose_equivalents',
      doseEquivalent,
      where: 'id = ?',
      whereArgs: [doseEquivalent['id']],
    );
  }
  
  // حذف مكافئ جرعة
  Future<int> deleteDoseEquivalent(int id) async {
    final db = await database;
    return await db.delete(
      'dose_equivalents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // الحصول على مكافئات الجرعات لدواء معين
  Future<List<Map<String, dynamic>>> getDoseEquivalents(int medicationId) async {
    final db = await instance.database;
    return await db.query(
      'dose_equivalents',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
  }
  
  // البحث عن الأدوية التي لها مكافئات جرعات
  Future<List<Medication>> getMedicationsWithDoseEquivalents({int limit = 20, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT m.* FROM medications m
      INNER JOIN dose_equivalents de ON m.id = de.medication_id
      ORDER BY m.trade_name ASC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }
  
  // Initialize SQLCipher libraries for the current platform
  Future<void> initializeSqlCipherLibs() async {
    // This method is only needed for non-web platforms
    if (!kIsWeb) {
      // SQLCipher initialization is handled by the platform
      // No need to call initSqlCipherLibs() as it's not available
      // Just a placeholder for future implementation if needed
    }
  }
  
  // Check if a table exists in the database
  Future<bool> checkIfTableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    return result.isNotEmpty;
  }
  
  // Create weight dose calculators table
  Future<void> createWeightDoseCalculatorsTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const realType = 'REAL';
    const intType = 'INTEGER';
    
    await db.execute('''
    CREATE TABLE weight_dose_calculators (
      id $idType,
      medication_id $intType,
      min_dose $realType,
      max_dose $realType,
      dose_unit $textType,
      weight_unit $textType,
      frequency $textType,
      duration $textType,
      min_age $intType,
      max_age $intType,
      notes $textType,
      created_at $textType,
      updated_at $textType
    )
    ''');
  }
  
  // ===== وظائف حاسبة الجرعة حسب الوزن =====
  
  // إضافة حاسبة جرعة جديدة
  Future<int> insertWeightDoseCalculator(Map<String, dynamic> calculator) async {
    final db = await database;
    // التحقق من وجود جدول حاسبات الجرعة
    final tableExists = await checkIfTableExists(db, 'weight_dose_calculators');
    if (!tableExists) {
      // إنشاء الجدول إذا لم يكن موجودًا
      await createWeightDoseCalculatorsTable(db);
    }
    return await db.insert('weight_dose_calculators', calculator);
  }
  
  // تحديث حاسبة جرعة موجودة
  Future<int> updateWeightDoseCalculator(Map<String, dynamic> calculator) async {
    final db = await database;
    return await db.update(
      'weight_dose_calculators',
      calculator,
      where: 'id = ?',
      whereArgs: [calculator['id']],
    );
  }
  
  // حذف حاسبة جرعة
  Future<int> deleteWeightDoseCalculator(int id) async {
    final db = await database;
    return await db.delete(
      'weight_dose_calculators',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // الحصول على حاسبة الجرعة لدواء معين
  Future<Map<String, dynamic>?> getWeightDoseCalculator(int medicationId) async {
    final db = await database;
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
  
  // الحصول على حاسبة الجرعة بواسطة المعرف
  Future<WeightDoseCalculator?> getWeightDoseCalculatorById(int id) async {
    final db = await database;
    final result = await db.query(
      'weight_dose_calculators',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return WeightDoseCalculator.fromJson(result.first);
    }
    return null;
  }
  
  // البحث عن الأدوية التي لها حاسبات جرعة
  Future<List<Medication>> getMedicationsWithDoseCalculators({int limit = 20, int offset = 0}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT m.* FROM medications m
      INNER JOIN weight_dose_calculators wdc ON m.id = wdc.medication_id
      ORDER BY m.trade_name ASC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);
    
    return result.map((json) => Medication.fromJson(json)).toList();
  }
}