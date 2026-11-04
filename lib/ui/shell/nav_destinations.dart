import 'package:flutter/material.dart';

import '../../state/nav_cubit.dart';

const navDestinations = <(AppTab, IconData, String)>[
  (AppTab.home, Icons.home_rounded, 'Início'),
  (AppTab.workouts, Icons.event_available_rounded, 'Treinos'),
  (AppTab.equipment, Icons.fitness_center_rounded, 'Academia'),
  (AppTab.explore, Icons.explore_rounded, 'Explorar'),
  (AppTab.progress, Icons.insights_rounded, 'Progresso'),
];
