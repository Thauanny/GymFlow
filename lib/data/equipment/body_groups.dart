import 'package:flutter/material.dart' show IconData, Icons;

const bodyGroups = <String, (String, IconData)>{
  'lower': ('Membros inferiores', Icons.directions_walk),
  'upper': ('Membros superiores', Icons.accessibility_new),
  'core': ('Core, corpo todo e cardio', Icons.self_improvement),
};

const _lowerIds = {
  'm_smith',
  'm_calf',
  'm_legpress',
  'm_hack',
  'm_squatm',
  'm_legext',
  'm_legcurl',
  'm_legcurl_seat',
  'm_glute',
  'm_abd',
  'm_add',
  'c_glute',
  'b_rack',
  'b_stiff',
  'b_calf',
  'd_calf',
  'd_hip',
  'd_squat',
  'bw_legs',
};
const _upperIds = {
  'm_chest',
  'm_peck',
  'm_rearfly',
  'm_shoulder',
  'm_row',
  'm_tbar',
  'm_shrug',
  'm_arm',
  'm_tricep',
  'm_pulldown',
  'm_assist',
  'c_chest',
  'c_back',
  'c_shoulder',
  'c_biceps',
  'c_triceps',
  'b_bench',
  'b_row',
  'b_shoulder',
  'b_curl',
  'b_triceps',
  'e-z curl bar',
  'd_curl',
  'd_triceps',
  'd_row',
  'd_chest',
  'd_shoulder',
  'bw_chest',
  'bw_back',
  'bw_arms',
  'o_bar',
};

String bodyGroup(String id) => _lowerIds.contains(id)
    ? 'lower'
    : (_upperIds.contains(id) ? 'upper' : 'core');
