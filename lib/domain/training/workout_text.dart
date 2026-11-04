import '../../models/exercise.dart';
import '../../models/labels.dart';
import '../../models/plan_item.dart';
import '../../models/workout.dart';

const appLink = 'https://thauanny.github.io/GymFlow/';

/// Como achar o exercício e escrever o nome dele (injetado: este arquivo não
/// depende de Flutter nem do catálogo).
typedef ExerciseLookup = Exercise? Function(String id);
typedef NameInPt = String Function(String englishName);

String _kg(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

String _line(
  int? number,
  PlanItem it,
  Exercise e,
  NameInPt pt, {
  required bool stretch,
}) {
  final name = pt(e.name);
  final String what;
  if (stretch) {
    what = '${it.sets}× ${it.reps}s';
  } else if (e.isCardio) {
    what = '${it.reps} min';
  } else {
    final bits = <String>['${it.sets}×${it.reps}'];
    if (it.restSec > 0) bits.add('descanso ${it.restSec}s');
    if (it.kg != null) bits.add('${_kg(it.kg!)} kg');
    what = bits.join(' · ');
  }
  final prefix = number == null ? '•' : '$number.';
  final muscles = e.primary.map(muscleLabel).join(', ');
  final detail = [
    if (muscles.isNotEmpty) muscles,
    equipLabel(e.equipKey),
  ].join(' · ');
  return '$prefix *$name*\n    $what\n    _${detail}_';
}

/// Ficha do treino em texto, pronta para o WhatsApp (*negrito*, _itálico_).
/// Alongamentos vêm antes, como na ficha do app.
///
/// Só usa caracteres comuns (sem emojis): pelo link `wa.me` o WhatsApp mostra
/// "�" no lugar dos emojis, e o texto fica ilegível.
String workoutToText(
  Workout w, {
  required ExerciseLookup byId,
  required NameInPt namePt,
  bool withFooter = true,
}) {
  final b = StringBuffer();
  final day = w.weekday == null ? 'TREINO' : weekdayFull[w.weekday! - 1];
  b.writeln('*${day.toUpperCase()} · ${w.focus.label.toUpperCase()}*');
  final stretchCount = w.stretches.length;
  b.writeln(
    '_${w.items.length} exercícios'
    '${stretchCount == 0 ? '' : ' + $stretchCount alongamentos'}'
    ' · ~${w.estimatedMinutes} min_',
  );

  final stretches = [
    for (final s in w.stretches)
      if (byId(s.exerciseId) case final Exercise e) (s, e),
  ];
  if (stretches.isNotEmpty) {
    b.writeln('\n*ALONGAMENTOS*');
    for (final (s, e) in stretches) {
      b.writeln(_line(null, s, e, namePt, stretch: true));
    }
  }

  final items = [
    for (final i in w.items)
      if (byId(i.exerciseId) case final Exercise e) (i, e),
  ];
  if (items.isNotEmpty) {
    b.writeln('\n*EXERCÍCIOS*');
    for (final (n, (i, e)) in items.indexed) {
      b.writeln(_line(n + 1, i, e, namePt, stretch: false));
    }
  }
  if (withFooter) b.writeln('\n_Montado no GymFlow_ · $appLink');
  return b.toString().trimRight();
}

/// A semana inteira: um bloco por dia, na ordem da semana.
String weekToText(
  List<Workout> workouts, {
  required ExerciseLookup byId,
  required NameInPt namePt,
}) {
  final ordered = [...workouts]
    ..sort((a, b) => (a.weekday ?? 8).compareTo(b.weekday ?? 8));
  final b = StringBuffer('*MINHA SEMANA DE TREINO*\n');
  for (final w in ordered) {
    b.writeln('\n━━━━━━━━━━━━━━━');
    b.writeln(workoutToText(w, byId: byId, namePt: namePt, withFooter: false));
  }
  b.writeln('\n_Montado no GymFlow_ · $appLink');
  return b.toString().trimRight();
}
