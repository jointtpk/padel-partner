import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/models/booking.dart';
import '../../core/models/friend.dart';
import '../../core/models/game.dart';
import '../../core/models/player.dart';
import '../../core/mock_data.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/game_sync_service.dart';
import '../../core/services/identity_service.dart';
import '../../core/services/state_storage.dart';
import '../../core/services/user_storage.dart';
import '../../core/theme/tokens.dart';
import '../routes.dart';

class AppController extends GetxController {
  static AppController get to => Get.find();

  final currentUser  = Rx<Player>(kMe);
  final bookings     = <Booking>[].obs;
  final friends      = <FriendEntry>[].obs;
  final requests     = <String, List<JoinRequest>>{}.obs;
  final gameChats    = <String, List<ChatMessage>>{}.obs;
  final friendChats  = <String, List<ChatMessage>>{}.obs;
  final hostedGames  = <Game>[].obs;
  final subscription = const Subscription(plan: 'trial', daysLeft: 23).obs;

  /// Live feed of all games published to Firestore (from any device).
  /// Used by home's "Open courts" and the browse screen so games hosted
  /// elsewhere are discoverable. Empty when Firestore is unavailable.
  final remoteGames = <Game>[].obs;
  StreamSubscription<List<Game>>? _remoteGamesSub;

  /// Per-game court position claims: gameId -> { userId: slotIndex (0..3) }.
  /// A user can only hold one slot per game; a slot can only hold one user.
  final courtPositions = <String, Map<String, int>>{}.obs;

  /// Claim [slot] (0..3) on [gameId] for [userId]. No-op if the slot is
  /// already taken by someone else; otherwise releases any prior claim.
  void claimCourtPosition(String gameId, String userId, int slot) {
    final cur = Map<String, int>.from(courtPositions[gameId] ?? const {});
    String? occupantId;
    cur.forEach((k, v) {
      if (v == slot) occupantId = k;
    });
    if (occupantId != null && occupantId != userId) return;
    cur.removeWhere((k, _) => k == userId);
    cur[userId] = slot;
    courtPositions[gameId] = cur;
    courtPositions.refresh();
  }

  /// Host-side assignment: place [userId] on [slot], displacing whoever was
  /// there. Unlike [claimCourtPosition] this overrides existing claims —
  /// only call when the host explicitly picks a player for a slot.
  void setCourtPosition(String gameId, String userId, int slot) {
    final cur = Map<String, int>.from(courtPositions[gameId] ?? const {});
    cur.removeWhere((_, v) => v == slot);
    cur.removeWhere((k, _) => k == userId);
    cur[userId] = slot;
    courtPositions[gameId] = cur;
    courtPositions.refresh();
  }

  /// Clears whatever player is on [slot] for [gameId]. Used by the host
  /// when reassigning positions.
  void clearCourtSlot(String gameId, int slot) {
    final cur = Map<String, int>.from(courtPositions[gameId] ?? const {});
    cur.removeWhere((_, v) => v == slot);
    courtPositions[gameId] = cur;
    courtPositions.refresh();
  }

  void updateCurrentUser({
    String? name,
    String? handle,
    String? email,
    String? bio,
    String? photoPath,
    String? city,
    int? age,
    String? gender,
    Map<String, String>? tags,
  }) {
    final cur = currentUser.value;
    final newName = name ?? cur.name;
    final next = cur.copyWith(
      name: newName,
      handle: handle ?? cur.handle,
      email: email ?? cur.email,
      bio: bio ?? cur.bio,
      photoPath: photoPath ?? cur.photoPath,
      city: city ?? cur.city,
      age: age ?? cur.age,
      gender: gender ?? cur.gender,
      tags: tags ?? cur.tags,
      initials: _initialsOf(newName),
    );
    currentUser.value = next;
    kMe = next; // keep top-level kMe in sync for legacy non-reactive reads
    UserStorage.save(next);
  }

  /// Clears all local user state and returns to the sign-up screen.
  Future<void> signOut() async {
    await UserStorage.clear();
    await StateStorage.clearAll();
    await AuthService.instance.signOut();
    IdentityService.instance.setOverrideUid(null);
    // Tear down per-account subscriptions so the next account's
    // streams don't merge with the previous one's data.
    await _friendsSub?.cancel();
    _friendsSub = null;
    for (final s in _gameChatSubs.values) {
      await s.cancel();
    }
    _gameChatSubs.clear();
    for (final s in _dmChatSubs.values) {
      await s.cancel();
    }
    _dmChatSubs.clear();
    bookings.clear();
    friends.clear();
    requests.clear();
    gameChats.clear();
    friendChats.clear();
    hostedGames.clear();
    currentUser.value = const Player(
      id: 'me',
      name: 'You',
      handle: '@you',
      level: 1.0,
      tier: 'rookie',
      badge: 'Rookie',
      avatarColor: Color(0xFFD5C7FF),
      initials: 'YO',
      city: '',
      wins: 0,
      games: 0,
      age: 0,
      gender: 'M',
    );
    kMe = currentUser.value;
    Get.offAllNamed(Routes.signUp);
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Match phase for demo: 'upcoming' | 'reminder_30' | 'reminder_15' | 'finished'
  final matchPhase = 'upcoming'.obs;

  /// Active Firestore listeners for hosted games' join requests, keyed by
  /// gameId. Cleaned up if the game is ever removed.
  final _requestSubs = <String, StreamSubscription>{};

  /// Active Firestore listeners for *my* pending bookings (joiner side).
  /// Keyed by gameId; cancelled once the booking leaves the 'pending' state.
  final _bookingSubs = <String, StreamSubscription>{};

  @override
  void onInit() {
    super.onInit();
    bookings.addAll(kInitialBookings);
    friends.addAll(kInitialFriends);
    requests.addAll(kInitialRequests);
    gameChats.addAll(kInitialGameChats);
    friendChats.addAll(kInitialFriendChats);
    // Restore persisted gameplay state (hosted games, bookings) before
    // wiring listeners so the watchers fire once with the rehydrated set
    // and (re-)attach Firestore listeners for them.
    _hydrate();
    // Host side: listen for incoming requests on each hosted game.
    ever<List<Game>>(hostedGames, _syncRequestSubs);
    // Joiner side: listen for the host's approve/decline on each pending
    // booking the user has submitted.
    ever<List<Booking>>(bookings, _syncBookingSubs);
    // Persist on every change so we never lose state if the app is killed.
    ever<List<Game>>(hostedGames, (g) => StateStorage.saveHostedGames(g));
    ever<List<Booking>>(bookings, (b) => StateStorage.saveBookings(b));
    // Auto-subscribe to chat for every hosted game and every confirmed
    // booking so the inbox unread badge stays accurate even before the
    // user opens the chat screen.
    ever<List<Game>>(hostedGames, (games) {
      for (final g in games) _ensureGameChatSub(g.id);
    });
    ever<List<Booking>>(bookings, (bs) {
      for (final b in bs) {
        if (b.status == 'confirmed' || b.status == 'hosting') {
          _ensureGameChatSub(b.gameId);
        }
      }
    });
    ever<List<FriendEntry>>(friends, (entries) {
      for (final f in entries) {
        if (f.status == 'friends') _ensureDmChatSub(f.userId);
      }
    });
    // Mirror Pro subscription state onto the current user's player profile
    // so the gold verified tick is reflected wherever Player is rendered
    // (own profile, host card, request rows on other devices via the
    // playerSnapshot).
    ever<Subscription>(subscription, _syncProBadge);
    // Apply the initial value too in case sub starts as Pro (e.g. restored).
    _syncProBadge(subscription.value);
    // Friend list / friend requests feed. Resolves identity first so the
    // subscription is keyed by a real uid; on slow networks falls back
    // to the cached value once the timeout in IdentityService expires.
    () async {
      await IdentityService.instance.uid();
      _ensureFriendsSub();
    }();
    // Live Firestore games feed (shared by home + browse).
    _remoteGamesSub = GameSyncService.instance.streamAllGames().listen((games) {
      // Register any joiner snapshots embedded in remote games so the
      // line-up picker / court diagram can resolve them by uid on every
      // device — not just the host's.
      for (final g in games) {
        for (final entry in g.playerSnapshots.entries) {
          registerRemotePlayer(entry.value.copyWith(id: entry.key));
        }
        if (g.hostSnapshot != null && g.hostUid != null) {
          registerRemotePlayer(g.hostSnapshot!.copyWith(id: g.hostUid!));
        }
      }
      remoteGames.assignAll(games);
    });
  }

  void _syncProBadge(Subscription sub) {
    final isPro = sub.plan == 'pro';
    if (currentUser.value.isPro == isPro) return;
    final next = currentUser.value.copyWith(isPro: isPro);
    currentUser.value = next;
    kMe = next;
    UserStorage.save(next);
  }

  Future<void> _hydrate() async {
    final games = await StateStorage.loadHostedGames();
    if (games.isNotEmpty) {
      hostedGames.addAll(games);
      // Re-register persisted joiner snapshots into kRemotePlayers so the
      // line-up picker / court diagram can resolve them by uid even
      // before the Firestore stream reconnects.
      for (final g in games) {
        for (final entry in g.playerSnapshots.entries) {
          registerRemotePlayer(entry.value.copyWith(id: entry.key));
        }
      }
    }
    final saved = await StateStorage.loadBookings();
    if (saved.isNotEmpty) {
      // Avoid duplicating any bookings already loaded from kInitialBookings.
      final knownIds = bookings.map((b) => b.gameId).toSet();
      bookings.addAll(saved.where((b) => !knownIds.contains(b.gameId)));
    }
    // Backfill: legacy games persisted before hostUid/hostSnapshot existed
    // would otherwise show the wrong host on joiner devices. Stamp the
    // current values now and republish so Firestore catches up.
    final uid = IdentityService.instance.cached;
    final me = currentUser.value;
    for (var i = 0; i < hostedGames.length; i++) {
      final g = hostedGames[i];
      if (g.hostUid != null && g.hostSnapshot != null) continue;
      final patched = g.copyWith(
        hostUid: g.hostUid ?? uid,
        hostSnapshot: g.hostSnapshot ?? me,
      );
      hostedGames[i] = patched;
      GameSyncService.instance.publishGame(patched);
    }
  }

  /// Adds/removes Firestore request listeners to match the current
  /// `hostedGames` set. Idempotent — safe to call as often as the list emits.
  void _syncRequestSubs(List<Game> games) {
    final wantIds = games.map((g) => g.id).toSet();
    // Cancel listeners for games no longer hosted.
    final stale = _requestSubs.keys.where((id) => !wantIds.contains(id)).toList();
    for (final id in stale) {
      _requestSubs.remove(id)?.cancel();
    }
    // Add listeners for newly-added games.
    for (final id in wantIds) {
      if (_requestSubs.containsKey(id)) continue;
      _requestSubs[id] = GameSyncService.instance
          .streamRequestsForGame(id)
          .listen(
            (remote) => _onRemoteRequestsChanged(id, remote),
            onError: (e) => debugPrint('AppController request listener error: $e'),
          );
    }
  }

  /// Adds/removes Firestore listeners for the joiner's own request status,
  /// one per *pending* booking. Once a booking flips to 'confirmed' (or is
  /// removed), the listener is torn down — the watcher fires again on the
  /// resulting `bookings` change and prunes accordingly.
  void _syncBookingSubs(List<Booking> all) {
    final wantIds = all
        .where((b) => b.status == 'pending')
        .map((b) => b.gameId)
        .toSet();
    final stale = _bookingSubs.keys.where((id) => !wantIds.contains(id)).toList();
    for (final id in stale) {
      _bookingSubs.remove(id)?.cancel();
    }
    for (final id in wantIds) {
      if (_bookingSubs.containsKey(id)) continue;
      _bookingSubs[id] = GameSyncService.instance
          .streamMyRequestStatus(id)
          .listen(
            (status) => _onMyRequestStatusChanged(id, status),
            onError: (e) => debugPrint('AppController booking listener error: $e'),
          );
    }
  }

  /// React to the host's decision on this device's join request.
  void _onMyRequestStatusChanged(String gameId, String? status) {
    if (status == 'approved') {
      final idx = bookings.indexWhere((b) => b.gameId == gameId);
      if (idx >= 0 && bookings[idx].status == 'pending') {
        bookings[idx] = bookings[idx].copyWith(status: 'confirmed');
        _toast(
          "You're in!",
          'The host approved your request.',
        );
      }
    } else if (status == 'declined') {
      final idx = bookings.indexWhere((b) => b.gameId == gameId);
      if (idx >= 0 && bookings[idx].status == 'pending') {
        bookings.removeAt(idx);
        _toast(
          'Request declined',
          'The host couldn\'t fit you in this time.',
        );
      }
    }
  }

  void _toast(String title, String body) {
    Get.snackbar(
      '',
      '',
      titleText: Text(title, style: AppFonts.display(14, color: AppColors.ink)),
      messageText: Text(body,
          style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.65))),
      backgroundColor: AppColors.ball,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  /// Merge Firestore-side join requests into the local `requests` map.
  /// Existing local-only entries (other test users) are preserved by keying
  /// on userId.
  void _onRemoteRequestsChanged(String gameId, List<RemoteJoinRequest> remote) {
    // Cache requester profiles keyed by their cross-device userId so
    // `playerById(uid)` resolves them. The snapshot's own `id` is `'me'`
    // (the joiner's local kMe.id) and would collide with the host's own
    // kMe — so we re-stamp it with the requester's uid before registering.
    for (final r in remote) {
      final p = r.playerSnapshot;
      if (p != null) registerRemotePlayer(p.copyWith(id: r.userId));
    }
    // Merge: keep any local entries that aren't in the remote set; replace
    // entries that are.
    final remoteIds = remote.map((r) => r.userId).toSet();
    final existing = requests[gameId] ?? const <JoinRequest>[];
    final localOnly = existing.where((r) => !remoteIds.contains(r.userId));
    final next = <JoinRequest>[
      ...localOnly,
      ...remote.map((r) => r.toLocal()),
    ];
    requests[gameId] = next;
    requests.refresh();
  }

  // ─── Friends ───────────────────────────────────────────────────────────────
  String getFriendStatus(String uid) =>
      friends.firstWhereOrNull((f) => f.userId == uid)?.status ?? 'none';

  bool isFriend(String uid) => getFriendStatus(uid) == 'friends';

  void addFriend(String uid) {
    final cur = getFriendStatus(uid);
    if (cur == 'none') {
      friends.add(FriendEntry(userId: uid, status: 'pending_out'));
      _pushFriendRequest(uid);
    } else if (cur == 'pending_in') {
      // Accepting an inbound request — flip locally and mirror remote.
      final i = friends.indexWhere((f) => f.userId == uid);
      if (i >= 0) friends[i] = friends[i].copyWith(status: 'friends');
      _pushFriendAccept(uid);
    }
  }

  void approveFriend(String uid) {
    final i = friends.indexWhere((f) => f.userId == uid);
    if (i >= 0) friends[i] = friends[i].copyWith(status: 'friends');
    _pushFriendAccept(uid);
  }

  void removeFriend(String uid) {
    friends.removeWhere((f) => f.userId == uid);
    final myUid = IdentityService.instance.cached;
    if (myUid != null) {
      GameSyncService.instance.removeFriend(myUid: myUid, theirUid: uid);
    }
  }

  int get pendingFriendRequests =>
      friends.where((f) => f.status == 'pending_in').length;

  void _pushFriendRequest(String theirUid) {
    final myUid = IdentityService.instance.cached;
    if (myUid == null) return;
    GameSyncService.instance.sendFriendRequest(
      myUid: myUid,
      mySnapshot: currentUser.value,
      theirUid: theirUid,
      theirSnapshot: kRemotePlayers[theirUid],
    );
  }

  void _pushFriendAccept(String theirUid) {
    final myUid = IdentityService.instance.cached;
    if (myUid == null) return;
    GameSyncService.instance.acceptFriendRequest(
      myUid: myUid,
      mySnapshot: currentUser.value,
      theirUid: theirUid,
    );
  }

  /// Active subscription to my friend list in Firestore.
  StreamSubscription<List<RemoteFriendEntry>>? _friendsSub;

  /// Re-subscribes to per-account streams after a fresh sign-in. The
  /// sign-out path tears them down so the new account starts clean —
  /// without this hook the friend list (and chat) would silently stay
  /// dark after sign-in until the next app launch.
  void bootstrapPerAccountStreams() {
    _ensureFriendsSub();
    for (final g in hostedGames) {
      _ensureGameChatSub(g.id);
    }
    for (final b in bookings) {
      if (b.status == 'confirmed' || b.status == 'hosting') {
        _ensureGameChatSub(b.gameId);
      }
    }
    for (final f in friends) {
      if (f.status == 'friends') _ensureDmChatSub(f.userId);
    }
  }

  /// Subscribes (idempotently) to `users/{myUid}/friends`. Called from
  /// `onInit` once the identity is resolved so friend requests sent
  /// from another device land in the local list automatically.
  void _ensureFriendsSub() {
    if (_friendsSub != null) return;
    final myUid = IdentityService.instance.cached;
    if (myUid == null) return;
    _friendsSub = GameSyncService.instance
        .streamMyFriends(myUid)
        .listen(_mergeRemoteFriends,
            onError: (e) => debugPrint('AppController friends sub error: $e'));
  }

  void _mergeRemoteFriends(List<RemoteFriendEntry> remote) {
    // Stash any embedded profile snapshots so `playerById(theirUid)`
    // resolves them in the friends UI.
    for (final r in remote) {
      final p = r.otherSnapshot;
      if (p != null) registerRemotePlayer(p.copyWith(id: r.otherUid));
    }
    // Replace the local list with the remote authority while keeping
    // any legacy local-only entries (those with no Firestore mirror).
    final remoteUids = remote.map((r) => r.otherUid).toSet();
    final localOnly = friends.where((f) => !remoteUids.contains(f.userId));
    final next = <FriendEntry>[
      ...localOnly,
      ...remote.map((r) => FriendEntry(userId: r.otherUid, status: r.status)),
    ];
    friends.assignAll(next);
  }

  // ─── Bookings ─────────────────────────────────────────────────────────────
  String getBookingStatus(String gameId) =>
      bookings.firstWhereOrNull((b) => b.gameId == gameId)?.status ?? 'none';

  void requestJoin(String gameId) {
    bookings.removeWhere((b) => b.gameId == gameId);
    bookings.add(Booking(gameId: gameId, status: 'pending'));
    // Mirror to Firestore so the host (on another device) sees the request.
    // Fire-and-forget; failures keep the local booking state intact.
    GameSyncService.instance.requestJoin(
      gameId: gameId,
      joiner: currentUser.value,
    );
  }

  // ─── Requests ─────────────────────────────────────────────────────────────
  int get totalPendingRequests =>
      requests.values.fold(0, (sum, list) => sum + list.length);

  void approveJoin(String gameId, String uid) {
    requests[gameId] = (requests[gameId] ?? [])
        .where((r) => r.userId != uid)
        .toList();
    requests.refresh();
    // Mark booking confirmed for the user (in a real app, update Firestore)
    final idx = bookings.indexWhere((b) => b.gameId == gameId);
    if (idx >= 0) bookings[idx] = bookings[idx].copyWith(status: 'confirmed');
    // Add the approved joiner to the game's playerIds + decrement spots so
    // both the host's own UI and any remote viewer's UI see the player
    // appear in the line-up. Republishes the game so Firestore picks up
    // the change for cross-device sync.
    final gi = hostedGames.indexWhere((g) => g.id == gameId);
    if (gi >= 0) {
      final g = hostedGames[gi];
      if (!g.playerIds.contains(uid)) {
        // Stamp the joiner's snapshot onto the game so the line-up
        // survives an app restart. kRemotePlayers is in-memory; without
        // this, the host would lose the joiner's name/avatar after a
        // relaunch even though their uid is still in playerIds.
        final snapshot = kRemotePlayers[uid];
        final mergedSnapshots = Map<String, Player>.from(g.playerSnapshots);
        if (snapshot != null) mergedSnapshots[uid] = snapshot;
        final next = g.copyWith(
          playerIds: [...g.playerIds, uid],
          spots: (g.spots - 1).clamp(0, g.total),
          playerSnapshots: mergedSnapshots,
        );
        hostedGames[gi] = next;
        GameSyncService.instance.publishGame(next);
      }
    }
    // Mirror to Firestore for cross-device requests.
    GameSyncService.instance.updateRequestStatus(
      gameId: gameId,
      requesterUid: uid,
      status: 'approved',
    );
  }

  void declineJoin(String gameId, String uid) {
    requests[gameId] = (requests[gameId] ?? [])
        .where((r) => r.userId != uid)
        .toList();
    requests.refresh();
    GameSyncService.instance.updateRequestStatus(
      gameId: gameId,
      requesterUid: uid,
      status: 'declined',
    );
  }

  // ─── Chat ─────────────────────────────────────────────────────────────────

  /// Active Firestore listeners for cross-device chat threads, keyed by
  /// the local map key (gameId for game chats, friend uid for DMs).
  final _gameChatSubs = <String, StreamSubscription>{};
  final _dmChatSubs = <String, StreamSubscription>{};

  void sendGameMessage(String gameId, String text) {
    final msg = ChatMessage(from: 'me', text: text, t: _nowTime());
    final list = List<ChatMessage>.from(gameChats[gameId] ?? []);
    list.add(msg);
    gameChats[gameId] = list;
    gameChats.refresh();
    final myUid = IdentityService.instance.cached;
    if (myUid != null) {
      GameSyncService.instance.sendGameMessage(
        gameId: gameId,
        message: msg,
        fromUid: myUid,
      );
    }
    _ensureGameChatSub(gameId);
  }

  void sendFriendMessage(String uid, String text) {
    final msg = ChatMessage(from: 'me', text: text, t: _nowTime());
    final list = List<ChatMessage>.from(friendChats[uid] ?? []);
    list.add(msg);
    friendChats[uid] = list;
    friendChats.refresh();
    final myUid = IdentityService.instance.cached;
    if (myUid != null) {
      final convoId = GameSyncService.dmConversationId(myUid, uid);
      GameSyncService.instance.sendDmMessage(
        conversationId: convoId,
        message: msg,
        fromUid: myUid,
      );
    }
    _ensureDmChatSub(uid);
  }

  /// Subscribes to a game's chat thread once. Subsequent calls are
  /// no-ops. Replaces the local `gameChats[gameId]` with the server
  /// stream's authoritative ordering on each emission.
  void _ensureGameChatSub(String gameId) {
    if (_gameChatSubs.containsKey(gameId)) return;
    final myUid = IdentityService.instance.cached;
    if (myUid == null) return;
    _gameChatSubs[gameId] = GameSyncService.instance
        .streamGameMessages(gameId: gameId, myUid: myUid)
        .listen((msgs) {
      gameChats[gameId] = msgs;
      gameChats.refresh();
    }, onError: (e) => debugPrint('AppController game chat sub error: $e'));
  }

  void _ensureDmChatSub(String friendUid) {
    if (_dmChatSubs.containsKey(friendUid)) return;
    final myUid = IdentityService.instance.cached;
    if (myUid == null) return;
    final convoId = GameSyncService.dmConversationId(myUid, friendUid);
    _dmChatSubs[friendUid] = GameSyncService.instance
        .streamDmMessages(conversationId: convoId, myUid: myUid)
        .listen((msgs) {
      friendChats[friendUid] = msgs;
      friendChats.refresh();
    }, onError: (e) => debugPrint('AppController dm chat sub error: $e'));
  }

  /// Public helper for screens to bootstrap chat sync — `ChatScreen`
  /// calls this on open so it always pulls from Firestore even if the
  /// local copy is empty (e.g. fresh install).
  void ensureChatSubscribed({String? gameId, String? friendUid}) {
    if (gameId != null) _ensureGameChatSub(gameId);
    if (friendUid != null) _ensureDmChatSub(friendUid);
  }

  // ─── Host games ───────────────────────────────────────────────────────────
  void addHostedGame(Game game) {
    // Stamp the cross-device host identity *and* a snapshot of this user's
    // profile on the game so non-host devices can correctly render the
    // "Hosted by" card. Without this, `playerById(hostId)` resolves the
    // joiner's own kMe and the host card shows the wrong name/avatar.
    final uid = IdentityService.instance.cached;
    final stamped = game.copyWith(
      hostUid: uid ?? game.hostUid,
      hostSnapshot: currentUser.value,
    );
    hostedGames.add(stamped);
    bookings.add(Booking(gameId: stamped.id, status: 'hosting'));
    // Pre-place the host on slot 0 so the court diagram reflects the
    // actual occupied/open ratio from the moment the game is created.
    setCourtPosition(stamped.id, currentUser.value.id, 0);
    GameSyncService.instance.publishGame(stamped);
  }

  /// Removes a hosted game entirely: drops it from local state, deletes
  /// the matching booking, clears any court positions, and pulls it from
  /// Firestore so it disappears for joiners too.
  Future<void> cancelHostedGame(String gameId) async {
    hostedGames.removeWhere((g) => g.id == gameId);
    bookings.removeWhere((b) => b.gameId == gameId);
    requests.remove(gameId);
    courtPositions.remove(gameId);
    requests.refresh();
    courtPositions.refresh();
    _requestSubs.remove(gameId)?.cancel();
    _bookingSubs.remove(gameId)?.cancel();
    await GameSyncService.instance.deleteGame(gameId);
  }

  /// Replace a hosted game with an edited copy and republish it. Caller is
  /// responsible for only invoking this while no joiner has been confirmed
  /// yet — once a joiner is in, edits would change the deal under their
  /// feet. The detail-screen edit button enforces that gate.
  void updateHostedGame(Game updated) {
    final i = hostedGames.indexWhere((g) => g.id == updated.id);
    if (i < 0) return;
    // Keep the existing hostUid stamp through edits.
    final next = updated.hostUid != null
        ? updated
        : updated.copyWith(hostUid: hostedGames[i].hostUid);
    hostedGames[i] = next;
    GameSyncService.instance.publishGame(next);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  String _nowTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  List<Game> get myUpcomingGames {
    final booked = bookings
        .where((b) => b.status == 'confirmed')
        .map((b) {
          final g = hostedGames.firstWhereOrNull((g) => g.id == b.gameId) ??
              remoteGames.firstWhereOrNull((g) => g.id == b.gameId);
          return g != null ? (game: g, status: b.status) : null;
        })
        .whereType<({Game game, String status})>()
        .toList();

    final hosted = hostedGames
        .map((g) => (game: g, status: 'hosting'))
        .toList();

    return [
      ...booked.map((e) => e.game),
      ...hosted.map((e) => e.game),
    ];
  }
}
