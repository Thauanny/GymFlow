import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/equipment/body_groups.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../data/equipment/equipment_gif.dart';
import '../../../data/equipment/equipment_matcher.dart';
import '../../../data/gif_catalog.dart';
import '../../../state/catalog_cubit.dart';
import '../../../state/equipment_cubit.dart';
import '../../widgets/pill.dart';
import '../exercise/exercise_dialog.dart';
import 'alternatives_dialog.dart';
import 'equip_card.dart';

/// Itens de uma categoria (Cardio, Máquinas...) como widgets separados:
/// cabeçalho, rótulos e uma linha por vez. Assim a lista só monta o que está
/// na tela, o que mantém o scroll leve no celular.
List<Widget> equipmentSectionRows({
  required String sectionId,
  required List<EquipItem> items,
  required int cols,
  required ValueChanged<EquipItem> onPicked,
  required bool expanded,
  required VoidCallback onToggle,
  Key? headerKey,
}) {
  final groups = items.map((i) => bodyGroup(i.id)).toSet();
  return [
    _SectionHeader(
      sectionId,
      expanded: expanded,
      onToggle: onToggle,
      key: headerKey,
    ),
    // Fechada, a categoria não monta (nem baixa) os GIFs dos cartões.
    if (expanded)
      for (final g in bodyGroups.entries)
        if (groups.contains(g.key)) ...[
          if (groups.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Pill(g.value.$1, icon: g.value.$2),
              ),
            ),
          for (final row in _chunks([
            for (final i in items)
              if (bodyGroup(i.id) == g.key) i,
          ], cols))
            _CardsRow(items: row, cols: cols, onPicked: onPicked),
        ],
  ];
}

List<List<EquipItem>> _chunks(List<EquipItem> all, int size) => [
  for (var i = 0; i < all.length; i += size)
    all.sublist(i, i + size > all.length ? all.length : i + size),
];

class _SectionHeader extends StatelessWidget {
  final String sectionId;
  final bool expanded;
  final VoidCallback onToggle;
  const _SectionHeader(
    this.sectionId, {
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<EquipmentCubit>().state;
    final cubit = context.read<EquipmentCubit>();
    final all = {
      for (final i in equipItems)
        if (i.section == sectionId) i.id,
    };
    final chosen = all.where(s.equipment.contains).length;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Row(
        children: [
          // Toque no título para abrir/fechar a categoria.
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      // O título quebra de linha se faltar espaço (telas pequenas).
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            sections[sectionId]!.toUpperCase(),
                            style: AppText.display(28),
                          ),
                          Pill(
                            '$chosen/${all.length}',
                            color: chosen == all.length ? p.highlight : p.muted,
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? .5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded, color: p.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            TextButton(
              onPressed: () => cubit.setAll({...s.equipment, ...all}),
              child: const Text('Todos'),
            ),
            TextButton(
              onPressed: () => cubit.setAll(s.equipment.difference(all)),
              child: Text('Nenhum', style: TextStyle(color: p.muted)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uma linha de cartões (colunas de mesma largura).
class _CardsRow extends StatelessWidget {
  final List<EquipItem> items;
  final int cols;
  final ValueChanged<EquipItem> onPicked;
  const _CardsRow({
    required this.items,
    required this.cols,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = context.watch<EquipmentCubit>().state;
    final gifs = context.read<GifCatalog>();
    final catalog = context.read<CatalogCubit>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cols; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: i >= items.length
                  ? const SizedBox.shrink()
                  : _card(context, items[i], s, gifs, catalog, p),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    EquipItem it,
    EquipmentState s,
    GifCatalog gifs,
    CatalogCubit catalog,
    AppPalette p,
  ) {
    return EquipCard(
      item: it,
      gifs: gifsForItem(it, gifs, catalog.state.exercises),
      count: s.counts[it.id] ?? 0,
      selected: s.equipment.contains(it.id),
      tint: p.tints[equipItems.indexOf(it) % p.tints.length],
      onToggle: () => context.read<EquipmentCubit>().toggle(it.id),
      onInfo: () {
        final e = catalog.byId(it.imageId);
        if (e != null) showExercise(context, e);
      },
      onAlternatives: () => showAlternatives(
        context,
        it,
        catalog.byId(it.imageId) ??
            catalog.state.exercises
                .where((x) => itemMatches(it, x))
                .firstOrNull,
        onPicked: onPicked,
      ),
    );
  }
}
