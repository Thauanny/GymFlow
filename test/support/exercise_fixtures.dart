import 'dart:convert';
import 'dart:io';

import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/data/equipment/equipment_matcher.dart';
import 'package:gymflow/models/exercise.dart';

/// Base real de exercícios embutida no app.
List<Exercise> loadExercises() =>
    (jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();

/// Exercícios possíveis com aparelhos de certos tipos (ex.: {'dumbbell'}).
List<Exercise> poolFor(Set<String> kinds) {
  final items = equipItems.where((i) => kinds.contains(i.dbEquip)).toList();
  return loadExercises()
      .where((e) => items.any((i) => itemMatches(i, e)))
      .toList();
}
