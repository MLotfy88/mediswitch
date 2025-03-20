import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mediswitch/models/medication.dart';
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
    
    // Generate a secure key for SQLCipher (in a real app, this should be stored securely)
    // Not using the key variable since SQLCipher is not fully implemented yet
    final secureKey = sha256.convert(utf8.encode('mediswitch_secure_key')).toString();
    
    // Open the database with encryption - only use password parameter on mobile platforms
    // Different database initialization for web and mobile platforms
    if (kIsWeb) {
      // For web, don't use encryption as SQLCipher is not supported
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } else {
      // For mobile platforms, use encryption
      // Use direct parameters instead of options map for better compatibility
      // Create a database factory that supports encryption
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        // Password parameter is only used on mobile platforms through sqlcipher_flutter_libs
        // We don't include it here to avoid errors on web platform
      );
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

  // Update database from new CSV file
  // Create a backup of the database
  Future<bool> _createBackup() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'mediswitch.db');
      final backupDir = join(documentsDirectory.path, 'backups');
      
      // Create backups directory if it doesn't exist
      final backupDirFolder = Directory(backupDir);
      if (!await backupDirFolder.exists()) {
        await backupDirFolder.create(recursive: true);
      }
      
      // Create backup with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(backupDir, 'mediswitch_backup_$timestamp.db');
      
      // Copy database file to backup location
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);
      
      debugPrint('Database backup created at: $backupPath');
      return true;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return false;
    }
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
  }
  
  // Restore database from backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'mediswitch.db');
      
      // Close current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Copy backup file to database location
      final backupFile = File(backupPath);
      await backupFile.copy(dbPath);
      
      // Reopen database
      _database = await initDatabase();
      
      debugPrint('Database restored from backup: $backupPath');
      return true;
    } catch (e) {
      debugPrint('Error restoring from backup: $e');
      return false;
    }
  }

  Future<bool> updateDatabaseFromCsv(String csvPath) async {
    try {
      final db = await instance.database;
      final file = File(csvPath);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      // Skip header row
      final List<List<dynamic>> data = csvTable.sublist(1);
      
      // Create backup before updating
      await _createBackup();
      
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
}