import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/backup/file_io.dart';
import '../../widgets/toast.dart';

/// Passo a passo para colocar o GymFlow na tela de início: um seletor
/// iPhone/Android (já no aparelho certo) e os 3 passos. No iPhone o navegador
/// não deixa o site criar o atalho, então só dá para guiar a pessoa.
class InstallGuide extends StatefulWidget {
  const InstallGuide({super.key});

  @override
  State<InstallGuide> createState() => _InstallGuideState();
}

class _InstallGuideState extends State<InstallGuide> {
  late bool _ios = isIos || !isAndroid;

  static const _iosSteps = [
    _Step(
      Icons.ios_share_rounded,
      'Toque em Compartilhar',
      'Safari: barra de baixo · Brave/Chrome: perto do endereço ou menu ⋯',
    ),
    _Step(Icons.add_box_outlined, 'Adicionar à Tela de Início', ''),
    _Step(Icons.check_rounded, 'Toque em Adicionar', ''),
  ];

  static const _androidSteps = [
    _Step(
      Icons.more_vert_rounded,
      'Abra o menu ⋮',
      'Canto superior direito do Chrome',
    ),
    _Step(
      Icons.install_mobile_rounded,
      'Instalar app',
      'ou "Adicionar à tela inicial"',
    ),
    _Step(Icons.check_rounded, 'Confirme', ''),
  ];

  @override
  Widget build(BuildContext context) {
    if (isInstalledApp) return const _InstalledNote();
    final p = context.pal;
    final steps = _ios ? _iosSteps : _androidSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Só no computador (aparelho desconhecido) deixa escolher; no celular
        // mostra só o roteiro do próprio aparelho.
        if (!isIos && !isAndroid) ...[
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: true, label: Text('iPhone')),
              ButtonSegment(value: false, label: Text('Android')),
            ],
            selected: {_ios},
            onSelectionChanged: (v) => setState(() => _ios = v.first),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            color: p.border.withValues(alpha: .25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (final (i, st) in steps.indexed) ...[
                if (i > 0) Divider(height: 1, indent: 52, color: p.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: p.muted,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(st.icon, size: 20, color: p.text),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              st.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (st.text.isNotEmpty)
                              Text(
                                st.text,
                                style: TextStyle(fontSize: 12, color: p.muted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_ios)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No iPhone nenhum navegador (Safari, Brave, Chrome) deixa o site criar o atalho sozinho: só por este menu.',
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
          ),
      ],
    );
  }
}

class _InstalledNote extends StatelessWidget {
  const _InstalledNote();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 18, color: p.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'GymFlow já está instalado na sua tela de início.',
            style: TextStyle(fontSize: 12.5, color: p.muted),
          ),
        ),
      ],
    );
  }
}

class _Step {
  final IconData icon;
  final String title, text;
  const _Step(this.icon, this.title, this.text);
}

/// Botão "Adicionar atalho": no Chrome/Android abre o convite nativo de
/// instalação; no iPhone (que não permite isso por código) e nos demais casos
/// abre o passo a passo.
class AddShortcutButton extends StatelessWidget {
  final bool filled;
  const AddShortcutButton({this.filled = true, super.key});

  Future<void> _tap(BuildContext context) async {
    if (canPromptInstall) {
      final ok = await promptInstall();
      if (ok && context.mounted) showToast(context, 'Atalho adicionado!');
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: InstallGuide(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.add_to_home_screen_rounded);
    const label = Text('Adicionar atalho');
    return filled
        ? FilledButton.icon(
            onPressed: () => _tap(context),
            icon: icon,
            label: label,
          )
        : OutlinedButton.icon(
            onPressed: () => _tap(context),
            icon: icon,
            label: label,
          );
  }
}

/// Aviso na Home (só no celular, enquanto o app não estiver instalado).
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  static const _key = 'install_banner_hidden';
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    if (!(isIos || isAndroid) || isInstalledApp) return;
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _hidden = p.getBool(_key) ?? false);
    });
  }

  Future<void> _close() async {
    setState(() => _hidden = true);
    (await SharedPreferences.getInstance()).setBool(_key, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 12),
      decoration: BoxDecoration(
        color: p.highlight.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.highlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_to_home_screen_rounded, color: p.text),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Coloque o GymFlow na tela de início',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Dispensar',
                onPressed: _close,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              'Abre como app, em tela cheia, e seus dados ficam mais protegidos.',
              style: TextStyle(color: p.muted, fontSize: 13, height: 1.35),
            ),
          ),
          const SizedBox(height: 10),
          const AddShortcutButton(),
        ],
      ),
    );
  }
}
