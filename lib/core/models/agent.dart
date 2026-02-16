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

/// Mots français sans caractères ambigus (i, l, I, L, o, O) ni chiffres.
/// Génère une passphrase facile à lire et dicter pour un mot de passe provisoire.
const _passphraseWords = [
  'Pomme', 'Arbre', 'Vent', 'Porte', 'Maison', 'Cafe', 'Eau', 'Feu',
  'Forme', 'Fort', 'Corps', 'Nord', 'Port', 'Part', 'Carte', 'Vente',
  'Temps', 'Coup', 'Debut', 'Effort', 'Enfant', 'Grand', 'Groupe',
  'Haut', 'Homme', 'Mort', 'Tortue', 'Vert', 'Banane', 'Orange',
];

/// Génère un mot de passe provisoire : 3 mots concaténés, sans chiffres.
/// Évite les caractères ambigus (I/L/1, O/0) pour faciliter la saisie.
String generateStrongPassword({int wordCount = 3}) {
  final random = Random.secure();
  return List.generate(wordCount, (_) => _passphraseWords[random.nextInt(_passphraseWords.length)]).join();
}
