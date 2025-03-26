import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

/// Service responsible for updating the database schema and data
class DatabaseUpdate {
  // Singleton instance
  static final DatabaseUpdate instance = DatabaseUpdate._privateConstructor();

  // Private constructor
  DatabaseUpdate._privateConstructor();

  /// Updates the database schema and data
  Future<void> updateDatabase() async {
    try {
      // Get the database path
      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'mediswitch.db');

      // Set the password for SQLCipher
      String password = 'your_encryption_key'; // Replace with a secure key

      // Open the database with SQLCipher
      Database db = await openDatabase(
        path,
        password: password,
        version: 1,
        onCreate: (Database db, int version) async {
          // Create dose_equivalents table
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

          // Create drug_interactions table
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

          // Create weight_dose_calculators table
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
        },
      );

      // Close the database
      await db.close();
    } catch (e) {
      debugPrint('Error updating database: $e');
    }
  }
}
