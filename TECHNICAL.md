# Padel Partner — Technical Structure

This document describes how the codebase is organised and how data flows through the app. For setup instructions see [`SETUP.md`](SETUP.md). For outstanding work see [`TODO.md`](TODO.md).

---

## Folder layout

```
lib/
├── main.dart                       Entry — Firebase init, persisted user load,
│                                   identity bootstrap, GetX wiring
│
├── firebase_options.dart           FlutterFire-generated platform config
│
├── app/
│   ├── app_pages.dart               GetPage list — declarative route table
│   ├── routes.dart                  Route name constants
│   └── controllers/
│       └── app_controller.dart      Single source of truth: user, bookings,
│                                    friends, requests, chats, hosted games,
│                                    Firestore subscriptions, court positions
│
├── core/
│   ├── mock_data.dart               kMe, kRemotePlayers, playerById,
│   │                                Pakistan cities/areas
│   │
│   ├── models/
│   │   ├── player.dart              Profile (id, handle, level, tier, tags,
│   │   │                            isPro, …)
│   │   ├── game.dart                Hosted game (host, schedule, cost,
│   │   │                            playerIds, hostSnapshot, playerSnapshots)
│   │   ├── booking.dart             Booking + JoinRequest + ChatMessage
│   │   ├── friend.dart              FriendEntry + Subscription
│   │   └── game_time.dart           Time-of-day helpers (hasStarted, etc.)
│   │
│   ├── services/
│   │   ├── auth_service.dart        Thin Firebase Auth wrapper (anonymous)
│   │   ├── identity_service.dart    Sync UID resolver — override / Firebase /
│   │   │                            per-install UUID
│   │   ├── user_storage.dart        SharedPreferences: active session +
│   │   │                            email-keyed registry + email→uid map +
│   │   │                            seed users
│   │   ├── state_storage.dart       Persists hostedGames + bookings
│   │   ├── game_sync_service.dart   ALL Firestore I/O lives here (games,
│   │   │                            requests, chat, friends)
│   │   ├── billing_service.dart     In-app purchase listener (Pro)
│   │   ├── deep_link_service.dart   padelpartner://join?d=… handler
│   │   └── email_otp_service.dart   4-digit code generation + email send
│   │
│   ├── theme/
│   │   └── tokens.dart              AppColors, AppFonts, kBorderRadiusPill
│   │
│   └── widgets/
│       ├── avatar_widget.dart       Player avatar (initials + photo overlay)
│       ├── ball_widget.dart         Tennis-ball decoration
│       ├── chip_widget.dart         Variant pills + LevelBadge
│       ├── court_diagram.dart       2v2 court with slot avatars (1–4 slots)
│       ├── floating_nav.dart        Bottom nav (Home/Browse/Host/Chat/Me)
│       ├── game_card.dart           Open-court list card
│       ├── pp_button.dart           Primary button
│       ├── pp_logo.dart             Branding mark
│       ├── ad_banner.dart           Trial / upgrade banner
│       └── verified_tick.dart       Gold checkmark for Pro users
│
└── screens/
    ├── sign_up/                     4-step: info → OTP → profile → tags
    ├── sign_in/                     Email lookup → OTP → restore
    ├── home/                        Hero, upcoming, quick actions, feed
    ├── browse/                      All open courts (filters)
    ├── detail/                      Game detail + line-up + edit + chat CTA
    ├── host/                        4-step host wizard (court → time → vibe →
    │                                review)
    ├── requests/                    Approve / decline incoming requests
    ├── join/                        Confirmation after auto-approve
    ├── inbox/                       Threads list (game chats + DMs)
    ├── chat/                        Single thread (text + Firestore stream)
    ├── friends/                     Friends / Requests / Suggested tabs
    ├── profile/                     Stats / History / Partners + settings
    │                                menu (Friends, Requests, Sign out)
    ├── edit_profile/                Photo, name, handle, email, city, bio
    ├── subscription/                Pro paywall + IAP entry
    └── match_finished/              Post-game summary
```

---

## State management — GetX + reactive Rx

Everything global lives on `AppController` (`lib/app/controllers/app_controller.dart`). It's `Get.put`-ed permanently in `main.dart` and accessed everywhere as `AppController.to`.

### Reactive collections

| Field             | Type                              | Purpose                                             |
|-------------------|-----------------------------------|-----------------------------------------------------|
| `currentUser`     | `Rx<Player>`                       | Active user, mirrors `kMe`                          |
| `bookings`        | `RxList<Booking>`                  | My bookings — pending / confirmed / hosting         |
| `friends`         | `RxList<FriendEntry>`              | My friends + incoming/outgoing requests             |
| `requests`        | `RxMap<String, List<JoinRequest>>` | gameId → pending join requests (host's view)        |
| `gameChats`       | `RxMap<String, List<ChatMessage>>` | gameId → messages (synced via Firestore)            |
| `friendChats`     | `RxMap<String, List<ChatMessage>>` | friendUid → DM messages                             |
| `hostedGames`     | `RxList<Game>`                     | Games this user has hosted                          |
| `remoteGames`     | `RxList<Game>`                     | Live feed of all published games (Firestore stream) |
| `subscription`    | `Rx<Subscription>`                 | Trial / Pro plan state                              |
| `courtPositions`  | `RxMap<String, Map<String, int>>`  | gameId → (uid → slot 0..3) — host-assigned line-up  |

UI reads via `Obx(() => …)` which auto-rebuilds when any read Rx changes.

### Persistence layers

There are three layers, each with a distinct purpose:

1. **In-memory (Rx)** — lives only while the app is running.
2. **SharedPreferences** (`UserStorage`, `StateStorage`) — survives app kill, scoped to this install.
3. **Firestore** (`GameSyncService`) — survives anything, syncs across devices.

`AppController._hydrate()` rebuilds the in-memory state from SharedPreferences on launch, then Firestore listeners reconcile it with the cloud authority.

---

## Identity model — three layers

This is the trickiest part of the codebase, so it's worth understanding clearly:

| Layer                | Value                          | Used for                                                |
|----------------------|--------------------------------|---------------------------------------------------------|
| `kMe.id`             | Always the literal `'me'`      | Local comparisons inside the app (host slot, "is mine?")|
| `IdentityService.uid`| Stable cross-device UID        | Firestore writes (game ownership, request authorship)   |
| `Player.email`       | The user-typed email           | Sign-in / account lookup / registry key                 |

`kMe.id == 'me'` on every device — this is intentional. It keeps "is this me?" checks simple. The price is that any cross-device check must use the IdentityService UID instead of `kMe.id`.

### IdentityService UID resolution

```
override (per-email pin)  →  Firebase Auth UID  →  per-install UUID
```

- **Override** is set at sign-in / sign-up from `UserStorage.getUidForEmail(email)`. This is what makes the same email always resolve to the same identity across sign-out/sign-in cycles.
- **Firebase UID** is the anonymous-auth UID. New on every fresh sign-in unless the override pins it.
- **Per-install UUID** is the legacy fallback for offline / unconfigured environments.

### Demo accounts

Two emails get hard-coded UIDs by `UserStorage.ensureSeedUsers()`:

```
manooazad@gmail.com   → demo_manoo_uid
taqiratnani@hotmail.com → demo_taqi_uid
```

This means a friend request sent to `manooazad@gmail.com` from any device always writes to `users/demo_manoo_uid/friends/...` — so the host receives it regardless of which device they sign in on.

---

## Firestore schema

```
games/{gameId}                              Game.toMap() + hostUid + createdAt
   ├─ requests/{requesterUid}              JoinRequest with playerSnapshot
   └─ messages/{auto-id}                   Chat message {fromUid, text, t}

dms/{conversationId}                        conversationId = sorted(a,b).join('__')
   └─ messages/{auto-id}                   {fromUid, text, t}

users/{uid}/friends/{otherUid}              {status, otherUid, otherSnapshot}
                                            status ∈ {pending_in, pending_out, friends}
```

### Snapshots-on-write pattern

Several documents embed a `Player` snapshot (e.g. `hostSnapshot` on a game, `playerSnapshot` on a join request, `otherSnapshot` on a friend entry). This is intentional:

- Receiving devices have no way to look up an arbitrary user — there's no `users/{uid}` profile collection yet.
- Embedding the snapshot at write time lets every reader render the right name/avatar/level without a round-trip.
- The price is staleness: if you change your name, old games / requests still show your old name. Acceptable for MVP; revisit when a global user collection lands.

### Player resolution flow

`playerById(uid)` (in `mock_data.dart`) resolves a UID to a `Player`:

```
if uid == kMe.id → return kMe              (always 'me')
if uid in kPlayers → return that            (currently empty)
return kRemotePlayers[uid]                  (populated by listeners)
```

`kRemotePlayers` is hydrated from three sources:

1. **Firestore request listener** — when a request comes in, `_onRemoteRequestsChanged` registers the requester's snapshot.
2. **Friends stream** — when a friend entry arrives, `_mergeRemoteFriends` registers the other party's snapshot.
3. **Hydrate on launch** — `Game.playerSnapshots` (persisted on each hosted game) is replayed into `kRemotePlayers`. This is what makes the host's line-up picker work after an app restart.

---

## Cross-device flows — end-to-end

### Hosting a game

```
[Host device]
  HostController.publish()
    → AppController.addHostedGame(game)
      → adds to hostedGames + bookings (status='hosting')
      → setCourtPosition(gameId, hostId, 0)   # pre-place host on slot 0
      → GameSyncService.publishGame(stamped)  # writes games/{id}
        → ever<List<Game>> persists to StateStorage

[Player device]
  GameSyncService.streamAllGames() emits
    → AppController.remoteGames updated
    → Home / Browse rebuild via Obx
```

### Player requests to join

```
[Player device]
  AppController.requestJoin(gameId)
    → bookings.add(Booking('pending'))
    → GameSyncService.requestJoin(gameId, joiner=currentUser.value)
      → games/{gameId}/requests/{playerUid}.set({playerSnapshot, …})

[Host device]
  GameSyncService.streamRequestsForGame(gameId) emits
    → AppController._onRemoteRequestsChanged
      → registerRemotePlayer(snapshot)  # so playerById(uid) resolves
      → requests[gameId] updated
    → Requests screen + Home badge rebuild
```

### Host approves

```
[Host device]
  AppController.approveJoin(gameId, playerUid)
    → requests filtered, bookings flipped to 'confirmed'
    → game.copyWith(playerIds: [+uid], spots: -1, playerSnapshots: [+snapshot])
    → publishGame(updated)
    → updateRequestStatus(approved)

[Player device]
  GameSyncService.streamMyRequestStatus(gameId) emits 'approved'
    → AppController._onMyRequestStatusChanged
      → bookings[idx].status = 'confirmed'
      → toast: "You're in!"
```

### Chat (game thread)

```
[Either device]
  ChatScreen.initState()
    → AppController.ensureChatSubscribed(gameId)

  on send:
    AppController.sendGameMessage(gameId, text)
      → gameChats[gameId].add(local copy)        # immediate echo
      → GameSyncService.sendGameMessage(...)      # writes Firestore

  Firestore listener (running on every device with a confirmed booking):
    → streamGameMessages emits the full thread, sorted by createdAt
    → gameChats[gameId] = remote               # authoritative ordering
```

### Friend request

```
[Sender]
  AppController.addFriend(theirUid)
    → friends.add(FriendEntry(pending_out))
    → sendFriendRequest(myUid, theirUid)
      → batch write:
         users/{me}/friends/{them}      status=pending_out
         users/{them}/friends/{me}      status=pending_in, otherSnapshot=me

[Recipient]
  streamMyFriends(myUid) emits the new pending_in entry
    → _mergeRemoteFriends merges into local friends list
    → Friends screen "Requests" tab shows the request

  on accept:
    AppController.approveFriend(theirUid)
      → friends[idx].status = 'friends'
      → acceptFriendRequest:
         users/{me}/friends/{them}      status=friends (merge)
         users/{them}/friends/{me}      status=friends (merge)

  ever<friends> watcher kicks in:
    _ensureDmChatSub(theirUid) → subscribes to dms/{conversationId}/messages
```

---

## Routing

Every screen is registered in `lib/app/app_pages.dart` with a string constant from `lib/app/routes.dart`. Navigation:

```dart
Get.toNamed(Routes.detail, arguments: game);   // push
Get.offAllNamed(Routes.home);                   // replace stack
Get.back();                                      // pop
```

Arguments are read with `Get.arguments` inside the destination screen.

### Initial route

```dart
runApp(PadelPartnerApp(
  initialRoute: saved != null ? Routes.home : Routes.signUp,
));
```

A user with a saved profile lands on Home; first launch lands on Sign Up.

---

## Theming

All colours, fonts, and shape constants come from `lib/core/theme/tokens.dart`:

```dart
AppColors.blue900    // primary dark
AppColors.ball       // accent yellow-green
AppColors.ink        // body text
AppFonts.display(…)  // headers
AppFonts.body(…)     // body copy
AppFonts.mono(…)     // labels / metadata
kBorderRadiusPill    // 999
```

Component widgets (`PPChip`, `LevelBadge`, `AvatarWidget`, etc.) compose these tokens. Avoid using raw `Color(0x…)` or `TextStyle(…)` outside `tokens.dart`.

---

## Sign-out semantics

```dart
AppController.signOut()
  → UserStorage.clear()                 # removes active session
  → StateStorage.clearAll()             # hosted games + bookings
  → AuthService.signOut()               # Firebase anonymous sign-out
  → IdentityService.setOverrideUid(null)
  → cancel friends / chat subscriptions
  → clear all Rx collections
  → reset currentUser to default placeholder
  → Get.offAllNamed(Routes.signUp)
```

The email-keyed registry in `UserStorage` is **not** cleared — that's what makes signing back in with the same email restore the same profile. The email→UID map is also preserved so the same identity persists across sign-out cycles.

---

## Graceful degradation

`GameSyncService` is the only place that talks to Firestore, and every method returns a safe default (false / null / empty stream) on any failure. If Firebase isn't initialised (web, network down, missing config), the app falls back to in-memory + SharedPreferences and behaves exactly like a single-device app. No exceptions surface to the UI.

---

## Conventions

- **Files**: snake_case (`court_diagram.dart`)
- **Classes**: PascalCase (`CourtDiagram`)
- **Private members**: `_camelCase`
- **Reactive types**: `Rx<T>`, `RxList<T>`, `RxMap<K,V>` (GetX)
- **Async**: `async/await`, never block the main isolate
- **Nullable everywhere external** comes in (`m['x'] as String?`); coerce at the boundary, then trust internally
- **Comments**: only when the WHY is non-obvious. Don't restate what the code says
