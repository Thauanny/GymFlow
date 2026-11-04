import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/format.dart';
import '../../../data/backup/backup_service.dart';
import '../../../data/backup/file_io.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/pill.dart';
import '../../widgets/toast.dart';

/// "Seus dados": explica onde os dados ficam e permite exportar/importar um
/// backup em arquivo, guardado fora do navegador.
class DataBackupCard extends StatefulWidget {
  const DataBackupCard({super.key});

  @override
  State<DataBackupCard> createState() => _DataBackupCardState();
}

class _DataBackupCardState extends State<DataBackupCard> {
  late Future<bool?> _persistent = storageIsPersistent();

  Future<void> _export(BackupService backup) async {
    try {
      downloadTextFile(backup.fileName, backup.export());
      showToast(context, 'Backup baixado. Guarde o arquivo num lugar seguro.');
    } on UnsupportedError catch (e) {
      showToast(context, '$e', error: true);
    }
  }

  Future<void> _import(BackupService backup) async {
    try {
      final content = await pickTextFile();
      if (content == null || !mounted) return;
      final ok = await confirmDialog(
        context,
        title: 'Restaurar backup?',
        message:
            'Os dados do arquivo vão substituir os dados atuais deste navegador.',
        confirm: 'Restaurar',
      );
      if (!ok || !mounted) return;
      final n = await backup.import(content);
      if (mounted) showToast(context, 'Backup restaurado ($n itens).');
    } on BackupException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } on UnsupportedError catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    }
  }

  Future<void> _protect() async {
    final ok = await requestPersistentStorage();
    if (!mounted) return;
    setState(() => _persistent = Future.value(ok));
    if (!ok) {
      showToast(
        context,
        'O navegador não liberou. Faça o backup em arquivo.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final backup = context.read<BackupService>();
    return ListenableBuilder(
      listenable: backup.changes,
      builder: (context, _) {
        final last = backup.lastBackup;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seus treinos ficam salvos neste navegador. Se você limpar os '
                'dados do site, ou o navegador apagar o armazenamento, eles '
                'somem. O backup em arquivo é a sua cópia de segurança.',
                style: TextStyle(color: p.muted, height: 1.35),
              ),
              const SizedBox(height: 12),
              FutureBuilder<bool?>(
                future: _persistent,
                builder: (_, snap) {
                  final v = snap.data;
                  if (v == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        v
                            ? Pill(
                                'Armazenamento protegido',
                                icon: Icons.shield_rounded,
                                color: p.highlight,
                              )
                            : Pill(
                                'Pode ser apagado pelo navegador',
                                icon: Icons.warning_amber_rounded,
                                color: p.warn,
                              ),
                        if (!v)
                          TextButton(
                            onPressed: _protect,
                            child: const Text('Proteger'),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Text(
                last == null
                    ? 'Você ainda não fez nenhum backup.'
                    : 'Último backup: ${formatDate(last)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: last == null ? p.warn : p.text,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => _export(backup),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Exportar backup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _import(backup),
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Importar backup'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'iPhone: toque em Compartilhar → "Adicionar à Tela de Início". '
                'O Safari apaga os dados de sites que ficam 7 dias sem uso, '
                'mas não os de apps adicionados à tela.',
                style: TextStyle(fontSize: 12.5, color: p.muted, height: 1.35),
              ),
              const SizedBox(height: 8),
              Text(
                'Android: no Chrome, toque em ⋮ → "Instalar app" (ou "Adicionar '
                'à tela inicial"). O app abre em tela cheia e o Chrome protege '
                'melhor os dados de apps instalados.',
                style: TextStyle(fontSize: 12.5, color: p.muted, height: 1.35),
              ),
            ],
          ),
        );
      },
    );
  }
}
