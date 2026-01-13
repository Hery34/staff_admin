# Audit : Problème de date de génération affichée à 00h00

## Problème identifié
La date de génération (`formattedToDoListDateTime`) s'affiche avec l'heure à "00h00" au lieu de l'heure réelle.

## Analyse du code

### 1. Modèle Report (`lib/core/models/report.dart`)

**Ligne 36-40** : Getter `formattedToDoListDateTime`
```dart
String get formattedToDoListDateTime {
  final todoDateTime = toDoList['date_time'];
  if (todoDateTime == null) return 'Non spécifié';
  return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(todoDateTime));
}
```

**Problèmes potentiels :**
- ✅ Le parsing avec `DateTime.parse()` devrait fonctionner si la date est au format ISO8601
- ⚠️ Si `todoDateTime` est déjà un objet DateTime (et non une string), `DateTime.parse()` échouera
- ⚠️ Si la date dans la base de données n'a pas d'heure (ou est à 00:00:00), elle s'affichera comme "00h00"

### 2. Service ReportService (`lib/core/services/report_service.dart`)

**Ligne 38-44** : Requête Supabase
```dart
to_do_list (
  date_time,
  site:site_id (
    name,
    site_code
  )
)
```

**Ligne 60-62** : Traitement des données
```dart
if (json['to_do_list'] != null) {
  final toDoList = json['to_do_list'];
  reportJson['to_do_list_date_time'] = toDoList['date_time'];
  // ...
}
```

**Problèmes identifiés :**
- ⚠️ Le code crée `to_do_list_date_time` mais ne modifie pas `to_do_list` lui-même
- ✅ Le modèle Report attend `to_do_list` comme Map, ce qui est correct
- ⚠️ La valeur `date_time` dans `to_do_list` peut être :
  - Une string ISO8601 (ex: "2024-01-15T00:00:00")
  - Un objet DateTime déjà parsé
  - Une date sans heure (timestamp à minuit)

### 3. Base de données (`database/database_schema.sql`)

**Ligne 198** : Table `to_do_list`
```sql
date_time timestamp without time zone NOT NULL,
```

**Problèmes potentiels :**
- ⚠️ `timestamp without time zone` : Si les dates sont insérées sans heure, elles seront à 00:00:00
- ⚠️ Si les dates sont insérées comme DATE au lieu de TIMESTAMP, elles seront converties à 00:00:00

## Causes possibles

### Cause 1 : Date stockée sans heure dans la base de données
- Les enregistrements dans `to_do_list.date_time` sont insérés sans heure
- Solution : Vérifier comment les dates sont insérées dans la base de données

### Cause 2 : Format de date incorrect retourné par Supabase
- Supabase peut retourner la date dans un format qui ne contient pas l'heure
- Solution : Ajouter un debug pour voir le format exact retourné

### Cause 3 : Parsing incorrect dans le modèle
- Si `todoDateTime` est déjà un DateTime, `DateTime.parse()` échouera
- Solution : Gérer les deux cas (string et DateTime)

## Solutions recommandées

### Solution 1 : Améliorer le parsing dans le modèle (RECOMMANDÉ)
```dart
String get formattedToDoListDateTime {
  final todoDateTime = toDoList['date_time'];
  if (todoDateTime == null) return 'Non spécifié';
  
  DateTime dateTime;
  if (todoDateTime is DateTime) {
    dateTime = todoDateTime;
  } else if (todoDateTime is String) {
    try {
      dateTime = DateTime.parse(todoDateTime);
    } catch (e) {
      debugPrint('Error parsing date_time: $todoDateTime');
      return 'Date invalide';
    }
  } else {
    return 'Format de date non supporté';
  }
  
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}
```

### Solution 2 : Ajouter des logs de debug
Dans `report_service.dart`, ajouter :
```dart
debugPrint('to_do_list date_time type: ${toDoList['date_time'].runtimeType}');
debugPrint('to_do_list date_time value: ${toDoList['date_time']}');
```

### Solution 3 : Vérifier la base de données
- Vérifier les valeurs réelles dans `to_do_list.date_time`
- Vérifier comment les dates sont insérées (avec ou sans heure)

## Actions à prendre

1. ✅ **Immédiat** : Ajouter des logs de debug pour voir le format exact des données
2. ✅ **Court terme** : Améliorer le parsing pour gérer tous les cas
3. ✅ **Moyen terme** : Vérifier et corriger les données dans la base de données si nécessaire
4. ✅ **Long terme** : S'assurer que toutes les dates sont insérées avec l'heure correcte
