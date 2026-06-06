/// Handles the custom URL scheme used by iOS Shortcuts.
///
/// iOS Shortcut opens:
///   fintrack://add-sms?text=<url-encoded SMS body>
///
/// The app decodes the text and pre-fills the Add SMS screen,
/// which then auto-parses and saves the transaction.
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/add_sms_screen.dart';

class DeepLinkService {
  static final _instance = DeepLinkService._();
  DeepLinkService._();
  factory DeepLinkService() => _instance;

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Call once from main.dart after the navigator is ready.
  void init(GlobalKey<NavigatorState> navigatorKey) {
    // Handle links that opened the app from a cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handle(uri, navigatorKey);
    });

    // Handle links while app is already running
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri, navigatorKey),
    );
  }

  void dispose() => _sub?.cancel();

  void _handle(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    if (uri.scheme != 'fintrack') return;
    if (uri.host == 'add-sms') {
      final text = uri.queryParameters['text'] ?? '';
      if (text.trim().isEmpty) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AddSmsScreen(prefillText: text),
        ),
      );
    }
  }
}
