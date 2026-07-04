import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabLoginType.dart';

/// JS snippets to fill login forms — one strategy per [DevQuickTabLoginType].
abstract final class WebViewLoginAutofill {
  WebViewLoginAutofill._();

  static String buildScript({
    required DevQuickTabLoginType type,
    required String username,
    required String password,
    required String passkey,
  }) {
    switch (type) {
      case DevQuickTabLoginType.htmlForm:
        return _htmlFormScript(username, password);
      case DevQuickTabLoginType.emailPassword:
        return _emailPasswordScript(username, password);
      case DevQuickTabLoginType.apiKey:
        return _apiKeyScript(passkey);
      case DevQuickTabLoginType.httpBasic:
      case DevQuickTabLoginType.oauth:
      case DevQuickTabLoginType.none:
        return '(function(){})();';
    }
  }

  static String _htmlFormScript(String username, String password) {
    final u = _escapeJs(username);
    final p = _escapeJs(password);
    return '''
(function() {
  try {
    var user = '$u';
    var pass = '$p';
    if (!user || !pass) return;
    var passEl = document.querySelector('input[type="password"]');
    if (!passEl || passEl.value) return;
    var userEl = document.querySelector(
      '#usernamefld, #username, input[name="usernamefld"], input[name="username"], '
      + 'input[name="user"], input[name="login"], input[autocomplete="username"]'
    );
    if (!userEl) {
      var form = passEl.closest('form');
      if (form) {
        userEl = form.querySelector('input[type="text"], input[type="email"]');
      }
    }
    $_setValHelper
    setVal(userEl, user);
    setVal(passEl, pass);
  } catch (e) {}
})();
''';
  }

  static String _emailPasswordScript(String email, String password) {
    final e = _escapeJs(email);
    final p = _escapeJs(password);
    return '''
(function() {
  try {
    var email = '$e';
    var pass = '$p';
    if (!email || !pass) return;
    var passEl = document.querySelector(
      'input[type="password"], input[name="password"], input[autocomplete="current-password"]'
    );
    if (!passEl || passEl.value) return;
    var emailEl = document.querySelector(
      'input[type="email"], input[name="email"], input[autocomplete="email"], '
      + 'input[autocomplete="username"], input[id*="email" i], input[placeholder*="@" i]'
    );
    if (!emailEl) {
      var form = passEl.closest('form');
      if (form) {
        emailEl = form.querySelector('input[type="text"], input[type="email"]');
      }
    }
    $_setValHelper
    $_reactSetValHelper
    reactSet(emailEl, email);
    reactSet(passEl, pass);
  } catch (e) {}
})();
''';
  }

  static String _apiKeyScript(String passkey) {
    final k = _escapeJs(passkey);
    return '''
(function() {
  try {
    var key = '$k';
    if (!key) return;
    var el = document.querySelector(
      'input[name*="api" i], input[name*="key" i], input[name*="token" i], '
      + 'input[placeholder*="api" i], input[placeholder*="key" i], textarea[name*="key" i]'
    );
    if (!el || el.value) return;
    $_setValHelper
    $_reactSetValHelper
    reactSet(el, key);
  } catch (e) {}
})();
''';
  }

  static const _setValHelper = '''
    function setVal(el, v) {
      if (!el || el.value) return;
      el.focus();
      el.value = v;
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
    }
''';

  static const _reactSetValHelper = '''
    function reactSet(el, v) {
      if (!el || el.value) return;
      try {
        var proto = window.HTMLInputElement.prototype;
        var setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
        setter.call(el, v);
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
      } catch (err) {
        setVal(el, v);
      }
    }
''';

  static String _escapeJs(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r');
}
