// Na web usa o modelo de embeddings; nas demais plataformas, o fallback.
export 'semantic_ranker_stub.dart'
    if (dart.library.js_interop) 'semantic_ranker.dart';
