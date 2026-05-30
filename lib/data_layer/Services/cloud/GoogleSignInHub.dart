import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Single [GoogleSignIn] for Drive, Calendar, and Docs export.
/// Multiple instances with the same client ID but different scopes break
/// silent sign-in on macOS/iOS.
class GoogleSignInHub {
  GoogleSignInHub._();

  static const String webClientId =
      '1076295055088-s88o9d59unnd0p68be5pmsiv6h2a0rgo.apps.googleusercontent.com';
  static const String darwinClientId =
      '807274985161-2tgda6mbjop0k2vnf85q5plac7t6d1aq.apps.googleusercontent.com';

  /// GCP project number for [darwinClientId] (enable APIs here on macOS/iOS).
  static const String darwinProjectNumber = '807274985161';

  static final List<String> allScopes = [
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveMetadataReadonlyScope,
    cal.CalendarApi.calendarReadonlyScope,
  ];

  static final GoogleSignIn signIn = GoogleSignIn(
    clientId: (Platform.isIOS || Platform.isMacOS) ? darwinClientId : null,
    serverClientId: webClientId,
    scopes: allScopes,
  );

  /// Login-only — do not request Drive/Calendar scopes during Supabase auth.
  static final GoogleSignIn authSignIn = GoogleSignIn(
    clientId: (Platform.isIOS || Platform.isMacOS) ? darwinClientId : null,
    serverClientId: webClientId,
    scopes: const ['email', 'profile'],
  );

  static Future<GoogleSignInAccount?> silentAccount() =>
      signIn.signInSilently();

  static Future<GoogleSignInAccount?> interactiveSignIn() => signIn.signIn();

  /// Web: sign-in does not grant API scopes — check then request incrementally.
  /// Darwin/Android: [canAccessScopes] is unimplemented; [requestScopes] prompts
  /// for any scopes not yet granted (e.g. calendar after an older sign-in).
  static Future<bool> ensureScopes(List<String> scopes) async {
    if (kIsWeb) {
      final missing = <String>[];
      for (final scope in scopes) {
        final ok = await signIn.canAccessScopes([scope]);
        if (!ok) missing.add(scope);
      }
      if (missing.isEmpty) return true;
      return signIn.requestScopes(missing);
    }
    return signIn.requestScopes(scopes);
  }
}

/// HTTP client that attaches fresh OAuth headers per request.
class GoogleAuthorizedClient extends http.BaseClient {
  final GoogleSignInAccount account;
  final http.Client _inner = http.Client();

  GoogleAuthorizedClient(this.account);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await account.authHeaders;
    request.headers.addAll(headers);
    return _inner.send(request);
  }
}
