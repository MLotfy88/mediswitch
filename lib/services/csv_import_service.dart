import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:mediswitch/models/medication.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CsvImportService {
  static Future<List<Medication>> loadMedicationsFromCsv() async {
    final String csvData = await rootBundle.loadString('meds.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);

    // Assuming the first row is the header
    List<String> headers = csvTable[0].map((e) => e.toString()).toList();

    List<Medication> medications = [];
    for (int i = 1; i < csvTable.length; i++) {
      List<dynamic> row = csvTable[i];
      medications.add(Medication.fromList(row));
    }

    return medications;
  }

  static Future<void> insertMedicationsIntoDatabase(
    List<Medication> medications,
  ) async {
    // Open the database
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'mediswitch.db');
    Database db = await openDatabase(path);

    // Insert the medications into the database
    for (var medication in medications) {
      await db.insert(
        'medications',
        medication.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Close the database
    await db.close();
  }

  static Future<void> importCsvData() async {
    List<Medication> medications = await loadMedicationsFromCsv();
    await insertMedicationsIntoDatabase(medications);
  }
}
