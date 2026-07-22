// Fachada com conditional import: usa a implementação web (js_interop) quando
// compilado para a Web, e um stub inofensivo na VM (para os testes rodarem).
export 'page_reload_stub.dart'
    if (dart.library.js_interop) 'page_reload_web.dart';
