import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class Medication {
  final String tradeName;
  final String arabicName;
  final String oldPrice;
  final String price;
  final String active;
  final String mainCategory;
  final String mainCategoryAr;
  final String category;
  final String categoryAr;
  final String company;
  final String dosageForm;
  final String dosageFormAr;
  final String unit;
  final String usage;
  final String usageAr;
  final String description;
  final String lastPriceUpdate;

  Medication({
    required this.tradeName,
    required this.arabicName,
    required this.oldPrice,
    required this.price,
    required this.active,
    required this.mainCategory,
    required this.mainCategoryAr,
    required this.category,
    required this.categoryAr,
    required this.company,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.unit,
    required this.usage,
    required this.usageAr,
    required this.description,
    required this.lastPriceUpdate,
  });

  factory Medication.fromJson(List<dynamic> row) {
    return Medication(
      tradeName: row[0].toString(),
      arabicName: row[1].toString(),
      oldPrice: row[2].toString(),
      price: row[3].toString(),
      active: row[4].toString(),
      mainCategory: row[5].toString(),
      mainCategoryAr: row[6].toString(),
      category: row[7].toString(),
      categoryAr: row[8].toString(),
      company: row[9].toString(),
      dosageForm: row[10].toString(),
      dosageFormAr: row[11].toString(),
      unit: row[12].toString(),
      usage: row[13].toString(),
      usageAr: row[14].toString(),
      description: row[15].toString(),
      lastPriceUpdate: row[16].toString(),
    );
  }
}


class MedicationService {
  List<Medication> _medications = [];

  Future<void> loadMedicationsFromCSV() async {
    final String csvData = await rootBundle.loadString('meds.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
    _medications = csvTable.skip(1).map((row) => Medication.fromJson(row)).toList();
  }

  List<Medication> searchMedications(String query) {
    return _medications.where((medication) =>
        medication.tradeName.toLowerCase().contains(query.toLowerCase()) ||
        medication.arabicName.toLowerCase().contains(query.toLowerCase()) ||
        medication.active.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<void> updateMedicationPrice(String tradeName, String newPrice) async {
    final medicationIndex = _medications.indexWhere((medication) => medication.tradeName == tradeName);
    if (medicationIndex != -1) {
      _medications[medicationIndex] = Medication(
        tradeName: _medications[medicationIndex].tradeName,
        arabicName: _medications[medicationIndex].arabicName,
        oldPrice: _medications[medicationIndex].oldPrice,
        price: newPrice,
        active: _medications[medicationIndex].active,
        mainCategory: _medications[medicationIndex].mainCategory,
        mainCategoryAr: _medications[medicationIndex].mainCategoryAr,
        category: _medications[medicationIndex].category,
        categoryAr: _medications[medicationIndex].categoryAr,
        company: _medications[medicationIndex].company,
        dosageForm: _medications[medicationIndex].dosageForm,
        dosageFormAr: _medications[medicationIndex].dosageFormAr,
        unit: _medications[medicationIndex].unit,
        usage: _medications[medicationIndex].usage,
        usageAr: _medications[medicationIndex].usageAr,
        description: _medications[medicationIndex].description,
        lastPriceUpdate: _medications[medicationIndex].lastPriceUpdate,
      );
      await _saveMedicationsToCSV();
    }
  }

  Future<void> _saveMedicationsToCSV() async {
    List<List<dynamic>> medicationList = [_medications.map((medication) => [
      medication.tradeName,
      medication.arabicName,
      medication.oldPrice,
      medication.price,
      medication.active,
      medication.mainCategory,
      medication.mainCategoryAr,
      medication.category,
      medication.categoryAr,
      medication.company,
      medication.dosageForm,
      medication.dosageFormAr,
      medication.unit,
      medication.usage,
      medication.usageAr,
      medication.description,
      medication.lastPriceUpdate,
    ]).toList()];

    String csv = const ListToCsvConverter().convert(medicationList);
    // The following line is commented out because writing to rootBundle is not possible.
    // await rootBundle.writeString('meds.csv', csv);
    // Instead of writing to the rootBundle, I will print the CSV data to the console.
    print(csv);
  }
}
