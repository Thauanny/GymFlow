import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/data/equipment/equipment_catalog.dart';
import 'package:gymflow/models/workout.dart';
import 'package:gymflow/state/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// App com academia completa e uma semana (seg, qua, sex) já salva.
  Future<AppDependencies> withPlan() async {
    SharedPreferences.setMockInitialValues({});
    final d = await AppDependencies.create();
    d.equipment.setAll({for (final i in equipItems) i.id});
    d.equipment.save();
    d.planner.setDays({1, 3, 5});
    await d.planner.generateWeek();
    d.planner.commit(replaceDays: true);
    return d;
  }

  Set<String> ids(Iterable<Workout> ws) => {
    for (final w in ws) ...w.items.map((i) => i.exerciseId),
  };

  test(
    'mudar só um dia troca aquele treino e guarda o antigo no histórico',
    () async {
      final d = await withPlan();
      final before = d.workouts.state;
      final monday = before.forWeekday(1).single;
      final wednesdayIds = ids(before.forWeekday(3));

      final change = (await d.planActions.changePlan(onlyDay: 1))!;
      final after = d.workouts.state;

      expect(after.forWeekday(1).single.id, isNot(monday.id));
      expect(after.forWeekday(1).single.day, monday.day); // mantém o foco
      expect(ids(after.forWeekday(3)), wednesdayIds); // outros dias intactos
      expect(after.archive, hasLength(1));
      expect(after.archive.first.workouts.single.id, monday.id);
      expect(change.archiveId, after.archive.first.id);
    },
  );

  test('mudar todos os dias troca a semana inteira', () async {
    final d = await withPlan();
    final oldIds = ids(d.workouts.state.workouts);
    await d.planActions.changePlan();
    final now = d.workouts.state;
    expect(now.workouts, hasLength(3));
    expect(
      ids(now.workouts).intersection(oldIds).length,
      lessThan(oldIds.length),
    );
    expect(now.archive.first.workouts, hasLength(3));
  });

  test('desfazer devolve os treinos e apaga a entrada do histórico', () async {
    final d = await withPlan();
    final originals = d.workouts.state.workouts.map((w) => w.id).toSet();
    final change = (await d.planActions.changePlan())!;
    d.planActions.undo(change);
    expect(d.workouts.state.workouts.map((w) => w.id).toSet(), originals);
    expect(d.workouts.state.archive, isEmpty);
  });

  test(
    'evoluir sobe a carga, mantém o foco e guarda a versão anterior',
    () async {
      final d = await withPlan();
      // simula treinos já feitos com carga de 20 kg no primeiro exercício
      final monday = d.workouts.state.forWeekday(1).single;
      final first = monday.items.first;
      first
        ..kg = 20
        ..done = true;
      d.progress.finish(monday, 45);

      final cycleBefore = d.planActions.cycle;
      final change = (await d.planActions.evolvePlan())!;
      final evolved = d.workouts.state.forWeekday(1).single;

      expect(evolved.day, monday.day);
      expect(
        evolved.items.any(
          (i) => i.exerciseId == first.exerciseId && i.kg == 22,
        ),
        isTrue,
      );
      expect(change.summary, contains('Plano evoluído'));
      expect(d.workouts.state.archive.first.label, contains('evolução'));
      expect(d.planActions.cycle, cycleBefore + 1);
      expect(d.planner.state.profile.minutes, 70); // tempo +10
    },
  );

  test('desfazer uma evolução também volta perfil e ciclo', () async {
    final d = await withPlan();
    final profile = d.planner.state.profile;
    final change = (await d.planActions.evolvePlan())!;
    d.planActions.undo(change);
    expect(d.planner.state.profile.minutes, profile.minutes);
    expect(d.planner.state.profile.level, profile.level);
    expect(d.planActions.cycle, 0);
    expect(d.workouts.state.archive, isEmpty);
  });

  test('a segunda evolução da semana sobe o nível', () async {
    final d = await withPlan();
    expect(d.planner.state.profile.level, 'intermediate');
    await d.planActions.evolvePlan(); // ciclo 0: mantém o nível
    expect(d.planner.state.profile.level, 'intermediate');
    await d.planActions.evolvePlan(); // ciclo 1: sobe
    expect(d.planner.state.profile.level, 'expert');
  });

  test(
    'restaurar um plano do histórico traz de volta e guarda o atual',
    () async {
      final d = await withPlan();
      final originalIds = d.workouts.state.workouts.map((w) => w.id).toSet();
      await d.planActions.changePlan();
      final old = d.workouts.state.archive.first;
      final currentIds = d.workouts.state.workouts.map((w) => w.id).toSet();

      d.workouts.restoreArchived(old);

      expect(d.workouts.state.workouts.map((w) => w.id).toSet(), originalIds);
      expect(d.workouts.state.archive.any((a) => a.id == old.id), isFalse);
      // o plano que estava ativo foi parar no histórico
      expect(
        d.workouts.state.archive.first.workouts.map((w) => w.id).toSet(),
        currentIds,
      );
    },
  );

  test(
    'salvar um plano novo por cima guarda o antigo; excluir não guarda',
    () async {
      final d = await withPlan();
      await d.planner.generateWeek();
      d.planner.commit(replaceDays: true);
      expect(d.workouts.state.archive, isNotEmpty);

      final count = d.workouts.state.archive.length;
      d.workouts.delete(d.workouts.state.workouts.first);
      expect(d.workouts.state.archive, hasLength(count)); // exclusão direta
    },
  );

  test('o histórico sobrevive a fechar e abrir o app', () async {
    final d = await withPlan();
    await d.planActions.changePlan();
    final store = d.store;
    d.workouts.load(); // relê do armazenamento
    expect(d.workouts.state.archive, hasLength(1));
    expect(store.getString('workout_history'), isNotNull);
  });
}
