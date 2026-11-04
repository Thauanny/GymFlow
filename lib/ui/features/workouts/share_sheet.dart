import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/backup/file_io.dart';
import '../../../data/translation/pt_names.dart';
import '../../../domain/training/workout_text.dart';
import '../../../models/workout.dart';
import '../../../state/catalog_cubit.dart';
import '../../widgets/toast.dart';

/// Texto da ficha de [w] com os nomes do catálogo.
String workoutShareText(BuildContext context, Workout w) {
  final catalog = context.read<CatalogCubit>();
  return workoutToText(w, byId: catalog.byId, namePt: exerciseNamePt);
}

/// Texto da semana inteira.
String weekShareText(BuildContext context, List<Workout> ws) {
  final catalog = context.read<CatalogCubit>();
  return weekToText(ws, byId: catalog.byId, namePt: exerciseNamePt);
}

/// Folha de compartilhamento: prévia do texto, enviar no WhatsApp e copiar.
Future<void> showShareSheet(
  BuildContext context, {
  required String title,
  required String text,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ShareSheet(title: title, text: text),
);

class _ShareSheet extends StatelessWidget {
  final String title, text;
  const _ShareSheet({required this.title, required this.text});

  void _whatsapp(BuildContext context) {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    try {
      openUrl(url);
    } on UnsupportedError {
      _copy(context);
    }
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(context, 'Ficha copiada. É só colar onde quiser.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Prévia da mensagem que vai para o WhatsApp.',
              style: TextStyle(fontSize: 13, color: p.muted),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.cardAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: const TextStyle(height: 1.4, fontSize: 13.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _whatsapp(context),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Enviar no WhatsApp'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar ficha'),
            ),
          ],
        ),
      ),
    );
  }
}
