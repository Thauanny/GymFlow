import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Com [destructive], o botão de confirmar fica vermelho (ações que apagam).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Confirmar',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: ctx.pal.danger,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Pede um número (aceita vírgula decimal). Retorna null se cancelado.
Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirm = 'Salvar',
}) async {
  final c = TextEditingController(text: initial);
  final v = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, double.tryParse(c.text.replaceAll(',', '.'))),
          child: Text(confirm),
        ),
      ],
    ),
  );
  c.dispose();
  return v;
}
