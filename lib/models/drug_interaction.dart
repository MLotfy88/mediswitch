import 'package:equatable/equatable.dart';

class DrugInteraction extends Equatable {
  final int? id;
  final int medicationId;
  final int interactingMedicationId;
  final String severityLevel; // 'minor', 'moderate', 'major', 'contraindicated'
  final String effect;
  final String effectAr;
  final String mechanism;
  final String mechanismAr;
  final String management;
  final String managementAr;
  final String reference;
  
  const DrugInteraction({
    this.id,
    required this.medicationId,
    required this.interactingMedicationId,
    required this.severityLevel,
    required this.effect,
    required this.effectAr,
    required this.mechanism,
    required this.mechanismAr,
    required this.management,
    required this.managementAr,
    this.reference = '',
  });

  // Factory constructor to create a DrugInteraction from a JSON map
  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    return DrugInteraction(
      id: json['id'] as int?,
      medicationId: json['medication_id'] as int,
      interactingMedicationId: json['interacting_medication_id'] as int,
      severityLevel: json['severity_level'] as String? ?? 'minor',
      effect: json['effect'] as String? ?? '',
      effectAr: json['effect_ar'] as String? ?? '',
      mechanism: json['mechanism'] as String? ?? '',
      mechanismAr: json['mechanism_ar'] as String? ?? '',
      management: json['management'] as String? ?? '',
      managementAr: json['management_ar'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
    );
  }

  // Convert a DrugInteraction to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'interacting_medication_id': interactingMedicationId,
      'severity_level': severityLevel,
      'effect': effect,
      'effect_ar': effectAr,
      'mechanism': mechanism,
      'mechanism_ar': mechanismAr,
      'management': management,
      'management_ar': managementAr,
      'reference': reference,
    };
  }

  // Get color based on severity level
  String get severityColor {
    switch (severityLevel) {
      case 'minor':
        return '#4CAF50'; // Green
      case 'moderate':
        return '#FFC107'; // Amber
      case 'major':
        return '#FF5722'; // Deep Orange
      case 'contraindicated':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  @override
  List<Object?> get props => [
    id, 
    medicationId, 
    interactingMedicationId, 
    severityLevel, 
    effect, 
    effectAr, 
    mechanism, 
    mechanismAr, 
    management, 
    managementAr, 
    reference
  ];
}