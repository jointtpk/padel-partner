import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Stable identifier used for cross-device sync writes (game ownership,
/// request authorship). Resolution order:
///
///   1. **Firebase Auth UID** if a user is signed in. Verifiable server-side
///      so security rules can enforce ownership.
///   2. **Per-install UUID** persisted in SharedPreferences. Fallback used
///      when Firebase Auth isn't available (web, network down, signed-out
///      legacy user). Not server-verifiable, so rules can only check
///      structural validity in this mode.
///
/// Independent from `kMe.id`, which stays `'me'` so existing local checks
/// keep working unchanged.
class IdentityService {
  IdentityService._();
  static final IdentityService instance = IdentityService._();

  static const _kKey = 'sync_uid_v1';

  String? _cachedUuid;

  /// Returns the best available identity. Prefers Firebase UID — kicks off
  /// anonymous sign-in if needed, with a short timeout so we don't block
  /// indefinitely on a flaky network. Falls back to the persisted per-install
  /// UUID otherwise.
  Future<String?> uid() async {
    // Already signed in?
    final cached = AuthService.instance.uid;
    if (cached != null && cached.isNotEmpty) return cached;
    // Try anonymous sign-in with a 3s budget. Anything longer and we'd
    // rather degrade to the legacy UUID than block the caller.
    final signedIn = await AuthService.instance
        .ensureSignedIn()
        .timeout(const Duration(seconds: 3), onTimeout: () => null);
    if (signedIn != null && signedIn.isNotEmpty) return signedIn;
    return _legacyUuid();
  }

  /// Synchronous accessor for code paths that have already awaited [uid] at
  /// least once during this session. Returns the Firebase UID if signed in,
  /// otherwise the cached UUID, otherwise null.
  String? get cached {
    final firebase = AuthService.instance.uid;
    if (firebase != null && firebase.isNotEmpty) return firebase;
    return _cachedUuid;
  }

  Future<String?> _legacyUuid() async {
    if (_cachedUuid != null) return _cachedUuid;
    try {
      final sp = await SharedPreferences.getInstance();
      var v = sp.getString(_kKey);
      if (v == null || v.isEmpty) {
        v = _generate();
        await sp.setString(_kKey, v);
      }
      _cachedUuid = v;
      return v;
    } catch (_) {
      return null;
    }
  }

  String _generate() {
    final rnd = Random.secure();
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = List.generate(8, (_) => rnd.nextInt(36).toRadixString(36)).join();
    return 'u_${ts}_$suffix';
  }
}
