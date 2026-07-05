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
      case DevQuickTabLoginType.bearerToken:
        return _apiKeyScript(passkey);
      case DevQuickTabLoginType.httpBasic:
      case DevQuickTabLoginType.externalBrowser:
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

    function setVal(el, v) {
      if (!el || el.value) return false;
      try {
        var proto = window.HTMLInputElement.prototype;
        var setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
        setter.call(el, v);
      } catch (err) {
        el.value = v;
      }
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      el.dispatchEvent(new Event('blur', { bubbles: true }));
      return true;
    }

    function findTokenInput() {
      var selectors = [
        'input[formcontrolname="token" i]',
        'input[name*="token" i]',
        'input[placeholder*="token" i]',
        'input[aria-label*="token" i]',
        'input[aria-label*="bearer" i]',
        'input[id*="token" i]',
        'textarea[name*="token" i]'
      ];
      for (var i = 0; i < selectors.length; i++) {
        var el = document.querySelector(selectors[i]);
        if (el) return el;
      }
      var labels = document.querySelectorAll('label, mat-label, .mat-form-field-label');
      for (var j = 0; j < labels.length; j++) {
        var txt = (labels[j].textContent || '').toLowerCase();
        if (txt.indexOf('bearer') >= 0 && txt.indexOf('token') >= 0) {
          var wrap = labels[j].closest('.mat-form-field, form, .login-form, kd-login');
          if (wrap) {
            var inp = wrap.querySelector('input, textarea');
            if (inp) return inp;
          }
        }
      }
      var pwd = document.querySelector('input[type="password"]');
      if (pwd && document.querySelectorAll('input[type="password"]').length === 1) {
        return pwd;
      }
      return null;
    }

    var el = findTokenInput();
    if (!el) return;
    if (!setVal(el, key)) return;

    setTimeout(function() {
      var buttons = document.querySelectorAll('button, input[type="submit"]');
      for (var i = 0; i < buttons.length; i++) {
        var t = (buttons[i].textContent || buttons[i].value || '').trim().toLowerCase();
        if (t.indexOf('sign in') >= 0 || t === 'login' || t.indexOf('đăng nhập') >= 0) {
          buttons[i].click();
          break;
        }
      }
    }, 500);
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
