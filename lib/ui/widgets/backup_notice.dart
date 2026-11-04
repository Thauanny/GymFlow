import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_palette.dart';
import '../../data/backup/backup_service.dart';
import '../features/settings/settings_page.dart';
import 'page_body.dart';

/// Aviso fixo: há alterações sem backup. Tocar leva à tela de backup; o "x"
/// esconde o aviso até a próxima alteração.
class BackupNotice extends StatelessWidget {
  const BackupNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final backup = context.read<BackupService>();
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return ValueListenableBuilder<bool>(
      valueListenable: backup.reminder,
      builder: (context, due, _) => AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: !due
            ? const SizedBox(width: double.infinity)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      narrow ? 16 : 28,
                      10,
                      narrow ? 16 : 28,
                      0,
                    ),
                    child: _Banner(
                      subtitle: backup.hasChangesSinceBackup
                          ? (backup.lastBackup == null
                                ? 'Você ainda não fez nenhum backup.'
                                : 'Há alterações desde o último backup.')
                          : 'Seu último backup está antigo.',
                      onOpen: () => openSettings(context, toBackup: true),
                      onClose: backup.dismissReminder,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String subtitle;
  final VoidCallback onOpen, onClose;
  const _Banner({
    required this.subtitle,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final shape = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: p.warn.withValues(alpha: .12),
          borderRadius: shape,
          border: Border.all(color: p.warn.withValues(alpha: .4)),
        ),
        child: InkWell(
          borderRadius: shape,
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: p.warn),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Faça um backup dos seus dados',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.muted),
                IconButton(
                  tooltip: 'Dispensar',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 20, color: p.muted),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
