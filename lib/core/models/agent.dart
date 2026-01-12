import 'package:flutter/foundation.dart';
import 'dart:math';

enum AgentStatus {
  actif,
  en_attente_confirmation,
  suspendu;

  String get displayName {
    switch (this) {
      case AgentStatus.actif:
        return 'Actif';
      case AgentStatus.en_attente_confirmation:
        return 'En attente de confirmation';
      case AgentStatus.suspendu:
        return 'Suspendu';
    }
  }

  String get databaseValue {
    return name;
  }

  static AgentStatus? fromString(String? value) {
    if (value == null) return null;
    try {
      final normalizedValue = value.trim().toLowerCase();
      return AgentStatus.values.firstWhere(
        (e) => e.name == normalizedValue,
      );
    } catch (e) {
      debugPrint('Erreur lors du parsing du statut: $value');
      return null;
    }
  }
}

enum AgentRole {
  agent,
  responsable,
  directeur_regionnal;

  String get displayName {
    switch (this) {
      case AgentRole.agent:
        return 'Agent';
      case AgentRole.responsable:
        return 'Responsable';
      case AgentRole.directeur_regionnal:
        return 'Directeur Régional';
    }
  }

  String get databaseValue {
    return name;
  }

  static AgentRole? fromString(String? value) {
    if (value == null) return null;
    try {
      // Normaliser la valeur : enlever les espaces et convertir en minuscules
      final normalizedValue = value.trim().toLowerCase();
      return AgentRole.values.firstWhere(
        (e) => e.name == normalizedValue,
      );
    } catch (e) {
      debugPrint('Erreur lors du parsing du rôle: $value');
      return null;
    }
  }
}

class Agent {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final int? pinCode;
  final AgentRole role;
  final AgentStatus statutCompte;

  Agent({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.pinCode,
    required this.role,
    required this.statutCompte,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: int.parse(json['id'].toString()),
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      pinCode: json['pin_code'] != null ? int.parse(json['pin_code'].toString()) : null,
      role: AgentRole.fromString(json['role']) ?? AgentRole.agent,
      statutCompte: AgentStatus.fromString(json['statut_compte']) ?? AgentStatus.en_attente_confirmation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'pin_code': pinCode,
      'role': role.databaseValue,
      'statut_compte': statutCompte.databaseValue,
    };
  }

  String get fullName => '$firstname $lastname'.trim();

  bool get hasPinCode => pinCode != null;
  
  bool get isActif => statutCompte == AgentStatus.actif;
  bool get isEnAttenteConfirmation => statutCompte == AgentStatus.en_attente_confirmation;
  bool get isSuspendu => statutCompte == AgentStatus.suspendu;
}

/// Génère un mot de passe simple de 8 caractères (lettres et chiffres uniquement)
String generateStrongPassword({int length = 8}) {
  const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const String numbers = '0123456789';
  const String allChars = '$lowercase$uppercase$numbers';
  
  final random = Random.secure();
  final password = StringBuffer();
  
  // S'assurer d'avoir au moins une lettre minuscule, une majuscule et un chiffre
  password.write(lowercase[random.nextInt(lowercase.length)]);
  password.write(uppercase[random.nextInt(uppercase.length)]);
  password.write(numbers[random.nextInt(numbers.length)]);
  
  // Remplir le reste avec des caractères aléatoires (lettres et chiffres)
  for (int i = password.length; i < length; i++) {
    password.write(allChars[random.nextInt(allChars.length)]);
  }
  
  // Mélanger les caractères
  final passwordList = password.toString().split('')..shuffle(random);
  return passwordList.join();
}
