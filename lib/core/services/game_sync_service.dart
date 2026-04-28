import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart' show ChatMessage, JoinRequest;
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

  /// Deletes a previously-published game and all its pending requests.
  /// Called by the host when they cancel the match — joiners' devices
  /// stop seeing it on their next stream tick.
  Future<bool> deleteGame(String gameId) async {
    if (!_enabled) return false;
    try {
      // Best-effort: clear pending requests first so streamed listeners
      // don't briefly emit an empty parent + ghost subcollection.
      final requests = await _firestore!
          .collection('games')
          .doc(gameId)
          .collection('requests')
          .get();
      for (final d in requests.docs) {
        await d.reference.delete();
      }
      await _firestore!.collection('games').doc(gameId).delete();
      return true;
    } catch (e) {
      debugPrint('GameSyncService.deleteGame error: $e');
      return false;
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

  // ─── Chat ────────────────────────────────────────────────────────────────

  /// Push a chat message into a game's thread. The local AppController
  /// also keeps a copy in its `gameChats` map so the sender sees the
  /// message immediately even before Firestore round-trips back.
  Future<bool> sendGameMessage({
    required String gameId,
    required ChatMessage message,
    required String fromUid,
  }) async {
    if (!_enabled) return false;
    try {
      await _firestore!
          .collection('games')
          .doc(gameId)
          .collection('messages')
          .add({
        'fromUid': fromUid,
        'text': message.text,
        't': message.t,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('GameSyncService.sendGameMessage error: $e');
      return false;
    }
  }

  /// Stream every message for a game's thread, oldest first. The
  /// `fromUid` field is rewritten to `'me'` when it matches [myUid] so
  /// the existing `ChatMessage.from == 'me'` rendering keeps working.
  Stream<List<ChatMessage>> streamGameMessages({
    required String gameId,
    required String myUid,
  }) {
    if (!_enabled) return const Stream.empty();
    try {
      return _firestore!
          .collection('games')
          .doc(gameId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snap) {
        final out = <ChatMessage>[];
        for (final d in snap.docs) {
          final data = d.data();
          final from = (data['fromUid'] as String?) ?? '';
          out.add(ChatMessage(
            from: from == myUid ? 'me' : from,
            text: (data['text'] as String?) ?? '',
            t: (data['t'] as String?) ?? '',
          ));
        }
        return out;
      }).handleError((e) {
        debugPrint('GameSyncService.streamGameMessages error: $e');
      });
    } catch (e) {
      debugPrint('GameSyncService.streamGameMessages setup error: $e');
      return const Stream.empty();
    }
  }

  /// Conversation id for a DM between [a] and [b] — sorted so both
  /// parties resolve the same key regardless of who's calling.
  static String dmConversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Future<bool> sendDmMessage({
    required String conversationId,
    required ChatMessage message,
    required String fromUid,
  }) async {
    if (!_enabled) return false;
    try {
      await _firestore!
          .collection('dms')
          .doc(conversationId)
          .collection('messages')
          .add({
        'fromUid': fromUid,
        'text': message.text,
        't': message.t,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('GameSyncService.sendDmMessage error: $e');
      return false;
    }
  }

  Stream<List<ChatMessage>> streamDmMessages({
    required String conversationId,
    required String myUid,
  }) {
    if (!_enabled) return const Stream.empty();
    try {
      return _firestore!
          .collection('dms')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snap) {
        final out = <ChatMessage>[];
        for (final d in snap.docs) {
          final data = d.data();
          final from = (data['fromUid'] as String?) ?? '';
          out.add(ChatMessage(
            from: from == myUid ? 'me' : from,
            text: (data['text'] as String?) ?? '',
            t: (data['t'] as String?) ?? '',
          ));
        }
        return out;
      }).handleError((e) {
        debugPrint('GameSyncService.streamDmMessages error: $e');
      });
    } catch (e) {
      debugPrint('GameSyncService.streamDmMessages setup error: $e');
      return const Stream.empty();
    }
  }

  // ─── Friend requests ─────────────────────────────────────────────────────
  // Layout: `users/{uid}/friends/{otherUid}` — symmetric pair, one entry
  // on each side. Sender writes their own outgoing copy + the recipient's
  // incoming copy in a single batch so both devices light up the same
  // moment.

  Future<bool> sendFriendRequest({
    required String myUid,
    required Player mySnapshot,
    required String theirUid,
    Player? theirSnapshot,
  }) async {
    if (!_enabled) return false;
    try {
      final batch = _firestore!.batch();
      final mineRef = _firestore!
          .collection('users').doc(myUid)
          .collection('friends').doc(theirUid);
      final theirsRef = _firestore!
          .collection('users').doc(theirUid)
          .collection('friends').doc(myUid);
      batch.set(mineRef, {
        'status': 'pending_out',
        'otherUid': theirUid,
        'otherSnapshot': theirSnapshot?.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(theirsRef, {
        'status': 'pending_in',
        'otherUid': myUid,
        'otherSnapshot': mySnapshot.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('GameSyncService.sendFriendRequest error: $e');
      return false;
    }
  }

  Future<bool> acceptFriendRequest({
    required String myUid,
    required Player mySnapshot,
    required String theirUid,
  }) async {
    if (!_enabled) return false;
    try {
      final batch = _firestore!.batch();
      final mineRef = _firestore!
          .collection('users').doc(myUid)
          .collection('friends').doc(theirUid);
      final theirsRef = _firestore!
          .collection('users').doc(theirUid)
          .collection('friends').doc(myUid);
      batch.set(mineRef, {
        'status': 'friends',
        'otherUid': theirUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(theirsRef, {
        'status': 'friends',
        'otherUid': myUid,
        'otherSnapshot': mySnapshot.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('GameSyncService.acceptFriendRequest error: $e');
      return false;
    }
  }

  Future<bool> removeFriend({
    required String myUid,
    required String theirUid,
  }) async {
    if (!_enabled) return false;
    try {
      final batch = _firestore!.batch();
      batch.delete(_firestore!
          .collection('users').doc(myUid)
          .collection('friends').doc(theirUid));
      batch.delete(_firestore!
          .collection('users').doc(theirUid)
          .collection('friends').doc(myUid));
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('GameSyncService.removeFriend error: $e');
      return false;
    }
  }

  /// Stream of every friend entry for [myUid] — incoming requests,
  /// outgoing requests, and confirmed friends. The other party's profile
  /// is included as a snapshot so the recipient can render the request
  /// without a separate user lookup.
  Stream<List<RemoteFriendEntry>> streamMyFriends(String myUid) {
    if (!_enabled) return const Stream.empty();
    try {
      return _firestore!
          .collection('users').doc(myUid)
          .collection('friends')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => RemoteFriendEntry.fromMap(d.id, d.data()))
              .toList())
          .handleError((e) {
        debugPrint('GameSyncService.streamMyFriends error: $e');
      });
    } catch (e) {
      debugPrint('GameSyncService.streamMyFriends setup error: $e');
      return const Stream.empty();
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

/// Remote friend entry as stored under `users/{me}/friends/{them}`.
class RemoteFriendEntry {
  const RemoteFriendEntry({
    required this.otherUid,
    required this.status,
    this.otherSnapshot,
  });

  final String otherUid;
  final String status; // 'pending_in' | 'pending_out' | 'friends'
  final Player? otherSnapshot;

  factory RemoteFriendEntry.fromMap(String docId, Map<String, dynamic> data) {
    Player? snap;
    final raw = data['otherSnapshot'];
    if (raw is Map) {
      try {
        snap = Player.fromMap(Map<String, dynamic>.from(raw));
      } catch (_) {
        snap = null;
      }
    }
    return RemoteFriendEntry(
      otherUid: data['otherUid'] as String? ?? docId,
      status: data['status'] as String? ?? 'friends',
      otherSnapshot: snap,
    );
  }
}
