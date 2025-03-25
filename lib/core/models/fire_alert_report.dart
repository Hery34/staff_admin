import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

enum AlertType {
  fausseAlerte,
  incendieMaitrisable,
  incendieHorsControle,
  alerte,
}

enum Declencheur {
  manuel,
  automatique,
}

class FireAlertReport {
  final int id;
  final DateTime date;
  final int? floor;
  final AlertType alertType;
  final bool isRunning;
  final int? createdBy;
  final DateTime? closedAt;
  final int? closedBy;
  final int? site;
  final Declencheur declencheur;
  final bool isComplete;
  final String? createdByName;
  final String? closedByName;
  final String? siteName;

  FireAlertReport({
    required this.id,
    required this.date,
    this.floor,
    required this.alertType,
    required this.isRunning,
    this.createdBy,
    this.closedAt,
    this.closedBy,
    this.site,
    required this.declencheur,
    required this.isComplete,
    this.createdByName,
    this.closedByName,
    this.siteName,
  });

  factory FireAlertReport.fromJson(Map<String, dynamic> json) {
    return FireAlertReport(
      id: int.parse(json['id'].toString()),
      date: DateTime.parse(json['date']),
      floor: json['floor'] != null ? int.parse(json['floor'].toString()) : null,
      alertType: _parseAlertType(json['alert_type']),
      isRunning: json['is_running'] ?? false,
      createdBy: json['created_by'] != null ? int.parse(json['created_by'].toString()) : null,
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
      closedBy: json['closed_by'] != null ? int.parse(json['closed_by'].toString()) : null,
      site: json['site'] != null ? int.parse(json['site'].toString()) : null,
      declencheur: _parseDeclencheur(json['declencheur']),
      isComplete: json['is_complete'] ?? false,
      createdByName: json['created_by_name'],
      closedByName: json['closed_by_name'],
      siteName: json['site_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'floor': floor,
      'alert_type': alertType.toString().split('.').last,
      'is_running': isRunning,
      'created_by': createdBy,
      'closed_at': closedAt?.toIso8601String(),
      'closed_by': closedBy,
      'site': site,
      'declencheur': declencheur.toString().split('.').last,
      'is_complete': isComplete,
      'created_by_name': createdByName,
      'closed_by_name': closedByName,
      'site_name': siteName,
    };
  }

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);
  String get formattedClosedAt => closedAt != null 
    ? DateFormat('dd/MM/yyyy HH:mm').format(closedAt!)
    : 'Non fermé';

  static AlertType _parseAlertType(String? value) {
    switch (value?.toLowerCase()) {
      case 'fausse alerte':
        return AlertType.fausseAlerte;
      case 'incendie maitrisable':
        return AlertType.incendieMaitrisable;
      case 'incendie hors de contrôle':
        return AlertType.incendieHorsControle;
      case 'incendie hors de controle':
        return AlertType.incendieHorsControle;
      case 'alerte':
        return AlertType.alerte;
      default:
        debugPrint('Alert type not recognized: $value');
        return AlertType.alerte;
    }
  }

  String get alertTypeDisplay {
    switch (alertType) {
      case AlertType.fausseAlerte:
        return 'Fausse alerte';
      case AlertType.incendieMaitrisable:
        return 'Incendie maîtrisable';
      case AlertType.incendieHorsControle:
        return 'Incendie hors de contrôle';
      case AlertType.alerte:
        return 'Alerte';
    }
  }

  static Declencheur _parseDeclencheur(String? value) {
    switch (value?.toLowerCase()) {
      case 'manuel':
        return Declencheur.manuel;
      case 'automatique':
        return Declencheur.automatique;
      default:
        return Declencheur.automatique;
    }
  }
} 