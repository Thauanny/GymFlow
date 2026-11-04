import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/format.dart';
import '../../../models/history.dart';
import '../../../models/labels.dart';
import '../../../state/progress_cubit.dart';

/// Calendário mensal: dias treinados em lima (dias seguidos ligados por uma
/// faixa), hoje com contorno; toque num dia para ver os treinos dele.
class ConsistencyCalendar extends StatefulWidget {
  final ProgressState progress;
  const ConsistencyCalendar(this.progress, {super.key});

  @override
  State<ConsistencyCalendar> createState() => _ConsistencyCalendarState();
}

class _ConsistencyCalendarState extends State<ConsistencyCalendar> {
  late DateTime _month = _firstOfMonth(DateTime.now());
  DateTime? _selected;

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);
  static int _index(DateTime d) => d.year * 12 + d.month;

  /// Não deixa voltar para antes do primeiro treino registrado.
  bool get _canGoBack {
    final logs = widget.progress.logs;
    if (logs.isEmpty) return false;
    final first = logs
        .map((l) => l.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return _index(_month) > _index(first);
  }

  bool get _canGoForward => _index(_month) < _index(DateTime.now());

  void _go(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    _selected = null;
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = widget.progress;
    final today = dateOnly(DateTime.now());
    final trained = s.trainedDays;
    final blanks = _month.weekday - 1;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final weeks = ((blanks + daysInMonth) / 7).ceil();
    final inMonth = trained
        .where((d) => d.year == _month.year && d.month == _month.month)
        .length;

    DateTime? dateAt(int cell) {
      final day = cell - blanks + 1;
      return day < 1 || day > daysInMonth
          ? null
          : DateTime(_month.year, _month.month, day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONSTÂNCIA', style: AppText.eyebrow(p.muted)),
                  const SizedBox(height: 4),
                  Text(
                    '${monthNames[_month.month - 1]} ${_month.year}'
                        .toUpperCase(),
                    style: AppText.display(32),
                  ),
                ],
              ),
            ),
            _NavButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Mês anterior',
              onPressed: _canGoBack ? () => _go(-1) : null,
            ),
            const SizedBox(width: 6),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Próximo mês',
              onPressed: _canGoForward ? () => _go(1) : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Stat('$inMonth', 'NO MÊS'),
            const SizedBox(width: 8),
            _Stat('${s.streakDays}', 'SEQUÊNCIA'),
            const SizedBox(width: 8),
            _Stat('${s.lastWeekCount}/7', '7 DIAS'),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (final n in weekdayNames)
              Expanded(
                child: Center(
                  child: Text(
                    n.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                      color: p.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var w = 0; w < weeks; w++)
          Row(
            children: [
              for (var c = w * 7; c < w * 7 + 7; c++)
                Expanded(
                  child: switch (dateAt(c)) {
                    null => const SizedBox(height: 44),
                    final d => _DayCell(
                      day: d.day,
                      trained: trained.contains(d),
                      linkPrev:
                          c % 7 > 0 &&
                          d.day > 1 &&
                          trained.contains(d) &&
                          trained.contains(
                            DateTime(d.year, d.month, d.day - 1),
                          ),
                      linkNext:
                          c % 7 < 6 &&
                          d.day < daysInMonth &&
                          trained.contains(d) &&
                          trained.contains(
                            DateTime(d.year, d.month, d.day + 1),
                          ),
                      today: d == today,
                      future: d.isAfter(today),
                      selected: d == _selected,
                      onTap: () =>
                          setState(() => _selected = d == _selected ? null : d),
                    ),
                  },
                ),
            ],
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _selected == null
              ? const SizedBox(width: double.infinity)
              : _DayDetails(_selected!, [
                  for (final l in s.logs)
                    if (dateOnly(l.date) == _selected) l,
                ]),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: p.cardAlt,
        foregroundColor: p.text,
        disabledBackgroundColor: p.cardAlt.withValues(alpha: .5),
        disabledForegroundColor: p.muted.withValues(alpha: .4),
      ),
      icon: Icon(icon),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: p.cardAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: AppText.display(28)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: p.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool trained, linkPrev, linkNext, today, future, selected;
  final VoidCallback onTap;
  const _DayCell({
    required this.day,
    required this.trained,
    required this.linkPrev,
    required this.linkNext,
    required this.today,
    required this.future,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final band = p.volt.withValues(alpha: p.isDark ? .18 : .45);
    final ring = selected
        ? Border.all(color: trained ? p.onVolt : p.highlight, width: 2)
        : today
        ? Border.all(color: p.text, width: 1.8)
        : null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (linkPrev || linkNext)
              Positioned.fill(
                top: 7,
                bottom: 7,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: linkPrev ? band : Colors.transparent,
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: linkNext ? band : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: trained ? p.volt : (selected ? p.cardAlt : null),
                border: ring,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: trained || today
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: trained
                      ? p.onVolt
                      : (future ? p.muted.withValues(alpha: .45) : p.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDetails extends StatelessWidget {
  final DateTime date;
  final List<LogEntry> logs;
  const _DayDetails(this.date, this.logs);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weekdayFull[date.weekday - 1]}, ${date.day} de '
                    '${monthNames[date.month - 1]}'
                .toUpperCase(),
            style: AppText.eyebrow(p.muted),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Nenhum treino neste dia.',
                style: TextStyle(color: p.muted),
              ),
            ),
          for (final l in logs)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: p.volt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 16, color: p.onVolt),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.workoutName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${l.minutes} min',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: p.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
