import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Entrega [content] como arquivo. No celular (iOS/Android) abre a folha de
/// compartilhar, onde dá para "Salvar em Arquivos"/Drive; o download por link
/// é ignorado pelo Safari em apps da tela de início. Sem isso, baixa direto.
Future<void> downloadTextFile(String name, String content) async {
  final file = web.File(
    [content.toJS].toJS,
    name,
    web.FilePropertyBag(type: 'application/json'),
  );
  if (_isMobile) {
    try {
      final data = web.ShareData(files: [file].toJS, title: name);
      if (web.window.navigator.canShare(data)) {
        await web.window.navigator.share(data).toDart;
        return;
      }
    } catch (e) {
      // Usuário fechou a folha de compartilhar: não é erro, nada a baixar.
      if ('$e'.contains('AbortError')) return;
    }
  }
  final url = web.URL.createObjectURL(file);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.append(a);
  a.click();
  a.remove();
  // Revogar na hora cancela o download em alguns navegadores móveis.
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}

String get _ua => web.window.navigator.userAgent;

/// iPhone/iPad (inclui iPadOS, que se apresenta como Mac com toque).
bool get isIos =>
    RegExp(r'iPhone|iPad|iPod').hasMatch(_ua) ||
    (web.window.navigator.platform == 'MacIntel' &&
        web.window.navigator.maxTouchPoints > 1);

bool get isAndroid => _ua.contains('Android');

bool get _isMobile => isIos || isAndroid;

/// O app já está aberto a partir da tela de início (modo "instalado")?
bool get isInstalledApp {
  try {
    // iOS (Safari e outros) marca o app aberto pela tela de início assim.
    final ios = (web.window.navigator as JSObject)
        .getProperty<JSAny?>('standalone'.toJS)
        .dartify();
    return ios == true ||
        web.window.matchMedia('(display-mode: standalone)').matches ||
        web.window.matchMedia('(display-mode: fullscreen)').matches ||
        web.window.matchMedia('(display-mode: minimal-ui)').matches;
  } catch (_) {
    return false;
  }
}

/// Abre o seletor de arquivos e devolve o texto do escolhido (null se vazio).
/// Se o usuário cancelar o seletor, o futuro simplesmente não completa.
Future<String?> pickTextFile() {
  final done = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json';
  input.onChange.listen((_) async {
    final file = input.files?.item(0);
    if (file == null) {
      done.complete(null);
      return;
    }
    done.complete((await file.text().toDart).toDart);
  });
  input.click();
  return done.future;
}

/// O navegador já marcou o armazenamento do site como protegido contra limpeza
/// automática? (null = o navegador não informa).
Future<bool?> storageIsPersistent() async {
  try {
    return (await web.window.navigator.storage.persisted().toDart).toDart;
  } catch (_) {
    return null;
  }
}

/// Pede ao navegador para não apagar os dados do site automaticamente.
Future<bool> requestPersistentStorage() async {
  try {
    return (await web.window.navigator.storage.persist().toDart).toDart;
  } catch (_) {
    return false;
  }
}

/// Abre [url] em outra aba, sem repassar a origem da página.
void openUrl(String url) {
  // mailto abre o app de e-mail na própria aba (em outra aba fica em branco).
  if (url.startsWith('mailto:')) {
    web.window.location.href = url;
    return;
  }
  web.window.open(url, '_blank', 'noopener,noreferrer');
}

/// O navegador (Chrome/Android) liberou o convite nativo de instalação?
bool get canPromptInstall =>
    web.window.getProperty<JSAny?>('__gfInstall'.toJS).isDefinedAndNotNull;

/// Abre o convite nativo "Instalar app". Devolve true se a pessoa aceitou.
Future<bool> promptInstall() async {
  try {
    final ev = web.window.getProperty<JSObject?>('__gfInstall'.toJS);
    if (ev == null) return false;
    ev.callMethod<JSAny?>('prompt'.toJS);
    final choice = await ev
        .getProperty<JSPromise<JSObject>>('userChoice'.toJS)
        .toDart;
    web.window.setProperty('__gfInstall'.toJS, null);
    return choice.getProperty<JSString>('outcome'.toJS).toDart == 'accepted';
  } catch (_) {
    return false;
  }
}
