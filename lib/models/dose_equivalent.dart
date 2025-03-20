import 'package:equatable/equatable.dart';

class DoseEquivalent extends Equatable {
  final int? id;
  final int medicationId;
  final int equivalentMedicationId;
  final double conversionFactor;
  final String unit;
  final String notes;
  final double efficacyPercentage;
  final double toxicityPercentage;
  
  const DoseEquivalent({
    this.id,
    required this.medicationId,
    required this.equivalentMedicationId,
    required this.conversionFactor,
    required this.unit,
    this.notes = '',
    this.efficacyPercentage = 100.0,
    this.toxicityPercentage = 0.0,
  });

  // Calculate equivalent dose
  double calculateEquivalentDose(double originalDose) {
    return originalDose * conversionFactor;
  }

  // Factory constructor to create a DoseEquivalent from a JSON map
  factory DoseEquivalent.fromJson(Map<String, dynamic> json) {
    return DoseEquivalent(
      id: json['id'] as int?,
      medicationId: json['medication_id'] as int,
      equivalentMedicationId: json['equivalent_medication_id'] as int,
      conversionFactor: json['conversion_factor'] is double 
          ? json['conversion_factor'] 
          : double.tryParse(json['conversion_factor'].toString()) ?? 1.0,
      unit: json['unit'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      efficacyPercentage: json['efficacy_percentage'] is double 
          ? json['efficacy_percentage'] 
          : double.tryParse(json['efficacy_percentage'].toString()) ?? 100.0,
      toxicityPercentage: json['toxicity_percentage'] is double 
          ? json['toxicity_percentage'] 
          : double.tryParse(json['toxicity_percentage'].toString()) ?? 0.0,
    );
  }

  // Convert a DoseEquivalent to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'equivalent_medication_id': equivalentMedicationId,
      'conversion_factor': conversionFactor,
      'unit': unit,
      'notes': notes,
      'efficacy_percentage': efficacyPercentage,
      'toxicity_percentage': toxicityPercentage,
    };
  }

  @override
  List<Object?> get props => [
    id, 
    medicationId, 
    equivalentMedicationId, 
    conversionFactor, 
    unit, 
    notes, 
    efficacyPercentage, 
    toxicityPercentage
  ];
}