import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/responsive.dart';
import '../../data/gif_catalog.dart';

/// GIF animado via elemento <img> do navegador (anima e evita problemas de CORS).
///
/// Em celulares ([lite] automático) baixa uma versão WebP animada, ~4x menor;
/// se ela falhar, usa o GIF original. Detalhes de exercício passam `lite: false`.
class GifView extends StatelessWidget {
  final String url;
  final double height;
  final Widget? fallback;
  final bool? lite;

  const GifView(
    this.url, {
    this.height = 160,
    this.fallback,
    this.lite,
    super.key,
  });

  Widget _image(String src, ImageErrorWidgetBuilder onError) => Image.network(
    src,
    key: ValueKey(src),
    fit: BoxFit.contain,
    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
    errorBuilder: onError,
  );

  @override
  Widget build(BuildContext context) {
    Widget failed(BuildContext ctx, Object _, StackTrace? _) =>
        fallback ??
        Center(
          child: Icon(Icons.image_not_supported_outlined, color: ctx.pal.muted),
        );
    final useLite = lite ?? isPhone(context);
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.white, // os GIFs têm fundo branco
      child: useLite
          ? _image(gifLiteUrl(url), (_, _, _) => _image(url, failed))
          : _image(url, failed),
    );
  }
}

/// Miniatura estática de um GIF. Em listas, dezenas de GIFs animados juntos
/// esgotam a memória do navegador do celular e a página recarrega.
class GifThumb extends StatelessWidget {
  final String url;
  final double size;
  final Widget fallback;

  const GifThumb(
    this.url, {
    required this.size,
    required this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
      48,
      256,
    );
    return Container(
      width: size,
      height: size,
      color: Colors.white, // os GIFs têm fundo branco
      child: Image.network(
        gifThumbUrl(url, px),
        key: ValueKey('$url@$px'),
        fit: BoxFit.contain,
        cacheWidth: px,
        gaplessPlayback: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
