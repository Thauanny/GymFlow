import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/exercise.dart';

/// Carrega a base de exercícios embutida no app (funciona offline).
class ExerciseRepository {
  static const asset = 'assets/data/exercises.json';

  Future<List<Exercise>> load() async {
    final body = await rootBundle.loadString(asset);
    return (jsonDecode(body) as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
