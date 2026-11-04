import '../domain/training/training_profile.dart';
import '../models/workout.dart';

/// Configuração de um dia: foco e músculos em destaque.
class DaySetting {
  final String focus;
  final Set<String> emphasis;
  const DaySetting(this.focus, [this.emphasis = const {}]);
}

/// Treino gerado ainda não salvo, com o motivo de cada exercício.
class DayDraft {
  final Workout workout;
  final Map<String, String> reasons;
  const DayDraft(this.workout, this.reasons);
}

class PlannerState {
  final TrainingProfile profile;
  final Map<int, DaySetting> settings;
  final Map<int, DayDraft> drafts;

  /// Aparelhos (ids do catálogo) que o usuário não quer usar neste plano.
  final Set<String> avoidedItems;
  final bool useSemantic, busy;
  final double progress;
  final String status;

  const PlannerState({
    this.profile = const TrainingProfile(),
    this.settings = const {},
    this.drafts = const {},
    this.avoidedItems = const {},
    this.useSemantic = false,
    this.busy = false,
    this.progress = 0,
    this.status = '',
  });

  String focusFor(int d) => settings[d]?.focus ?? 'full';
  Set<String> emphasisFor(int d) => settings[d]?.emphasis ?? const {};

  PlannerState copyWith({
    TrainingProfile? profile,
    Map<int, DaySetting>? settings,
    Map<int, DayDraft>? drafts,
    Set<String>? avoidedItems,
    bool? useSemantic,
    bool? busy,
    double? progress,
    String? status,
  }) => PlannerState(
    profile: profile ?? this.profile,
    settings: settings ?? this.settings,
    drafts: drafts ?? this.drafts,
    avoidedItems: avoidedItems ?? this.avoidedItems,
    useSemantic: useSemantic ?? this.useSemantic,
    busy: busy ?? this.busy,
    progress: progress ?? this.progress,
    status: status ?? this.status,
  );
}
