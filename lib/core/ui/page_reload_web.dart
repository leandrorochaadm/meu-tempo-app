import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Recarrega a página inteira no navegador — `window.location.reload()`.
void reloadPage() {
  globalContext
      .getProperty<JSObject>('location'.toJS)
      .callMethod('reload'.toJS);
}
