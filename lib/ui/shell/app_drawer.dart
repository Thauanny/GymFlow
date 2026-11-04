import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';
import '../features/settings/contact_sheet.dart';
import '../features/settings/settings_page.dart';

/// Menu sanduíche: configurações e contato.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Fecha o menu e então executa [action] (com o contexto da página).
  void _go(BuildContext context, void Function(BuildContext) action) {
    final page = Navigator.of(context);
    page.pop(); // fecha o drawer
    action(page.context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Drawer(
      backgroundColor: p.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: p.volt,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.onVolt, width: 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('GYMFLOW', style: AppText.display(30)),
                ],
              ),
            ),
            const Divider(),
            _Item(
              icon: Icons.settings_rounded,
              label: 'Configurações',
              onTap: () => _go(context, openSettings),
            ),
            _Item(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Contato e sugestões',
              onTap: () => _go(context, showContactSheet),
            ),
            const Spacer(),
            const _Version(),
          ],
        ),
      ),
    );
  }
}

/// Versão do app, discreta no fim do menu.
class _Version extends StatelessWidget {
  const _Version();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: Text(
          'v$appVersion',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .4,
            color: context.pal.muted,
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: context.pal.muted),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}
