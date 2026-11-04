import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../state/theme_cubit.dart';
import '../../widgets/app_card.dart';
import '../../widgets/page_body.dart';
import '../../widgets/section_title.dart';
import 'contact_sheet.dart';
import 'data_backup_card.dart';
import 'data_reset_card.dart';

/// Com [toBackup], abre já rolado até "Seus dados" (exportar/importar backup).
Future<void> openSettings(BuildContext context, {bool toBackup = false}) =>
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsPage(scrollToBackup: toBackup)),
    );

/// Configurações: aparência, seus dados (backup e apagar) e contato.
class SettingsPage extends StatefulWidget {
  final bool scrollToBackup;
  const SettingsPage({this.scrollToBackup = false, super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _backupKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToBackup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = _backupKey.currentContext;
        if (c != null) {
          Scrollable.ensureVisible(
            c,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(),
      body: PageBody(
        title: 'Configurações',
        subtitle: 'Aparência, seus dados e contato.',
        children: [
          const SectionTitle('Aparência'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: SwitchListTile(
              value: dark,
              onChanged: (_) => context.read<ThemeCubit>().toggle(
                Theme.of(context).brightness,
              ),
              secondary: Icon(
                dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: p.muted,
              ),
              title: const Text(
                'Tema escuro',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                dark ? 'Ligado' : 'Desligado',
                style: TextStyle(color: p.muted),
              ),
            ),
          ),
          KeyedSubtree(
            key: _backupKey,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [SectionTitle('Seus dados'), DataBackupCard()],
            ),
          ),
          const SectionTitle('Apagar dados'),
          const DataResetCard(),
          const SectionTitle('Contato'),
          AppCard(
            onTap: () => showContactSheet(context),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, color: p.muted),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Enviar sugestão ou falar comigo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
