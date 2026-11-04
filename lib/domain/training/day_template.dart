import '../../models/day_focus.dart';

enum SlotRole { compound, isolation }

/// Vaga de um treino: qual músculo e que tipo de exercício entra nela.
class Slot {
  final String muscle;
  final SlotRole role;
  const Slot(this.muscle, this.role);
}

const _c = SlotRole.compound;
const _i = SlotRole.isolation;

/// Ordem de prioridade: cortes por falta de tempo tiram do fim da lista.
const dayTemplates = <String, List<Slot>>{
  'chest_triceps': [
    Slot('chest', _c),
    Slot('chest', _c),
    Slot('triceps', _c),
    Slot('chest', _i),
    Slot('triceps', _i),
    Slot('chest', _i),
    Slot('triceps', _i),
    Slot('triceps', _i),
    Slot('chest', _i),
  ],
  'back_biceps': [
    Slot('lats', _c),
    Slot('middle back', _c),
    Slot('lats', _c),
    Slot('biceps', _i),
    Slot('middle back', _i),
    Slot('biceps', _i),
    Slot('traps', _i),
    Slot('lower back', _i),
    Slot('forearms', _i),
  ],
  'shoulders_abs': [
    Slot('shoulders', _c),
    Slot('shoulders', _c),
    Slot('abdominals', _i),
    Slot('shoulders', _i),
    Slot('traps', _i),
    Slot('abdominals', _i),
    Slot('shoulders', _i),
    Slot('abdominals', _i),
    Slot('traps', _i),
  ],
  'legs': [
    Slot('quadriceps', _c),
    Slot('hamstrings', _c),
    Slot('glutes', _c),
    Slot('quadriceps', _c),
    Slot('calves', _i),
    Slot('hamstrings', _i),
    Slot('glutes', _i),
    Slot('quadriceps', _i),
    Slot('adductors', _i),
  ],
  'upper': [
    Slot('chest', _c),
    Slot('lats', _c),
    Slot('shoulders', _c),
    Slot('middle back', _c),
    Slot('biceps', _i),
    Slot('triceps', _i),
    Slot('shoulders', _i),
    Slot('chest', _i),
    Slot('abdominals', _i),
  ],
  'full': [
    Slot('quadriceps', _c),
    Slot('chest', _c),
    Slot('lats', _c),
    Slot('hamstrings', _c),
    Slot('shoulders', _c),
    Slot('biceps', _i),
    Slot('triceps', _i),
    Slot('abdominals', _i),
    Slot('calves', _i),
  ],
};

/// Monta a lista de vagas do dia. Músculos em [emphasis] passam na frente e
/// ganham vagas extras (um composto e um isolado) se o modelo não as tiver.
List<Slot> buildSlots(DayFocus focus, Set<String> emphasis) {
  final base = dayTemplates[focus.id] ?? const <Slot>[];
  final chosen = emphasis.where(focus.muscles.contains).toSet();
  if (chosen.isEmpty) return base;

  final boosted = [
    for (final s in base)
      if (chosen.contains(s.muscle)) s,
  ];
  for (final m in chosen) {
    final has = boosted.where((s) => s.muscle == m);
    if (!has.any((s) => s.role == _c)) boosted.add(Slot(m, _c));
    if (!has.any((s) => s.role == _i)) boosted.add(Slot(m, _i));
  }
  final rest = [
    for (final s in base)
      if (!chosen.contains(s.muscle)) s,
  ];
  return [...boosted, ...rest];
}
