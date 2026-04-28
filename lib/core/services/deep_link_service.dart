import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../models/game.dart';
import 'game_sync_service.dart';

/// Listens for incoming `padelpartner://join?…` deep links and routes the
/// user into the matching game's detail screen.
///
/// Two URL forms are supported:
///   1. Short:    `padelpartner://join?id=<gameId>`
///                Used when the game is published to Firestore; the recipient
///                fetches the live document by id.
///   2. Embedded: `padelpartner://join?d=<base64url game JSON>`
///                Fallback when Firestore isn't available (no project,
///                offline, rules block writes). Self-contained — the URL
///                itself carries the entire game payload.
///
/// Encoders should prefer the short form via [buildShareUrl] which probes
/// Firestore availability and falls back automatically.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  static const _scheme = 'padelpartner';
  static const _joinHost = 'join';

  /// Firebase Hosting domain for shareable HTTPS join links. The browser
  /// page at `/g/<id>` (`public/g.html`) bounces into the custom scheme so
  /// the existing handler picks the link up. Once iOS Universal Links /
  /// Android App Links are configured for this domain, the OS will route
  /// taps directly into the app and `_handle` will see the HTTPS URI.
  static const _hostingDomain = 'padelpartner-74b7d.web.app';

  /// Begin listening for cold-start + runtime links. Safe to call once on app
  /// launch.
  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      debugPrint('DeepLinkService initial link error: $e');
    }
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (e) => debugPrint('DeepLinkService stream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _handle(Uri uri) {
    // Custom scheme: padelpartner://join?id=… or ?d=…
    if (uri.scheme == _scheme && uri.host == _joinHost) {
      final id = uri.queryParameters['id'];
      final encoded = uri.queryParameters['d'];
      if (id != null && id.isNotEmpty) {
        _handleByIdLookup(id);
      } else if (encoded != null && encoded.isNotEmpty) {
        _handleEmbedded(encoded);
      }
      return;
    }
    // HTTPS App / Universal Link: https://<hosting>/g/<gameId>
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == _hostingDomain &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'g') {
      final id = uri.pathSegments[1];
      if (id.isNotEmpty) _handleByIdLookup(id);
    }
  }

  Future<void> _handleByIdLookup(String gameId) async {
    final game = await GameSyncService.instance.fetchGame(gameId);
    if (game == null) {
      debugPrint('DeepLinkService: no Firestore game for id=$gameId');
      return;
    }
    _navigate(game);
  }

  void _handleEmbedded(String encoded) {
    try {
      final jsonStr = utf8.decode(base64Url.decode(_padBase64(encoded)));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final game = Game.fromMap(map);
      _navigate(game);
    } catch (e) {
      debugPrint('DeepLinkService failed to decode embedded link: $e');
    }
  }

  void _navigate(Game game) {
    // Microtask so the navigator is mounted on cold start.
    Future.microtask(() => Get.toNamed(Routes.detail, arguments: game));
  }

  String _padBase64(String s) {
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s + '=' * (4 - mod);
  }

  /// Builds the shareable join URL for [game]. Order of preference:
  ///   1. HTTPS link (`https://<hosting>/g/<id>`) — clickable in any chat
  ///      app. Used when the game was successfully published to Firestore.
  ///   2. Custom-scheme link with embedded payload (`padelpartner://…?d=…`)
  ///      as a fallback when Firestore is unavailable.
  static Future<String> buildShareUrl(Game game) async {
    final published = await GameSyncService.instance.publishGame(game);
    if (published) {
      return 'https://$_hostingDomain/g/${Uri.encodeComponent(game.id)}';
    }
    return _buildEmbeddedUrl(game);
  }

  /// Synchronous embedded-payload fallback. Useful when callers can't await
  /// (or want to avoid the Firestore round-trip).
  static String buildShareUrlSync(Game game) => _buildEmbeddedUrl(game);

  static String _buildEmbeddedUrl(Game game) {
    final json = jsonEncode(game.toMap());
    final encoded = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return '$_scheme://$_joinHost?d=$encoded';
  }
}
