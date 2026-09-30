import 'package:flutter/material.dart';

import 'equipment.dart';
import 'illustration.dart';
import 'main.dart';
import 'models.dart';
import 'state.dart';
import 'workout.dart';

const _pastels = [mint, lilac, peach, sky, rose];

/// Miniatura do aparelho (mesma imagem da tela de equipamentos).
Widget exerciseThumb(AppState s, Exercise e, double size) {
  final it = itemForExercise(e);
  final gif = it == null ? null : s.itemGif(it.id);
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: size,
      height: size,
      color: Colors.white,
      alignment: Alignment.center,
      child: _media(gif, it?.kind ?? 'body', lilac, size),
    ),
  );
}

OverlayEntry? _toast;

/// Aviso discreto no topo da tela (não cobre botões e não intercepta cliques).
void showToast(BuildContext context, String message, {bool error = false}) {
  _toast?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      error: error,
      onDone: () {
        if (_toast == entry) _toast = null;
        entry.remove();
      },
    ),
  );
  _toast = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  final String message;
  final bool error;
  final VoidCallback onDone;
  const _Toast({
    required this.message,
    required this.error,
    required this.onDone,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    c.forward();
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      await c.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.error
        ? const Color(0xFFC0504D)
        : const Color(0xFF7E6BB0);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: c,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, -.6),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
                child: Container(
                  margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: .5)),
                    boxShadow: [
                      BoxShadow(
                        color: ink.withValues(alpha: .12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.error
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ink,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _title(String t, [String? sub]) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        t,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      if (sub != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(sub, style: TextStyle(color: ink.withValues(alpha: .6))),
        ),
    ],
  ),
);

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Cartão de seção com cabeçalho numerado, usado para dividir fluxos em etapas.
Widget _panel(String title, Widget child, {int? step, String? hint}) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
  child: Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ink.withValues(alpha: .06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (step != null)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  color: lilac,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hint,
              style: TextStyle(fontSize: 13, color: ink.withValues(alpha: .6)),
            ),
          ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  ),
);

/// Aviso de ação necessária com botão para resolver.
Widget _notice(String text, String action, VoidCallback onTap) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: peach.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: ink),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
        const SizedBox(width: 12),
        FilledButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  ),
);

// ---------------------------------------------------------------- Exercício

/// Resolve o GIF instrutivo de um exercício (definido pelo Shell).
String? Function(Exercise) gifLookup = (_) => null;
List<Alt> Function(Exercise) altLookup = (_) => [];
Exercise Function(Alt) altExercise = (a) => throw UnimplementedError();

/// Barra com botão X para fechar modais (facilita o uso no celular).
Widget _closeBar(BuildContext ctx, {Widget? leading}) => Row(
  children: [
    Expanded(child: leading ?? const SizedBox.shrink()),
    IconButton.filledTonal(
      tooltip: 'Fechar',
      onPressed: () => Navigator.of(ctx).pop(),
      icon: const Icon(Icons.close),
    ),
  ],
);

/// GIF animado via elemento <img> do navegador (anima e funciona com CDN sem CORS).
class GifView extends StatelessWidget {
  final String url;
  final double height;
  final Widget? fallback;
  const GifView(this.url, {this.height = 160, this.fallback, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.white,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (_, child, p) => p == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (_, _, _) =>
            fallback ??
            const Center(child: Icon(Icons.image_not_supported_outlined)),
      ),
    );
  }
}

/// Alternativas (outros aparelhos/equipamentos) para o exercício principal de um aparelho.
void showAlternatives(
  BuildContext context,
  EquipItem item,
  Exercise? e,
  AppState state, {
  void Function(EquipItem)? onPicked,
}) {
  final alts = e == null ? <Alt>[] : state.alternativesFor(e, max: 12);
  final title = item.label;
  showDialog(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _closeBar(dialogCtx),
              Text(
                'Sem $title? Faça de outra forma',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Variações do mesmo movimento com outros equipamentos. '
                'As do seu equipamento salvo aparecem primeiro.',
                style: TextStyle(
                  fontSize: 13,
                  color: ink.withValues(alpha: .65),
                ),
              ),
              const SizedBox(height: 14),
              if (alts.isEmpty)
                const Text('Ainda não há variações para este aparelho.')
              else
                LayoutBuilder(
                  builder: (_, c) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final a in alts)
                        _AltCard(
                          a,
                          state: state,
                          original: item,
                          onPicked: onPicked,
                          width: _altWidth(c.maxWidth),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Largura dos cards de alternativa: 2 colunas no celular, mais em telas largas.
double _altWidth(double maxW) {
  final cols = maxW >= 700 ? 4 : (maxW >= 480 ? 3 : 2);
  return (maxW - (cols - 1) * 10) / cols;
}

class _AltCard extends StatelessWidget {
  final Alt a;
  final AppState state;
  final EquipItem? original;
  final void Function(EquipItem)? onPicked;
  final bool inDialog;
  final double width;
  const _AltCard(
    this.a, {
    required this.state,
    this.original,
    this.onPicked,
    this.inDialog = true,
    this.width = 170,
  });

  @override
  Widget build(BuildContext context) {
    final target = itemForAlt(a.name, a.equip);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final chosen = target != null && state.equipment.contains(target.id);
        final replace =
            original != null &&
            state.equipment.contains(original!.id) &&
            target?.id != original!.id;
        return Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: chosen || a.have
                  ? const Color(0xFF7E6BB0)
                  : ink.withValues(alpha: .1),
              width: chosen || a.have ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => showExercise(context, altExercise(a)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GifView(a.gif, height: 120),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                      child: Text(
                        a.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                      child: Text(
                        target == null ? equipLabel(a.equip) : target.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              if (target != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: chosen
                        ? FilledButton.icon(
                            onPressed: null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text(
                              'Selecionado',
                              style: TextStyle(fontSize: 13),
                            ),
                          )
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                            onPressed: () {
                              state.swapEquipment(
                                replace ? original!.id : null,
                                target.id,
                              );
                              if (inDialog) Navigator.of(context).pop();
                              onPicked?.call(target);
                            },
                            child: Text(
                              replace ? 'Usar no lugar' : 'Adicionar',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Visualização do exercício: GIF animado (padrão) ou fotos de pessoas executando.
class _ExerciseMedia extends StatefulWidget {
  final Exercise e;
  final String? gif;
  const _ExerciseMedia(this.e, this.gif);

  @override
  State<_ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<_ExerciseMedia> {
  bool photos = false;

  @override
  Widget build(BuildContext context) {
    final hasGif = widget.gif != null;
    final hasPhotos = widget.e.images.isNotEmpty;
    if (!hasGif && !hasPhotos) return const SizedBox.shrink();
    final showPhotos = hasPhotos && (!hasGif || photos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasGif && hasPhotos) ...[
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.animation),
                label: Text('GIF animado'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.person),
                label: Text('GIF pessoa'),
              ),
            ],
            selected: {photos},
            onSelectionChanged: (s) => setState(() => photos = s.first),
          ),
          const SizedBox(height: 10),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: showPhotos
              ? AnimatedFrames(widget.e.id, height: 280)
              : GifView(widget.gif!, height: 280),
        ),
      ],
    );
  }
}

void showExercise(BuildContext context, Exercise e) {
  final gif = gifLookup(e);
  final alts = altLookup(e);
  showDialog(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _closeBar(dialogCtx),
              const SizedBox(height: 4),
              _ExerciseMedia(e, gif),
              const SizedBox(height: 12),
              Text(
                e.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                    label: Text(equipLabel(e.equipKey)),
                    backgroundColor: sky,
                  ),
                  Chip(
                    label: Text(levelNames[e.level] ?? e.level),
                    backgroundColor: peach,
                  ),
                  for (final m in e.primary)
                    Chip(label: Text(muscleLabel(m)), backgroundColor: mint),
                  for (final m in e.secondary)
                    Chip(label: Text(muscleLabel(m)), backgroundColor: rose),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < e.instructions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${i + 1}. ${e.instructions[i]}'),
                ),
              if (alts.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Sem esse aparelho? Faça de outra forma',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Variações para o mesmo músculo; as do seu equipamento salvo vêm primeiro.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ink.withValues(alpha: .6),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: alts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final a = alts[i];
                      return GestureDetector(
                        onTap: () => showExercise(context, altExercise(a)),
                        child: Container(
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: a.have
                                  ? const Color(0xFF7E6BB0)
                                  : ink.withValues(alpha: .1),
                              width: a.have ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GifView(a.gif, height: 110),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                                child: Text(
                                  a.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    Text(
                                      equipLabel(a.equip),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    if (a.have)
                                      const Text(
                                        '· você tem',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF7E6BB0),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class ExerciseTile extends StatelessWidget {
  final Exercise e;
  final Widget? trailing;
  const ExerciseTile(this.e, {this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => showExercise(context, e),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 52,
            height: 52,
            child: e.imageUrl == null
                ? Container(
                    color: lilac,
                    child: const Icon(Icons.fitness_center),
                  )
                : Image.network(
                    e.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: lilac,
                      child: const Icon(Icons.fitness_center),
                    ),
                  ),
          ),
        ),
        title: Text(
          e.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${e.primary.map(muscleLabel).join(', ')} • ${equipLabel(e.equipKey)}',
        ),
        trailing: trailing,
      ),
    );
  }
}

// -------------------------------------------------------------------- Início

class HomePage extends StatelessWidget {
  final AppState state;
  final void Function(int) go;
  const HomePage({required this.state, required this.go, super.key});

  @override
  Widget build(BuildContext context) {
    final totalMin = state.logs.fold<int>(0, (a, b) => a + b.minutes);
    final weight = state.weights.isEmpty ? '--' : '${state.weights.last.kg} kg';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
        ? 'Boa tarde'
        : 'Boa noite';
    final today = DateTime.now();
    final week = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    bool trained(DateTime d) => state.logs.any(
      (l) =>
          l.date.year == d.year &&
          l.date.month == d.month &&
          l.date.day == d.day,
    );
    const dayNames = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    Widget stat(String label, String value, IconData icon, Color c) => Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ink),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            Text(label, style: const TextStyle(color: ink)),
          ],
        ),
      ),
    );
    return ListView(
      children: [
        _title('$greeting!', 'Resumo da sua rotina de treino.'),
        if (state.savedEquipment.isEmpty)
          _notice(
            'Comece escolhendo os equipamentos da sua academia.',
            'Escolher',
            () => go(1),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  stat(
                    'Treinos',
                    '${state.logs.length}',
                    Icons.check_circle_outline,
                    mint,
                  ),
                  stat(
                    'Sequência',
                    '${state.streakDays} d',
                    Icons.local_fire_department_outlined,
                    peach,
                  ),
                ],
              ),
              Row(
                children: [
                  stat('Minutos', '$totalMin', Icons.timer_outlined, sky),
                  stat('Peso', weight, Icons.monitor_weight_outlined, rose),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _panel(
          'Últimos 7 dias',
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final d in week)
                Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: trained(d) ? mint : cream,
                      child: trained(d)
                          ? const Icon(Icons.check, size: 16, color: ink)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayNames[d.weekday - 1],
                      style: TextStyle(
                        fontSize: 12,
                        color: ink.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        _panel(
          'Treino com IA',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.equipment.length} aparelho(s) selecionado(s) • ${state.available.length} exercícios disponíveis',
                style: TextStyle(color: ink.withValues(alpha: .7)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: state.available.isEmpty ? null : () => go(2),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Gerar treino'),
                  ),
                  OutlinedButton(
                    onPressed: () => go(1),
                    child: const Text('Editar equipamentos'),
                  ),
                ],
              ),
            ],
          ),
        ),
        _title('Últimos treinos'),
        if (state.logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Nenhum treino registrado ainda.'),
          ),
        for (final l in state.logs.take(5))
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: mint,
                child: Icon(Icons.check, color: ink),
              ),
              title: Text(l.workoutName),
              subtitle: Text(
                '${_fmt(l.date)} • ${l.exercises} exercícios • ${l.minutes} min',
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ------------------------------------------------------------- Equipamentos

/// Alterna os 2 quadros do exercício (efeito de GIF) para mostrar o movimento.
class AnimatedFrames extends StatefulWidget {
  final String imageId;
  final double? height;
  const AnimatedFrames(this.imageId, {this.height, super.key});

  @override
  State<AnimatedFrames> createState() => _AnimatedFramesState();
}

class _AnimatedFramesState extends State<AnimatedFrames> {
  int frame = 0;
  bool alive = true;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (alive) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!alive) return;
      setState(() => frame = 1 - frame);
    }
  }

  @override
  void dispose() {
    alive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final f in [0, 1])
            Opacity(
              opacity: frame == f ? 1 : 0,
              child: Image.network(
                frameUrl(widget.imageId, f),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: lilac,
                  child: const Icon(Icons.fitness_center),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EquipmentPage extends StatefulWidget {
  final AppState state;
  final void Function(int) go;
  const EquipmentPage({required this.state, required this.go, super.key});

  static const presets = {
    'Academia completa': null,
    'Treino em casa': {
      'body only',
      'bands',
      'dumbbell',
      'kettlebells',
      'exercise ball',
    },
    'Só peso corporal': {'body only'},
  };

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  String search = '';
  String? muscle;
  int muscleShown = 24;
  final _secKeys = {for (final k in sections.keys) k: GlobalKey()};

  /// Leva o usuário até a categoria do aparelho escolhido.
  void _goTo(EquipItem it) {
    setState(() => search = '');
    showToast(
      context,
      '${it.label} adicionado em "${sections[it.section]}". Salve para confirmar.',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _secKeys[it.section]?.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _grid(List<Widget Function(double)> builders) => LayoutBuilder(
    builder: (_, cons) {
      final cols = cons.maxWidth >= 780 ? 4 : (cons.maxWidth >= 560 ? 3 : 2);
      final w = (cons.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final b in builders) b(w)],
      );
    },
  );

  Widget _stepper() {
    final s = widget.state;
    final done = [
      s.openSections.isNotEmpty,
      s.equipment.isNotEmpty,
      s.savedEquipment.isNotEmpty && !s.dirty,
      false,
    ];
    final cur = done.indexOf(false);
    const steps = [
      ('Categorias', 'Tipos de aparelho'),
      ('Aparelhos', 'Marque os que existem'),
      ('Salvar', 'Confirme a seleção'),
      ('Treino com IA', 'Gere seu treino'),
    ];
    const purple = Color(0xFF7E6BB0);
    final canGo = done[2] && s.available.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ink.withValues(alpha: .08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: i == 3 && canGo ? () => widget.go(2) : null,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i == 0
                                ? Colors.transparent
                                : (done[i - 1] ? purple : lilac),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done[i] || i == cur ? purple : Colors.white,
                            border: Border.all(
                              color: i == cur
                                  ? lilac
                                  : (done[i] ? purple : lilac),
                              width: i == cur ? 5 : 2,
                            ),
                          ),
                          child: done[i]
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: i == cur
                                        ? Colors.white
                                        : ink.withValues(alpha: .5),
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Container(
                            height: 3,
                            color: i == steps.length - 1
                                ? Colors.transparent
                                : (done[i] ? purple : lilac),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[i].$1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: i == cur
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: done[i] || i == cur
                            ? ink
                            : ink.withValues(alpha: .5),
                      ),
                    ),
                    Text(
                      steps[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: ink.withValues(alpha: .55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(int n, String title, String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: const Color(0xFF7E6BB0),
          child: Text(
            '$n',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: ink.withValues(alpha: .6),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final counts = state.equipmentCounts;
    final open = state.openSections;
    final cats = sections.keys.toList();
    final anyOpen = open.isNotEmpty;
    final q = search.trim().toLowerCase();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _title(
                'Equipamentos da academia',
                'Defina o que está disponível para gerar treinos sob medida.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _stepper(),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ink.withValues(alpha: .06)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Atalho rápido:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ink.withValues(alpha: .7),
                        ),
                      ),
                      for (final p in EquipmentPage.presets.entries)
                        ActionChip(
                          avatar: const Icon(Icons.bolt, size: 16),
                          label: Text(p.key),
                          onPressed: () => state.setEquipment(
                            p.value == null
                                ? equipItems.map((e) => e.id).toSet()
                                : {
                                    for (final id in p.value!)
                                      if (id == 'dumbbell')
                                        ...equipItems
                                            .where(
                                              (e) => e.dbEquip == 'dumbbell',
                                            )
                                            .map((e) => e.id)
                                      else
                                        id,
                                  },
                          ),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpar'),
                        onPressed: () {
                          state.openSections = {};
                          state.setEquipment({});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _panel(
                  'Filtrar por músculo',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final m in muscleNames.entries)
                              if (m.key != 'neck')
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(m.value),
                                    selected: muscle == m.key,
                                    selectedColor: lilac,
                                    visualDensity: VisualDensity.comfortable,
                                    onSelected: (s) => setState(() {
                                      muscle = s ? m.key : null;
                                      muscleShown = 24;
                                    }),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      if (muscle != null)
                        Builder(
                          builder: (_) {
                            final alts = state.altsForMuscle(muscle!);
                            final shown = alts.take(muscleShown).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 14),
                                Text(
                                  '${alts.length} exercícios para ${muscleLabel(muscle!)} em todos os equipamentos',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (alts.isEmpty)
                                  const Text('Nenhum exercício encontrado.')
                                else
                                  LayoutBuilder(
                                    builder: (_, c) => Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        for (final a in shown)
                                          _AltCard(
                                            a,
                                            state: state,
                                            inDialog: false,
                                            onPicked: _goTo,
                                            width: _altWidth(c.maxWidth),
                                          ),
                                      ],
                                    ),
                                  ),
                                if (alts.length > shown.length)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                      ),
                                      onPressed: () =>
                                          setState(() => muscleShown += 24),
                                      icon: const Icon(Icons.expand_more),
                                      label: Text(
                                        'Ver mais (${alts.length - shown.length})',
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                  hint:
                      'Veja todas as alternativas para o músculo, em qualquer aparelho.',
                ),
              ),
              _sectionHeader(
                1,
                'Escolha as categorias',
                'Toque nas categorias que existem na sua academia.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _grid([
                  for (var i = 0; i < cats.length; i++)
                    (w) {
                      final c = cats[i];
                      final total = equipItems
                          .where((x) => x.section == c)
                          .length;
                      final sel = equipItems
                          .where(
                            (x) =>
                                x.section == c &&
                                state.equipment.contains(x.id),
                          )
                          .length;
                      return _CategoryCard(
                        width: w,
                        label: sections[c]!,
                        desc: '$sel de $total selecionados',
                        gif: null,
                        kind: sectionKinds[c]!,
                        color: _pastels[i % _pastels.length],
                        selected: open.contains(c),
                        onTap: () => state.toggleSection(c),
                      );
                    },
                ]),
              ),
              if (anyOpen) ...[
                _sectionHeader(
                  2,
                  'Marque os aparelhos',
                  'Depois toque em "Salvar equipamentos" l\u00e1 embaixo.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setState(() => search = v),
                    decoration: const InputDecoration(
                      hintText:
                          'Buscar aparelho (ex.: leg press, polia, halter)',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ],
              for (final sec in sections.entries)
                if (open.contains(sec.key) || muscle != null)
                  Builder(
                    builder: (_) {
                      final mIds = muscle == null
                          ? null
                          : state.itemsForMuscle(muscle!);
                      final items = equipItems
                          .where(
                            (i) =>
                                i.section == sec.key &&
                                (mIds == null || mIds.contains(i.id)) &&
                                (q.isEmpty ||
                                    i.label.toLowerCase().contains(q) ||
                                    i.desc.toLowerCase().contains(q)),
                          )
                          .toList();
                      if (items.isEmpty) return const SizedBox.shrink();
                      final all = equipItems
                          .where((i) => i.section == sec.key)
                          .map((i) => i.id)
                          .toSet();
                      final chosen = all.where(state.equipment.contains).length;
                      return Column(
                        key: _secKeys[sec.key],
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${sec.value}  ·  $chosen/${all.length}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => state.setEquipment({
                                    ...state.equipment,
                                    ...all,
                                  }),
                                  child: const Text('Todos'),
                                ),
                                TextButton(
                                  onPressed: () => state.setEquipment(
                                    state.equipment.difference(all)
                                      ..removeAll({}),
                                  ),
                                  child: const Text('Nenhum'),
                                ),
                              ],
                            ),
                          ),
                          for (final g in bodyGroups.entries)
                            if (items.any((i) => bodyGroup(i.id) == g.key)) ...[
                              if (items
                                      .map((i) => bodyGroup(i.id))
                                      .toSet()
                                      .length >
                                  1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    8,
                                  ),
                                  child: Chip(
                                    avatar: Icon(g.value.$2, size: 16),
                                    label: Text(
                                      g.value.$1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    backgroundColor: lilac,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _grid([
                                  for (final it in items.where(
                                    (i) => bodyGroup(i.id) == g.key,
                                  ))
                                    (w) => _EquipCard(
                                      width: w,
                                      item: it,
                                      gif: state.itemGif(it.id),
                                      count: counts[it.id] ?? 0,
                                      selected: state.equipment.contains(it.id),
                                      color:
                                          _pastels[equipItems.indexOf(it) %
                                              _pastels.length],
                                      onTap: () => state.toggleEquipment(it.id),
                                      onInfo: () {
                                        final e = state.byId(it.imageId);
                                        if (e != null) showExercise(context, e);
                                      },
                                      onAlt: () {
                                        final e =
                                            state.byId(it.imageId) ??
                                            state.exercises
                                                .where(
                                                  (x) => itemMatches(it, x),
                                                )
                                                .firstOrNull;
                                        showAlternatives(
                                          context,
                                          it,
                                          e,
                                          state,
                                          onPicked: _goTo,
                                        );
                                      },
                                    ),
                                ]),
                              ),
                            ],
                        ],
                      );
                    },
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: ink.withValues(alpha: .08))),
          ),
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.dirty
                              ? Icons.pending_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                          color: state.dirty
                              ? const Color(0xFFB5651D)
                              : const Color(0xFF7E6BB0),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.dirty
                                ? '${state.equipment.length} aparelho(s) \u2022 ${state.draftAvailable.length} exerc\u00edcios \u2022 altera\u00e7\u00f5es n\u00e3o salvas'
                                : '${state.available.length} exerc\u00edcios dispon\u00edveis \u2022 equipamentos salvos',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: state.dirty
                                  ? const Color(0xFFB5651D)
                                  : ink.withValues(alpha: .7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (state.dirty)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          state.saveEquipment();
                          showToast(context, 'Equipamentos salvos.');
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar equipamentos'),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: state.available.isEmpty
                                  ? null
                                  : () async {
                                      final saved = await showWorkoutEditor(
                                        context,
                                        state,
                                      );
                                      if (saved != null) widget.go(3);
                                    },
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Montar manual'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: state.available.isEmpty
                                  ? null
                                  : () => widget.go(2),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Gerar com IA'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Miniatura: GIF instrutivo quando existir; caso contrário, ilustração.
Widget _media(String? gif, String kind, Color color, double height) =>
    gif == null
    ? Illustration(kind, color: color, height: height)
    : GifView(
        gif,
        height: height,
        fallback: Illustration(kind, color: color, height: height),
      );

class _CategoryCard extends StatelessWidget {
  final String label, desc, kind;
  final String? gif;
  final Color color;
  final bool selected;
  final double width;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.label,
    required this.desc,
    required this.kind,
    required this.gif,
    required this.color,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? ink.withValues(alpha: .5) : color,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _media(gif, kind, color, 130),
                  if (selected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.check, size: 16),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 76,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: ink.withValues(alpha: .7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipCard extends StatelessWidget {
  final EquipItem item;
  final String? gif;
  final int count;
  final bool selected;
  final Color color;
  final double width;
  final VoidCallback onTap, onInfo, onAlt;
  const _EquipCard({
    required this.item,
    required this.gif,
    required this.count,
    required this.selected,
    required this.color,
    required this.width,
    required this.onTap,
    required this.onInfo,
    required this.onAlt,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF7E6BB0)
                : ink.withValues(alpha: .1),
            width: selected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onInfo,
              child: Stack(
                children: [
                  _media(gif, item.kind, color, 140),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withValues(alpha: .9),
                      child: const Icon(Icons.zoom_in, size: 18, color: ink),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: SizedBox(
                height: 116,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: ink.withValues(alpha: .7),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count exercícios',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: selected
                    ? FilledButton.icon(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Selecionado'),
                      )
                    : OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Adicionar'),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onAlt,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: ink.withValues(alpha: .05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text(
                    'Ver alternativas',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------- IA

class AiPage extends StatefulWidget {
  final AppState state;
  final void Function(int) go;
  const AiPage({required this.state, required this.go, super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final goal = TextEditingController();
  final muscles = <String>{};
  String level = 'intermediate';
  String objective = 'hipertrofia';
  double count = 6;
  bool busy = false;
  double progress = 0;
  String status = '';
  int weekday = 1;
  String dayType = 'upper1';

  static const objectives = {
    'hipertrofia': (3, 10),
    'força': (4, 6),
    'resistência': (3, 15),
  };

  @override
  void dispose() {
    goal.dispose();
    super.dispose();
  }

  Future<void> generate() async {
    final s = widget.state;
    setState(() {
      busy = true;
      progress = 0;
      status = 'Carregando modelo de IA no navegador (só na 1ª vez)...';
    });
    final ok = await s.ranker.init();
    if (!mounted) return;
    setState(
      () => status = ok
          ? 'Analisando exercícios com IA...'
          : 'Modelo indisponível, usando busca por palavras-chave.',
    );

    const order = ['beginner', 'intermediate', 'expert'];
    final maxLevel = order.indexOf(level);
    var pool = s.available
        .where((e) => order.indexOf(e.level) <= maxLevel)
        .toList();
    pool = pool.where((e) {
      if (dayType == 'cardio') return e.category == 'cardio';
      if (e.category == 'stretching' || e.category == 'cardio') return false;
      if (dayType == 'mixed') return true;
      return guessDay([e]).startsWith(dayType.substring(0, 5));
    }).toList();
    if (muscles.isNotEmpty) {
      pool = pool.where((e) => e.primary.any(muscles.contains)).toList();
    }
    final query = '${goal.text} ${muscles.join(' ')} $objective';
    final ranked = await s.ranker.rank(
      query,
      pool,
      onProgress: (p) {
        if (mounted) setState(() => progress = p);
      },
    );

    final n = count.round();
    final perMuscle = muscles.isEmpty
        ? (n / 3).ceil()
        : (n / muscles.length).ceil();
    final otherDays = {
      for (final d in s.drafts.entries)
        if (d.key != weekday) ...d.value.items.map((i) => i.exerciseId),
    };
    String itemKey(Exercise e) => itemForExercise(e)?.id ?? e.id;
    final picked = <Exercise>[];
    // Passo 0: sem repetir aparelho nem exercícios de outros dias.
    // Passo 1: permite repetir de outros dias. Passo 2: permite repetir aparelho.
    for (var pass = 0; pass < 3 && picked.length < n; pass++) {
      final used = <String, int>{};
      for (final e in picked) {
        final m = e.primary.isEmpty ? '-' : e.primary.first;
        used[m] = (used[m] ?? 0) + 1;
      }
      final keys = {for (final e in picked) itemKey(e)};
      for (final e in ranked) {
        if (picked.contains(e)) continue;
        if (pass == 0 && otherDays.contains(e.id)) continue;
        if (pass < 2 && keys.contains(itemKey(e))) continue;
        final m = e.primary.isEmpty ? '-' : e.primary.first;
        if ((used[m] ?? 0) >= perMuscle) continue;
        used[m] = (used[m] ?? 0) + 1;
        keys.add(itemKey(e));
        picked.add(e);
        if (picked.length >= n) break;
      }
    }
    if (!mounted) return;
    final w = Workout(
      DateTime.now().microsecondsSinceEpoch.toString(),
      '$_base - ${weekdayNames[weekday - 1]}',
      _plan(picked),
      day: dayType,
      weekday: weekday,
    );
    s.setDraft(w);
    setState(() {
      _saved.remove(weekday);
      busy = false;
      status = ok
          ? 'Sugestão gerada por IA local'
          : 'Sugestão gerada (modo simples)';
    });
  }

  List<String> _musclesFor(String t) {
    const upper = [
      'chest',
      'shoulders',
      'lats',
      'middle back',
      'traps',
      'biceps',
      'triceps',
      'forearms',
      'abdominals',
    ];
    const lower = [
      'quadriceps',
      'hamstrings',
      'glutes',
      'calves',
      'abductors',
      'adductors',
      'lower back',
    ];
    return switch (t) {
      'upper1' => upper,
      'lower1' => lower,
      'cardio' => const [],
      _ => [...upper, ...lower],
    };
  }

  List<PlanItem> _plan(List<Exercise> es) {
    final (sets, reps) = objectives[objective]!;
    return [
      for (final e in es)
        e.category == 'cardio'
            ? PlanItem(e.id, 1, 20)
            : PlanItem(e.id, sets, reps),
    ];
  }

  String get _base => goal.text.trim().isEmpty ? 'Treino IA' : goal.text.trim();

  void _pick(int d) {
    weekday = d;
    dayType = widget.state.suggestType(d);
    muscles.removeWhere((m) => !_musclesFor(dayType).contains(m));
  }

  @override
  void initState() {
    super.initState();
    final s = widget.state;
    final w = s.aiWeekday;
    s.aiWeekday = null;
    if (w != null && s.trainDays.contains(w)) {
      _pick(w);
    } else if (s.sortedDays.isNotEmpty) {
      _pick(s.missingDays.firstOrNull ?? s.sortedDays.first);
    }
  }

  final Set<int> _saved = {};

  void _saveDay(int d) {
    final s = widget.state;
    setState(() {
      _saved.add(d);
      final next = s.missingDays;
      if (next.isNotEmpty) _pick(next.first);
    });
    final left = s.missingDays;
    showToast(
      context,
      left.isEmpty
          ? '${weekdayFull[d - 1]} salvo. Todos os dias prontos!'
          : '${weekdayFull[d - 1]} salvo. Agora gere: ${weekdayFull[left.first - 1]}',
    );
  }

  void saveWeek() {
    final n = widget.state.drafts.length;
    widget.state.commitDrafts();
    showToast(context, '$n treino(s) salvo(s) por dia da semana');
    widget.go(3);
  }

  List<Widget> _plansView(AppState s) {
    if (busy || s.drafts.isEmpty) return [];
    final days = s.drafts.keys.toList()..sort();
    final missing = s.missingDays;
    return [
      _title(
        'Sua semana',
        '${days.length} de ${s.trainDays.length} dia(s) prontos. O treino s\u00f3 vai para "Treinos" quando todos os dias estiverem prontos.',
      ),
      for (final d in days) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Icon(
                dayTypes[s.drafts[d]!.day]!.$2,
                color: const Color(0xFF7E6BB0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${weekdayFull[d - 1]} \u2022 ${dayTypes[s.drafts[d]!.day]!.$1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar dia',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showWorkoutEditor(
                  context,
                  s,
                  existing: s.drafts[d],
                  draft: true,
                  exercisesOnly: true,
                ),
              ),
              IconButton(
                tooltip: 'Remover dia',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() {
                  s.removeDraft(d);
                  _saved.remove(d);
                  _pick(d);
                }),
              ),
            ],
          ),
        ),
        for (final it in s.drafts[d]!.items)
          if (s.byId(it.exerciseId) case final e?)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                onTap: () => showExercise(context, e),
                leading: exerciseThumb(s, e, 52),
                title: Text(
                  exerciseNamePt(e.name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${e.primary.map(muscleLabel).join(', ')} • ${itemForExercise(e)?.label ?? equipLabel(e.equipKey)}',
                ),
                trailing: Text(
                  e.category == 'cardio'
                      ? '${it.reps} min'
                      : '${it.sets}\u00d7${it.reps}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: _saved.contains(d)
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle),
                  label: Text('${weekdayFull[d - 1]} salvo'),
                )
              : FilledButton.tonalIcon(
                  onPressed: () => _saveDay(d),
                  icon: const Icon(Icons.check),
                  label: Text('Salvar treino de ${weekdayFull[d - 1]}'),
                ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Faltam: ${missing.map((d) => weekdayFull[d - 1]).join(', ')}',
                  style: TextStyle(color: ink.withValues(alpha: .7)),
                ),
              ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: missing.isEmpty ? saveWeek : null,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Salvar semana em Treinos'),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ListView(
      children: [
        _title(
          'Gerar treino com IA',
          'Passo 2: descreva o objetivo. O modelo roda no seu navegador e usa a base free-exercise-db.',
        ),
        if (s.savedEquipment.isEmpty)
          _notice(
            'Nenhum equipamento selecionado.',
            'Escolher',
            () => widget.go(1),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.savedEquipment.length} aparelho(s) \u2022 ${s.available.length} exerc\u00edcios dispon\u00edveis',
                  style: TextStyle(color: ink.withValues(alpha: .6)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final it in equipItems)
                      if (s.savedEquipment.contains(it.id))
                        InputChip(
                          label: Text(
                            it.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () {
                            s.toggleEquipment(it.id);
                            s.saveEquipment();
                          },
                        ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => widget.go(1),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar equipamentos'),
                ),
              ],
            ),
          ),
        IgnorePointer(
          ignoring: s.savedEquipment.isEmpty,
          child: Opacity(
            opacity: s.savedEquipment.isEmpty ? .4 : 1,
            child: Column(
              children: [
                _panel(
                  'Qual \u00e9 o seu objetivo?',
                  TextField(
                    controller: goal,
                    decoration: const InputDecoration(
                      hintText:
                          'Ex.: fortalecer costas e ombros, gl\u00fateos, emagrecer...',
                      prefixIcon: Icon(Icons.auto_awesome),
                    ),
                  ),
                  step: 1,
                  hint:
                      'Opcional. Escreva livremente, a IA interpreta o significado.',
                ),
                _panel(
                  'Dias de treino',
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          label: Text(weekdayNames[d - 1]),
                          selected: s.trainDays.contains(d),
                          selectedColor: mint,
                          onSelected: (v) {
                            final days = {...s.trainDays};
                            v ? days.add(d) : days.remove(d);
                            s.setTrainDays(days);
                            setState(() {
                              if (!days.contains(weekday) && days.isNotEmpty) {
                                _pick(
                                  s.missingDays.firstOrNull ??
                                      s.sortedDays.first,
                                );
                              } else {
                                dayType = s.suggestType(weekday);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  hint:
                      'Escolha em quais dias da semana quer treinar. O treino \u00e9 dividido entre eles.',
                ),
                _panel(
                  'Dia do treino',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.trainDays.isEmpty)
                        const Text('Escolha os dias de treino acima.')
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final d in s.sortedDays)
                              ChoiceChip(
                                label: Text(
                                  s.drafts.containsKey(d)
                                      ? '${weekdayNames[d - 1]} \u2713'
                                      : weekdayNames[d - 1],
                                ),
                                selected: weekday == d,
                                selectedColor: sky,
                                onSelected: (_) => setState(() => _pick(d)),
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      const Text('Tipo do treino deste dia'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in const [
                            'upper1',
                            'lower1',
                            'cardio',
                            'mixed',
                          ])
                            ChoiceChip(
                              avatar: Icon(dayTypes[t]!.$2, size: 18),
                              label: Text(
                                t == 'upper1'
                                    ? 'Superior'
                                    : t == 'lower1'
                                    ? 'Inferior'
                                    : dayTypes[t]!.$1,
                              ),
                              selected: dayType == t,
                              selectedColor: mint,
                              onSelected: (_) => setState(() {
                                dayType = t;
                                muscles.removeWhere(
                                  (m) => !_musclesFor(t).contains(m),
                                );
                              }),
                            ),
                        ],
                      ),
                    ],
                  ),
                  hint:
                      'Comece pela segunda: gere um dia, depois siga para o pr\u00f3ximo.',
                ),
                _panel(
                  'Foco muscular (${dayTypes[dayType]!.$1})',
                  _musclesFor(dayType).isEmpty
                      ? const Text('Cardio n\u00e3o usa foco muscular.')
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final m in _musclesFor(dayType))
                              FilterChip(
                                label: Text(muscleLabel(m)),
                                selected: muscles.contains(m),
                                selectedColor: mint,
                                showCheckmark: false,
                                onSelected: (v) => setState(
                                  () => v ? muscles.add(m) : muscles.remove(m),
                                ),
                              ),
                          ],
                        ),
                  step: 2,
                  hint:
                      'Opcional. Sem sele\u00e7\u00e3o, o treino \u00e9 balanceado.',
                ),
                _panel(
                  'Configura\u00e7\u00e3o',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('N\u00edvel'),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          for (final l in levelNames.entries)
                            ButtonSegment(value: l.key, label: Text(l.value)),
                        ],
                        selected: {level},
                        onSelectionChanged: (v) =>
                            setState(() => level = v.first),
                      ),
                      const SizedBox(height: 14),
                      const Text('Objetivo de treino'),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          for (final o in objectives.entries)
                            ButtonSegment(
                              value: o.key,
                              label: Text(
                                '${o.key[0].toUpperCase()}${o.key.substring(1)} (${o.value.$1}\u00d7${o.value.$2})',
                              ),
                            ),
                        ],
                        selected: {objective},
                        onSelectionChanged: (v) =>
                            setState(() => objective = v.first),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Exerc\u00edcios por treino (no dia): ${count.round()}',
                          ),
                          Expanded(
                            child: Slider(
                              min: 3,
                              max: 12,
                              divisions: 9,
                              value: count,
                              onChanged: (v) => setState(() => count = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  step: 3,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: FilledButton.icon(
                    onPressed:
                        busy || s.available.isEmpty || s.trainDays.isEmpty
                        ? null
                        : generate,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      s.drafts.containsKey(weekday)
                          ? 'Gerar novamente'
                          : 'Gerar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (busy)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: progress == 0 ? null : progress),
                const SizedBox(height: 6),
                Text(status, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ..._plansView(s),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ------------------------------------------------------------------- Treinos

class WorkoutsPage extends StatelessWidget {
  final AppState state;
  final void Function(int) go;
  const WorkoutsPage({required this.state, required this.go, super.key});

  Future<void> _delete(BuildContext context, Workout w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: Text('"${w.name}" será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) state.deleteWorkout(w);
  }

  Widget _card(BuildContext context, Workout w) {
    final total = w.items.length;
    final progress = total == 0 ? 0.0 : w.doneCount / total;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openTicket(context, state, w),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (w.weekday != null)
                          Text(
                            weekdayNames[w.weekday! - 1],
                            style: TextStyle(
                              fontSize: 12,
                              color: ink.withValues(alpha: .6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        showWorkoutEditor(context, state, existing: w),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, w),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: lilac.withValues(alpha: .4),
                          color: const Color(0xFF7E6BB0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${w.doneCount}/$total'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => openTicket(context, state, w),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('Abrir ficha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _draftCard(BuildContext context, Workout w) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: lilac.withValues(alpha: .25),
      child: ListTile(
        onTap: () =>
            showWorkoutEditor(context, state, existing: w, draft: true),
        title: Text(
          w.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${w.items.length} exerc\u00edcios \u2022 ${dayTypes[w.day]!.$1} \u2022 rascunho',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showWorkoutEditor(context, state, existing: w, draft: true),
            ),
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => state.removeDraft(w.weekday!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missingCard(BuildContext context, int d) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treino de ${weekdayFull[d - 1]} ainda n\u00e3o gerado (${dayTypes[state.suggestType(d)]!.$1}).',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.savedEquipment.isEmpty
                        ? null
                        : () {
                            state.aiWeekday = d;
                            go(2);
                          },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Gerar com IA'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.savedEquipment.isEmpty
                        ? null
                        : () => showWorkoutEditor(
                            context,
                            state,
                            draft: true,
                            weekday: d,
                            initialDay: state.suggestType(d),
                            name: 'Treino - ${weekdayNames[d - 1]}',
                          ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Criar manual'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = {
      ...state.trainDays,
      for (final w in state.workouts)
        if (w.weekday != null) w.weekday!,
      ...state.drafts.keys,
    }.toList()..sort();
    final missing = state.missingDays;
    return ListView(
      children: [
        _title(
          'Meus treinos',
          'Escolha os dias da semana, monte manualmente ou com IA e acompanhe na ficha.',
        ),
        if (state.savedEquipment.isEmpty)
          _notice('Nenhum equipamento selecionado.', 'Escolher', () => go(1)),
        _panel(
          'Dias de treino',
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(weekdayNames[d - 1]),
                  selected: state.trainDays.contains(d),
                  selectedColor: mint,
                  onSelected: (v) {
                    final s = {...state.trainDays};
                    v ? s.add(d) : s.remove(d);
                    state.setTrainDays(s);
                  },
                ),
            ],
          ),
          hint: 'Os treinos s\u00e3o divididos entre os dias escolhidos.',
        ),
        if (state.drafts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (missing.isNotEmpty)
                  Text(
                    'Faltam: ${missing.map((d) => weekdayFull[d - 1]).join(', ')}. Gere ou crie para concluir.',
                    style: TextStyle(color: ink.withValues(alpha: .7)),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: missing.isEmpty ? state.commitDrafts : null,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Salvar semana'),
                ),
              ],
            ),
          ),
        if (days.isEmpty && state.workouts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Escolha os dias em que quer treinar.',
              style: TextStyle(color: ink.withValues(alpha: .6)),
            ),
          ),
        for (final d in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              weekdayFull[d - 1],
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
          for (final w in state.workouts.where((w) => w.weekday == d))
            _card(context, w),
          if (state.drafts[d] case final w?) _draftCard(context, w),
          if (!state.coveredDays.contains(d)) _missingCard(context, d),
        ],
        if (state.workouts.any((w) => w.weekday == null)) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Sem dia definido',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
          for (final w in state.workouts.where((w) => w.weekday == null))
            _card(context, w),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ------------------------------------------------------------------ Catálogo

class CatalogPage extends StatefulWidget {
  final AppState state;
  const CatalogPage({required this.state, super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String q = '';
  String? muscle;
  bool onlyMine = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final list = (onlyMine ? s.available : s.exercises).where((e) {
      if (muscle != null && !e.primary.contains(muscle)) return false;
      return q.isEmpty || e.name.toLowerCase().contains(q.toLowerCase());
    }).toList();
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _title('Exercícios', '${list.length} resultados'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(
              hintText: 'Buscar (em inglês)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              FilterChip(
                label: const Text('Só meus equipamentos'),
                selected: onlyMine,
                selectedColor: sky,
                onSelected: (v) => setState(() => onlyMine = v),
              ),
              for (final m in muscleNames.keys)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(muscleLabel(m)),
                    selected: muscle == m,
                    selectedColor: mint,
                    onSelected: (v) => setState(() => muscle = v ? m : null),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => ExerciseTile(list[i]),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- Progresso

class ProgressPage extends StatelessWidget {
  final AppState state;
  const ProgressPage({required this.state, super.key});

  Future<void> addWeight(BuildContext context) async {
    final c = TextEditingController();
    final v = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar peso'),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Peso (kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(c.text.replaceAll(',', '.')),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    c.dispose();
    if (v != null && v > 0) state.addWeight(v);
  }

  @override
  Widget build(BuildContext context) {
    final w = state.weights.length > 12
        ? state.weights.sublist(state.weights.length - 12)
        : state.weights;
    final maxKg = w.isEmpty
        ? 1.0
        : w.map((e) => e.kg).reduce((a, b) => a > b ? a : b);
    return ListView(
      children: [
        _title('Progresso', 'Acompanhe peso e frequência.'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Peso corporal',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => addWeight(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (w.isEmpty)
                    const Text('Sem registros.')
                  else
                    SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < w.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      w[i].kg.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      height: 110 * (w[i].kg / maxKg),
                                      decoration: BoxDecoration(
                                        color: _pastels[i % _pastels.length],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    Text(
                                      '${w[i].date.day}/${w[i].date.month}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        _title('Histórico de treinos'),
        if (state.logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Sem treinos.'),
          ),
        for (final l in state.logs)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(l.workoutName),
              subtitle: Text('${_fmt(l.date)} • ${l.exercises} exercícios'),
              trailing: Text('${l.minutes} min'),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
