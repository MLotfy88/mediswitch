import 'package:equatable/equatable.dart';

class WeightDoseCalculator extends Equatable {
  final int? id;
  final int medicationId;
  final double minDosePerKg;
  final double maxDosePerKg;
  final String unit;
  final int minAgeMonths;
  final int maxAgeMonths;
  final double minWeightKg;
  final double maxWeightKg;
  final int maxDailyDoses;
  final String notes;
  final String warningThreshold; // 'none', 'low', 'medium', 'high'
  
  const WeightDoseCalculator({
    this.id,
    required this.medicationId,
    required this.minDosePerKg,
    required this.maxDosePerKg,
    required this.unit,
    this.minAgeMonths = 0,
    this.maxAgeMonths = 1200, // 100 years
    this.minWeightKg = 0,
    this.maxWeightKg = 500, // Maximum reasonable weight
    this.maxDailyDoses = 4,
    this.notes = '',
    this.warningThreshold = 'none',
  });

  // Calculate single dose based on weight
  Map<String, double> calculateDose(double weightKg, int ageMonths) {
    // Check if weight and age are within allowed range
    if (weightKg < minWeightKg || weightKg > maxWeightKg) {
      throw Exception('الوزن خارج النطاق المسموح به');
    }
    
    if (ageMonths < minAgeMonths || ageMonths > maxAgeMonths) {
      throw Exception('العمر خارج النطاق المسموح به');
    }
    
    // Calculate minimum and maximum single doses
    final minSingleDose = minDosePerKg * weightKg;
    final maxSingleDose = maxDosePerKg * weightKg;
    
    // Calculate daily doses
    final minDailyDose = minSingleDose * maxDailyDoses;
    final maxDailyDose = maxSingleDose * maxDailyDoses;
    
    return {
      'minSingleDose': minSingleDose,
      'maxSingleDose': maxSingleDose,
      'minDailyDose': minDailyDose,
      'maxDailyDose': maxDailyDose,
      'dosesPerDay': maxDailyDoses.toDouble(),
    };
  }

  // Convert kg to lb
  static double kgToLb(double kg) {
    return kg * 2.20462;
  }
  
  // Convert lb to kg
  static double lbToKg(double lb) {
    return lb / 2.20462;
  }

  // Check if dose exceeds safety threshold
  bool isDoseSafe(double proposedDose, double weightKg) {
    final maxSafeDose = maxDosePerKg * weightKg;
    return proposedDose <= maxSafeDose;
  }

  // Get warning level based on proposed dose
  String getWarningLevel(double proposedDose, double weightKg) {
    final maxSafeDose = maxDosePerKg * weightKg;
    final ratio = proposedDose / maxSafeDose;
    
    if (ratio > 1.2) return 'high';
    if (ratio > 1.0) return 'medium';
    if (ratio > 0.9) return 'low';
    return 'none';
  }

  // Factory constructor to create a WeightDoseCalculator from a JSON map
  factory WeightDoseCalculator.fromJson(Map<String, dynamic> json) {
    return WeightDoseCalculator(
      id: json['id'] as int?,
      medicationId: json['medication_id'] as int,
      minDosePerKg: json['min_dose_per_kg'] is double 
          ? json['min_dose_per_kg'] 
          : double.tryParse(json['min_dose_per_kg'].toString()) ?? 0.0,
      maxDosePerKg: json['max_dose_per_kg'] is double 
          ? json['max_dose_per_kg'] 
          : double.tryParse(json['max_dose_per_kg'].toString()) ?? 0.0,
      unit: json['unit'] as String? ?? 'mg',
      minAgeMonths: json['min_age_months'] as int? ?? 0,
      maxAgeMonths: json['max_age_months'] as int? ?? 1200,
      minWeightKg: json['min_weight_kg'] is double 
          ? json['min_weight_kg'] 
          : double.tryParse(json['min_weight_kg'].toString()) ?? 0.0,
      maxWeightKg: json['max_weight_kg'] is double 
          ? json['max_weight_kg'] 
          : double.tryParse(json['max_weight_kg'].toString()) ?? 500.0,
      maxDailyDoses: json['max_daily_doses'] as int? ?? 4,
      notes: json['notes'] as String? ?? '',
      warningThreshold: json['warning_threshold'] as String? ?? 'none',
    );
  }

  // Convert a WeightDoseCalculator to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'min_dose_per_kg': minDosePerKg,
      'max_dose_per_kg': maxDosePerKg,
      'unit': unit,
      'min_age_months': minAgeMonths,
      'max_age_months': maxAgeMonths,
      'min_weight_kg': minWeightKg,
      'max_weight_kg': maxWeightKg,
      'max_daily_doses': maxDailyDoses,
      'notes': notes,
      'warning_threshold': warningThreshold,
    };
  }

  @override
  List<Object?> get props => [
    id, 
    medicationId, 
    minDosePerKg, 
    maxDosePerKg, 
    unit, 
    minAgeMonths, 
    maxAgeMonths, 
    minWeightKg, 
    maxWeightKg, 
    maxDailyDoses, 
    notes, 
    warningThreshold
  ];
}