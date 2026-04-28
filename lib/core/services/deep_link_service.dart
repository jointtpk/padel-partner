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
    if (uri.scheme != _scheme) return;
    if (uri.host != _joinHost) return;
    final id = uri.queryParameters['id'];
    final encoded = uri.queryParameters['d'];
    if (id != null && id.isNotEmpty) {
      _handleByIdLookup(id);
    } else if (encoded != null && encoded.isNotEmpty) {
      _handleEmbedded(encoded);
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

  /// Builds the shareable join URL for [game]. Tries Firestore publish first
  /// for a short URL; falls back to embedding the full game payload so the
  /// link still works without a backend.
  static Future<String> buildShareUrl(Game game) async {
    final published = await GameSyncService.instance.publishGame(game);
    if (published) {
      return '$_scheme://$_joinHost?id=${Uri.encodeComponent(game.id)}';
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
