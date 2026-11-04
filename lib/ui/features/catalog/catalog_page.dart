import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/exercise_thumb.dart';
import '../../widgets/page_body.dart';
import '../exercise/exercise_dialog.dart';

const _pageSize = 48;

/// Tela "Explorar": catálogo de exercícios em grade, com busca e filtros.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _query = '';
  String? _muscle;
  bool _onlyMine = true;
  int _shown = _pageSize;

  bool _matches(Exercise e) {
    if (_muscle != null && !e.primary.contains(_muscle)) return false;
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        e.name.toLowerCase().contains(q) ||
        exerciseNamePt(e.name).toLowerCase().contains(q);
  }

  void _reset(VoidCallback change) => setState(() {
    change();
    _shown = _pageSize;
  });

  /// Linhas da grade (colunas conforme a largura útil da tela).
  List<Widget> _rows(BuildContext context, List<Exercise> items) {
    final screen = MediaQuery.sizeOf(context).width;
    final inner =
        (screen < contentMaxWidth ? screen : contentMaxWidth) -
        (screen < 600 ? 32 : 56);
    final cols = inner >= 860 ? 4 : (inner >= 560 ? 3 : 2);
    final width = (inner - (cols - 1) * 12) / cols;
    return [
      for (var i = 0; i < items.length; i += cols)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(
                  child: i + j < items.length
                      ? _Tile(exercise: items[i + j], width: width)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final equipment = context.watch<EquipmentCubit>().state;
    final all = context.read<CatalogCubit>().state.exercises;
    final source = _onlyMine && equipment.available.isNotEmpty
        ? equipment.available
        : all;
    final list = source.where(_matches).toList();
    return PageBody(
      title: 'Explorar',
      subtitle: 'Todos os exercícios, com como fazer e alternativas.',
      children: [
        TextField(
          onChanged: (v) => _reset(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Buscar exercício (PT ou EN)',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                label: const Text('Só meus equipamentos'),
                selected: _onlyMine,
                onSelected: (v) => _reset(() => _onlyMine = v),
              ),
              for (final m in muscleNames.keys)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(muscleLabel(m)),
                    selected: _muscle == m,
                    onSelected: (v) => _reset(() => _muscle = v ? m : null),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${list.length} exercícios',
          style: TextStyle(
            color: context.pal.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // uma linha por item da lista: só as visíveis são montadas
        for (final row in _rows(context, list.take(_shown).toList())) row,
        if (list.length > _shown)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _shown += _pageSize),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('Ver mais (${list.length - _shown})'),
            ),
          ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Nenhum exercício encontrado.')),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final Exercise exercise;
  final double width;
  const _Tile({required this.exercise, required this.width});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final e = exercise;
    return AppCard(
      padding: const EdgeInsets.all(8),
      radius: 22,
      onTap: () => showExercise(context, e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExerciseThumb(e, size: width - 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseNamePt(e.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.primary.map(muscleLabel).join(', ')} · ${itemForExercise(e)?.label ?? equipLabel(e.equipKey)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
