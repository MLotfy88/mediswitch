import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for updating the database schema and data
class DatabaseUpdate {
  // Singleton instance
  static final DatabaseUpdate instance = DatabaseUpdate._privateConstructor();
  
  // Private constructor
  DatabaseUpdate._privateConstructor();
  
  /// Updates the database schema and data
  Future<void> updateDatabase() async {
    try {
      // Get the database
      final Database db = await openDatabase('mediswitch.db');
      
      // Check if dose_equivalents table exists
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='dose_equivalents'"
      );
      
      // Create dose_equivalents table if it doesn't exist
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE dose_equivalents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER,
            equivalent_medication_id INTEGER,
            ratio REAL,
            notes TEXT,
            FOREIGN KEY (medication_id) REFERENCES medications(id),
            FOREIGN KEY (equivalent_medication_id) REFERENCES medications(id)
          )
        ''');
      }
      
      // Check if drug_interactions table exists
      final List<Map<String, dynamic>> interactionTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='drug_interactions'"
      );
      
      // Create drug_interactions table if it doesn't exist
      if (interactionTables.isEmpty) {
        await db.execute('''
          CREATE TABLE drug_interactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id_1 INTEGER,
            medication_id_2 INTEGER,
            severity TEXT,
            description TEXT,
            recommendation TEXT,
            FOREIGN KEY (medication_id_1) REFERENCES medications(id),
            FOREIGN KEY (medication_id_2) REFERENCES medications(id)
          )
        ''');
      }
      
      // Check if weight_dose_calculators table exists
      final List<Map<String, dynamic>> calculatorTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='weight_dose_calculators'"
      );
      
      // Create weight_dose_calculators table if it doesn't exist
      if (calculatorTables.isEmpty) {
        await db.execute('''
          CREATE TABLE weight_dose_calculators(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER,
            min_dose_per_kg REAL,
            max_dose_per_kg REAL,
            dose_unit TEXT,
            frequency INTEGER,
            frequency_unit TEXT,
            min_age INTEGER,
            max_age INTEGER,
            notes TEXT,
            FOREIGN KEY (medication_id) REFERENCES medications(id)
          )
        ''');
      }
      
      // Close the database
      await db.close();
    } catch (e) {
      debugPrint('Error updating database: $e');
    }
  }
}