import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/responsive.dart';
import '../../../data/alternatives_service.dart';
import '../../../data/equipment/equipment_catalog.dart';
import '../../../state/equipment_cubit.dart';
import '../../../state/nav_cubit.dart';
import '../../widgets/page_body.dart';
import '../../widgets/section_title.dart';
import '../../widgets/toast.dart';
import 'dumbbell_picker.dart';
import 'equipment_section.dart';
import 'muscle_explorer.dart';
import 'presets_bar.dart';
import 'save_bar.dart';

/// Tela "Academia": marque os equipamentos disponíveis.
class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  String _search = '';
  String? _muscle;

  /// Categorias que o usuário inverteu em relação ao padrão (no celular o
  /// padrão é fechada, para não baixar dezenas de GIFs; no desktop, aberta).
  final Set<String> _toggled = {};
  final _sectionKeys = {for (final k in sections.keys) k: GlobalKey()};

  /// Leva o usuário até a categoria do aparelho escolhido.
  void _goTo(EquipItem it) {
    setState(() {
      _search = '';
      // garante que a categoria do aparelho adicionado esteja aberta
      if (!_isOpen(context, it.section)) {
        isPhone(context)
            ? _toggled.add(it.section)
            : _toggled.remove(it.section);
      }
    });
    showToast(
      context,
      '${it.label} adicionado em "${sections[it.section]}". Salve para confirmar.',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _sectionKeys[it.section]?.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Colunas da grade conforme a largura útil da tela.
  int _columns(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final inner =
        (screen < contentMaxWidth ? screen : contentMaxWidth) -
        (screen < 600 ? 32 : 56);
    return inner >= 780 ? 4 : (inner >= 560 ? 3 : 2);
  }

  bool _isOpen(BuildContext context, String section) {
    // buscando ou filtrando por músculo: abre tudo para mostrar o resultado
    if (_search.trim().isNotEmpty || _muscle != null) return true;
    final byDefault = !isPhone(context);
    return _toggled.contains(section) ? !byDefault : byDefault;
  }

  List<EquipItem> _visibleItems(String section) {
    final counts = context.read<EquipmentCubit>().state.counts;
    final q = _search.trim().toLowerCase();
    final byMuscle = _muscle == null
        ? null
        : context.read<AlternativesService>().itemsForMuscle(_muscle!);
    return [
      for (final i in equipItems)
        if (i.section == section &&
            (counts[i.id] ?? 1) > 0 &&
            (byMuscle == null || byMuscle.contains(i.id)) &&
            (q.isEmpty ||
                i.label.toLowerCase().contains(q) ||
                i.desc.toLowerCase().contains(q)))
          i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // reconstrói quando a seleção muda (as seções leem o estado diretamente)
    context.watch<EquipmentCubit>();
    return PageBody(
      title: 'Sua academia',
      subtitle: 'Marque o que existe aí para gerar treinos sob medida.',
      bottom: EquipmentSaveBar(
        onWorkoutSaved: () => context.read<NavCubit>().go(AppTab.workouts),
      ),
      children: [
        const PresetsBar(),
        const DumbbellPicker(),
        const SizedBox(height: 12),
        MuscleExplorer(
          muscle: _muscle,
          onMuscle: (m) => setState(() => _muscle = m),
          onPicked: _goTo,
        ),
        const SectionTitle(
          'Aparelhos',
          hint: 'Toque para marcar o que existe na sua academia.',
        ),
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: const InputDecoration(
            hintText: 'Buscar aparelho (ex.: leg press, polia, halter)',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        for (final sec in sections.keys)
          ...equipmentSectionRows(
            sectionId: sec,
            items: _visibleItems(sec),
            cols: _columns(context),
            onPicked: _goTo,
            headerKey: _sectionKeys[sec],
            expanded: _isOpen(context, sec),
            onToggle: () => setState(
              () => _toggled.contains(sec)
                  ? _toggled.remove(sec)
                  : _toggled.add(sec),
            ),
          ),
      ],
    );
  }
}
