import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/translation/pt_names.dart';
import '../../../models/exercise.dart';
import '../../../models/labels.dart';
import '../../../models/plan_item.dart';
import '../../widgets/exercise_thumb.dart';

/// Exercício na ficha: toque nas bolinhas para marcar cada série, ou em
/// "Concluir" para marcar o exercício todo.
class TicketRow extends StatelessWidget {
  final Exercise exercise;
  final PlanItem item;
  final ValueChanged<int> onSetTap;
  final VoidCallback onOpen, onEditLoad, onRest, onToggleDone;

  const TicketRow({
    required this.exercise,
    required this.item,
    required this.onSetTap,
    required this.onOpen,
    required this.onEditLoad,
    required this.onRest,
    required this.onToggleDone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final done = item.done;
    final prescription = exercise.isCardio
        ? '${item.reps} min'
        : '${item.sets}×${item.reps}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? p.softTints[0] : p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: done ? Colors.transparent : p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpen,
            child: Row(
              children: [
                ExerciseThumb(exercise, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseNamePt(exercise.name),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.primary.map(muscleLabel).join(', '),
                        style: TextStyle(fontSize: 12.5, color: p.muted),
                      ),
                    ],
                  ),
                ),
                Text(prescription, style: AppText.display(34)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < item.sets; i++)
                _SetBubble(
                  number: i + 1,
                  done: i < item.setsDone,
                  onTap: () => onSetTap(i),
                ),
              if (!exercise.isCardio) ...[
                const SizedBox(width: 4),
                _MiniButton(
                  icon: Icons.fitness_center_rounded,
                  label: item.kg == null ? 'Carga' : '${_kg(item.kg!)} kg',
                  onTap: onEditLoad,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (!exercise.isCardio) ...[
                Expanded(
                  child: _ActionButton(
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                    label: 'Descanso ${item.restSec}s',
                    background: p.accent,
                    foreground: p.onAccent,
                    onTap: onRest,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _ActionButton(
                  icon: _DoneIcon(done: done, color: done ? p.onVolt : p.text),
                  label: done ? 'Feito' : 'Concluir',
                  background: done ? p.volt : Colors.transparent,
                  foreground: done ? p.onVolt : p.text,
                  border: done ? p.volt : p.border,
                  onTap: onToggleDone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _kg(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
}

class _SetBubble extends StatelessWidget {
  final int number;
  final bool done;
  final VoidCallback onTap;
  const _SetBubble({
    required this.number,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? p.volt : Colors.transparent,
          border: Border.all(color: done ? p.volt : p.border, width: 2),
        ),
        child: done
            ? Icon(Icons.check_rounded, color: p.onVolt)
            : Text('$number', style: AppText.display(22, color: p.muted)),
      ),
    );
  }
}

/// Botão largo e preenchido, bem visível como ação principal da linha.
class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color background, foreground;
  final Color? border;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(14));
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: border == null
              ? null
              : Border.all(color: border!, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: foreground),
              child: icon,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone de check que "estoura" (escala + anel) ao passar de pendente para feito.
class _DoneIcon extends StatefulWidget {
  final bool done;
  final Color color;
  const _DoneIcon({required this.done, required this.color});

  @override
  State<_DoneIcon> createState() => _DoneIconState();
}

class _DoneIconState extends State<_DoneIcon>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );

  @override
  void didUpdateWidget(_DoneIcon old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        return SizedBox.square(
          dimension: 22,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (widget.done && t < 1)
                Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(
                    scale: 1 + t * 1.8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.color, width: 2),
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: widget.done ? Curves.elasticOut.transform(t) : 1,
                child: Icon(
                  widget.done
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 22,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: p.cardAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: p.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
