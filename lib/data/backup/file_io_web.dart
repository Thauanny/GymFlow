import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Baixa [content] como arquivo de texto.
void downloadTextFile(String name, String content) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
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
  web.window.open(url, '_blank', 'noopener,noreferrer');
}
