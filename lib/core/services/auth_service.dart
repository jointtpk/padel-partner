import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around `FirebaseAuth` for anonymous sign-in.
///
/// Why anonymous? The app already has a custom email-OTP sign-up flow that
/// users invest several steps in. Replacing it with Firebase's email-link
/// flow would be a large UX change. Anonymous sign-in lets us mint a real
/// Firebase UID *behind* the existing OTP UX so Firestore security rules
/// can verify ownership (`request.auth.uid == resource.data.hostUid`)
/// without changing what the user sees.
///
/// **Graceful degradation:** every method here catches and logs errors.
/// If Firebase Auth is unavailable (no project, network down, etc.),
/// callers get null and the rest of the app falls back to the per-install
/// UUID from `IdentityService`. Nothing user-visible breaks.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// The current Firebase UID, or null if not signed in / Firebase
  /// unavailable. Synchronous — call after [ensureSignedIn] to get a value.
  String? get uid => _auth?.currentUser?.uid;

  /// Idempotently ensures there is a signed-in Firebase user. If one
  /// already exists, returns its UID; otherwise signs in anonymously.
  /// Returns null on any failure — caller must treat null as "no Firebase
  /// identity, use IdentityService fallback".
  Future<String?> ensureSignedIn() async {
    final auth = _auth;
    if (auth == null) return null;
    try {
      if (auth.currentUser != null) return auth.currentUser!.uid;
      final cred = await auth.signInAnonymously();
      return cred.user?.uid;
    } catch (e) {
      debugPrint('AuthService.ensureSignedIn error: $e');
      return null;
    }
  }

  /// Signs out the current Firebase user. Used by [AppController.signOut].
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut error: $e');
    }
  }
}
