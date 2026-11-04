// Na web usa o navegador; nas demais plataformas, o stub.
export 'file_io_stub.dart' if (dart.library.js_interop) 'file_io_web.dart';
