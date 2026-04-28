import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart' show JoinRequest;
import '../models/game.dart';
import '../models/player.dart';
import 'identity_service.dart';

/// Thin wrapper around Firestore for cross-device game sync.
///
/// **Design invariant: graceful degradation.** Every method here returns a
/// safe default (false / null / empty stream) on any failure — no exceptions
/// surface to callers. If your Firestore project isn't configured, security
/// rules block writes, or the device is offline, the app behaves exactly as
/// the in-memory-only version did.
///
/// The "live" feature unlocked by this service is: deep-link recipients can
/// open a hosted game and submit a join request that the host actually
/// receives on their device.
///
/// Firestore layout:
///   games/{gameId}
///     - all fields from Game.toMap()
///     - hostUid: <IdentityService uid of the publishing device>
///     - createdAt: server timestamp
///   games/{gameId}/requests/{requesterUid}
///     - userId: <requester's IdentityService uid>
///     - playerSnapshot: <Player.toMap() captured at request time>
///     - note: optional message
///     - status: 'pending' | 'approved' | 'declined'
///     - createdAt: server timestamp
class GameSyncService {
  GameSyncService._();
  static final GameSyncService instance = GameSyncService._();

  FirebaseFirestore? _db;

  /// Lazily resolves the Firestore instance. Returns null if Firebase isn't
  /// initialised (e.g. on web, or if init failed at app start).
  FirebaseFirestore? get _firestore {
    if (_db != null) return _db;
    try {
      _db = FirebaseFirestore.instance;
      return _db;
    } catch (_) {
      return null;
    }
  }

  bool get _enabled => _firestore != null;

  /// Publish a hosted [game] to Firestore. Returns true on success — used by
  /// the share-link builder to decide between a short URL and the embedded
  /// fallback. Fire-and-forget for callers that don't care.
  Future<bool> publishGame(Game game) async {
    if (!_enabled) return false;
    final uid = await IdentityService.instance.uid();
    if (uid == null) return false;
    try {
      await _firestore!.collection('games').doc(game.id).set({
        ...game.toMap(),
        'hostUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('GameSyncService.publishGame error: $e');
      return false;
    }
  }

  /// Stream of all currently-published games. Used by the browse screen so
  /// users can discover games hosted on other devices. Returns an empty
  /// stream if Firestore is unavailable.
  Stream<List<Game>> streamAllGames() {
    if (!_enabled) return const Stream.empty();
    try {
      return _firestore!
          .collection('games')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) {
        final games = <Game>[];
        for (final d in snap.docs) {
          try {
            games.add(Game.fromMap(_sanitize(d.data())));
          } catch (_) {
            // Skip malformed docs rather than failing the whole stream.
          }
        }
        return games;
      }).handleError((e) {
        debugPrint('GameSyncService.streamAllGames error: $e');
      });
    } catch (e) {
      debugPrint('GameSyncService.streamAllGames setup error: $e');
      return const Stream.empty();
    }
  }

  /// Fetch a previously-published game by id. Used by the deep-link receiver
  /// when the URL carries only `?id=…` instead of an embedded payload.
  Future<Game?> fetchGame(String gameId) async {
    if (!_enabled) return null;
    try {
      final snap = await _firestore!.collection('games').doc(gameId).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return Game.fromMap(_sanitize(data));
    } catch (e) {
      debugPrint('GameSyncService.fetchGame error: $e');
      return null;
    }
  }

  /// Submit a join request. Writes to `games/{gameId}/requests/{requesterUid}`.
  /// The host's listener will pick it up and merge it into their local
  /// requests state. [joiner] is captured as a snapshot so the host can show
  /// the requester's name / avatar / level without needing a user lookup.
  Future<bool> requestJoin({
    required String gameId,
    required Player joiner,
    String note = '',
  }) async {
    if (!_enabled) return false;
    final uid = await IdentityService.instance.uid();
    if (uid == null) return false;
    try {
      await _firestore!
          .collection('games')
          .doc(gameId)
          .collection('requests')
          .doc(uid)
          .set({
        'userId': uid,
        'playerSnapshot': joiner.toMap(),
        'note': note,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('GameSyncService.requestJoin error: $e');
      return false;
    }
  }

  /// Stream of pending requests for [gameId]. The host subscribes to this
  /// for each game they've hosted; emissions get merged into AppController's
  /// local requests map. Yields an empty stream if Firestore is unavailable.
  Stream<List<RemoteJoinRequest>> streamRequestsForGame(String gameId) {
    if (!_enabled) return const Stream.empty();
    try {
      return _firestore!
          .collection('games')
          .doc(gameId)
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => RemoteJoinRequest.fromMap(d.id, d.data()))
              .toList())
          .handleError((e) {
        debugPrint('GameSyncService.streamRequestsForGame error: $e');
      });
    } catch (e) {
      debugPrint('GameSyncService.streamRequestsForGame setup error: $e');
      return const Stream.empty();
    }
  }

  /// Stream the status of *my* request for [gameId] (i.e. the doc keyed by
  /// this device's IdentityService uid). Emits the latest status string
  /// ('pending' | 'approved' | 'declined') or null if the doc doesn't exist.
  /// The joiner's app subscribes for each pending booking so it can react
  /// when the host approves/declines from another device.
  Stream<String?> streamMyRequestStatus(String gameId) async* {
    if (!_enabled) {
      return;
    }
    final uid = await IdentityService.instance.uid();
    if (uid == null) return;
    try {
      yield* _firestore!
          .collection('games')
          .doc(gameId)
          .collection('requests')
          .doc(uid)
          .snapshots()
          .map((d) => d.data()?['status'] as String?)
          .handleError((e) {
        debugPrint('GameSyncService.streamMyRequestStatus error: $e');
      });
    } catch (e) {
      debugPrint('GameSyncService.streamMyRequestStatus setup error: $e');
    }
  }

  /// Mark a request as approved/declined. Caller passes the request's userId
  /// (the requester's IdentityService uid). The remote document is updated
  /// so the requester's app sees the new status on its own listener.
  Future<bool> updateRequestStatus({
    required String gameId,
    required String requesterUid,
    required String status, // 'approved' | 'declined'
  }) async {
    if (!_enabled) return false;
    try {
      await _firestore!
          .collection('games')
          .doc(gameId)
          .collection('requests')
          .doc(requesterUid)
          .update({'status': status});
      return true;
    } catch (e) {
      debugPrint('GameSyncService.updateRequestStatus error: $e');
      return false;
    }
  }

  /// Firestore allows nested Maps but Dart's `Map<String, dynamic>` may
  /// contain `Timestamp` and other native types that Game.fromMap doesn't
  /// know about — strip them so the model stays string/num/list/bool only.
  Map<String, dynamic> _sanitize(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((k, v) {
      if (v is Timestamp) return; // skip server timestamps
      out[k] = v;
    });
    return out;
  }
}

/// Server-side join request, enriched with the requester's profile snapshot.
/// Maps onto `JoinRequest` for in-app display, but carries extra info that
/// the in-memory `JoinRequest` doesn't model.
class RemoteJoinRequest {
  const RemoteJoinRequest({
    required this.userId,
    required this.note,
    required this.playerSnapshot,
    required this.status,
  });

  final String userId;
  final String note;
  final Player? playerSnapshot;
  final String status;

  factory RemoteJoinRequest.fromMap(String docId, Map<String, dynamic> data) {
    Player? snap;
    final raw = data['playerSnapshot'];
    if (raw is Map) {
      try {
        snap = Player.fromMap(Map<String, dynamic>.from(raw));
      } catch (_) {
        snap = null;
      }
    }
    return RemoteJoinRequest(
      userId: data['userId'] as String? ?? docId,
      note: data['note'] as String? ?? '',
      playerSnapshot: snap,
      status: data['status'] as String? ?? 'pending',
    );
  }

  /// Adapter to the in-memory JoinRequest shape so AppController can store it
  /// in the existing `requests` map without changing every consumer.
  JoinRequest toLocal() => JoinRequest(
        userId: userId,
        when: 'just now',
        note: note,
      );
}
