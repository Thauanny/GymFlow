import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/backup/file_io.dart';
import '../../widgets/toast.dart';

const linkedinUrl = 'https://www.linkedin.com/in/thauanny-ramos/';
const contactEmail = 'gymflow.free@gmail.com';
const _emailUrl =
    'mailto:$contactEmail?subject=Sugest%C3%A3o%20para%20o%20GymFlow';

/// Contato: sugestões e ideias chegam por e-mail ou pelo LinkedIn da criadora.
Future<void> showContactSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ContactSheet(),
    );

class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  void _open(BuildContext context) {
    try {
      openUrl(linkedinUrl);
    } on UnsupportedError {
      Clipboard.setData(const ClipboardData(text: linkedinUrl));
      showToast(context, 'Link copiado: $linkedinUrl');
    }
  }

  void _email(BuildContext context) {
    try {
      openUrl(_emailUrl);
    } on UnsupportedError {
      Clipboard.setData(const ClipboardData(text: contactEmail));
      showToast(context, 'E-mail copiado: $contactEmail');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CONTATO E SUGESTÕES', style: AppText.display(36)),
            const SizedBox(height: 8),
            Text(
              'Tem uma sugestão, encontrou algo estranho ou quer trocar uma '
              'ideia sobre o GymFlow? Escreva por e-mail ou me chame no LinkedIn.',
              style: TextStyle(color: p.muted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.cardAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: p.volt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.person_rounded, color: p.onVolt),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thauanny Ramos',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'linkedin.com/in/thauanny-ramos',
                          style: TextStyle(fontSize: 13, color: p.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir LinkedIn'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _email(context),
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Enviar e-mail'),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  contactEmail,
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
                IconButton(
                  tooltip: 'Copiar e-mail',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.copy_rounded, size: 18, color: p.muted),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: contactEmail));
                    showToast(context, 'E-mail copiado');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
