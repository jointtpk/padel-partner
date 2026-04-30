# Padel Partner — TODO

Living list of outstanding work, known issues, and future scope. Updated on 2026-04-30.

Items are loosely ordered by impact. Anything blocking real users sits at the top.

---

## P0 — Blocking real-world use

- [ ] **DEPLOY THE NEW `firestore.rules`** — the file in this repo has been relaxed (any authenticated user can read/write everywhere we use). Until you push it to Firebase, cross-device sync is broken. Either:
   1. **Firebase Console** (no CLI needed): https://console.firebase.google.com/project/padelpartner-74b7d/firestore/rules → paste the contents of `firestore.rules` → **Publish**, OR
   2. **CLI**: `firebase deploy --only firestore:rules --project padelpartner-74b7d`
- [ ] **Tighten Firestore rules before production** — current rules are permissive (any authenticated user can read/write anywhere we use). The strict version (host == auth.uid, etc.) was rejecting everything because we pin a deterministic per-email sync UID that doesn't equal the anonymous Firebase auth.uid. Real fix: switch to email-link / phone auth so auth.uid == sync UID by construction, OR validate writes via a Cloud Function that maps auth.uid → email → sync UID.
- [ ] **Real authentication** — anonymous Firebase Auth + email-OTP via custom service is fine for testing but doesn't survive cross-device sign-in by default. Replace with Firebase email-link auth or phone auth so the same email always resolves to the same Firebase UID without our `email_uids_v1` workaround.
- [ ] **Production OTP delivery** — `email_otp_service.dart` needs a real SMTP / SendGrid / Firebase Functions endpoint configured. Currently relies on dev keys.
- [ ] **App store assets** — icon, launch screen, screenshots, description, privacy policy URL, terms URL.
- [ ] **Privacy policy + terms of service** — required for Play / App Store submission.

## P1 — Known bugs / rough edges

- [ ] **Court positions are local-only** — `courtPositions` in `AppController` is in-memory and not synced to Firestore. The host's lineup assignments don't appear on joiners' devices. Should write to `games/{gameId}/positions` and stream back.
- [ ] **Chat history isn't persisted locally** — messages live in `gameChats` / `friendChats` Rx maps; on app restart they're empty until the Firestore listener catches up. Add `StateStorage.saveChats` / `loadChats` for an instant cold-boot experience.
- [ ] **Cancel-match cleanup is partial** — `cancelHostedGame` deletes the game doc and pending requests but doesn't delete the `messages/` subcollection. Orphaned chat docs accumulate in Firestore.
- [ ] **Booking stays in joiner's list after host cancels** — when a host cancels a game, joiners' `bookings` still reference it. They get a "game disappeared" experience. Need a listener on game existence to prune.
- [ ] **Demo seed UIDs collide** — `demo_manoo_uid` / `demo_taqi_uid` are hard-coded for testing. If two physical devices both seed and one user re-signs-up with a different email, the seed UID stays pinned to the old account on disk. Fine for the two-tester loop; remove before public release.
- [ ] **`mounted` check missing** in a few async gaps in dialogs (post-`await Navigator.pop()`). Low-impact, but tighten before release.
- [ ] **Snapshot staleness** — embedded `playerSnapshot` / `hostSnapshot` / `otherSnapshot` documents go stale when a user updates their name, photo, or level. Either invalidate on profile edit, or move to a real `users/{uid}` collection that everyone reads from.
- [ ] **No avatar upload to Firebase Storage** — `image_picker` returns a local file path, but the path is unique per device. Other users see no photo. Wire up `firebase_storage` upload + remote URL.
- [ ] **Friend list isn't persisted locally** — only Firestore-backed. On app launch with no network, friends appear empty until the stream connects. Mirror to `StateStorage`.

## P2 — UX polish

- [ ] **Inbox is barebones** — needs unread counts per thread, last-message preview, sort by recency.
- [ ] **Nav badges** — Messages tab in floating nav doesn't show unread counts (the count is computed but capped at 9 and not always wired through).
- [ ] **Push notifications** — Firebase Cloud Messaging not integrated. Users only see new requests / messages while the app is foregrounded.
- [ ] **Browse filters** — level, vibe, area, time-of-day, price filters exist visually but several aren't wired to the feed.
- [ ] **Map view of open courts** — currently only list. Browse already pulls geo coords for some games; render a map tab.
- [ ] **Skill-level matching** — host can pick a level requirement, but join requests aren't filtered by it. Add a soft warning when a requester's level is far off.
- [ ] **Empty-state polish** — several empty screens (no games, no friends, no requests) are functional but not delightful.
- [ ] **Loading skeletons** — replace spinners on Home / Browse with content skeletons.
- [ ] **Confirmation toasts vs banners** — current `Get.snackbar` styling is inconsistent across screens. Centralise.

## P3 — Features on the roadmap

- [ ] **Recurring games** — "Every Tuesday at 7pm" matches.
- [ ] **Tournaments / brackets** — multi-game events with standings.
- [ ] **Court bookings integration** — partner with clubs to actually book the court via the app (currently host books separately).
- [ ] **Payments split** — collect each player's share in-app via a payment gateway (JazzCash / Easypaisa / Stripe).
- [ ] **Player ratings post-match** — rate teammates / opponents to feed level progression.
- [ ] **Coach / training mode** — separate vibe for lesson bookings.
- [ ] **Match results entry** — currently `match_finished_screen` shows a placeholder.
- [ ] **Stats deep-dive** — head-to-head records, win-rate trend, opponent-strength-adjusted level.
- [ ] **Public player profile sharing** — deep-link a profile to share outside the app.
- [ ] **Search players by handle** — directory + add-friend by username.
- [ ] **Block / report user** — abuse handling, required for app stores.
- [ ] **Multi-language** — Urdu support.

## P4 — Code health

- [ ] **Replace deprecated `withOpacity`** — `flutter analyze` flags ~120 uses; migrate to `withValues(alpha: …)` before the Flutter SDK breaks them.
- [ ] **Replace deprecated `Color.value`** — same rationale.
- [ ] **Remove unused fields** — `_remoteGamesSub`, `_messages` in `chat_screen.dart`, `players` in `game_card.dart`. Pre-existing.
- [ ] **Tests** — test coverage is essentially zero. Add unit tests for `AppController` (especially `approveJoin`, `setCourtPosition`, `signOut` invariants) and integration tests for the host → request → approve → chat flow.
- [ ] **Extract `GameSyncService` into smaller services** — chat, friends, and games could each have their own service. The current single-file approach is starting to bulge (~500 lines).
- [ ] **Migrate from local `kMe` to `currentUser.value` everywhere** — there are still legacy direct reads of the global `kMe`. The reactive `currentUser` should be the only source of truth.
- [ ] **Constants for magic strings** — `'pending'`, `'confirmed'`, `'hosting'`, `'approved'`, `'declined'`, `'pending_in'`, `'pending_out'`, `'friends'` should be enum-typed.

---

## Recently shipped

These were on the list in earlier rounds and are now closed:

- [x] Pull-to-refresh on Home and Browse (RefreshIndicator + `AppController.refreshAll`)
- [x] Profile picture displays correctly during sign-up and edit-profile (was using NetworkImage on local file paths — switched to FileImage / Image.file via a `_PhotoPreview` helper)
- [x] Firebase Auth now signs in BEFORE AppController's listeners attach (was a fire-and-forget race that could leave streams unauthenticated)
- [x] Firestore rules relaxed to unblock cross-device writes — the strict rules required `auth.uid == hostUid` which never matched our deterministic per-email sync UID, so every cross-device write was silently rejected by `_enabled`-style graceful-degradation. Strict rules tracked above as a P0 follow-up.



- [x] Email-keyed user registry + seed two demo accounts
- [x] Same email restores same identity across sign-out / sign-in
- [x] Sign-up detects returning email and skips the new-profile flow
- [x] Persistent sync UID per email (override mechanism in `IdentityService`)
- [x] Host can edit every game field (club, area, city, court, court type, schedule, vibe, cost, approval mode)
- [x] Host can cancel / delete a match (with confirmation + Firestore cleanup)
- [x] Court diagram respects `game.total` (1–4 slots, not always 4)
- [x] Host is auto-placed on slot 0 when a game is published
- [x] Only host can assign court positions; player picker bottom-sheet
- [x] Approved-player snapshots are persisted on each game so the line-up survives restart
- [x] Friend requests sync across devices via `users/{uid}/friends/{otherUid}`
- [x] Game chat synced via Firestore (`games/{id}/messages`)
- [x] DM chat synced via Firestore (`dms/{conversationId}/messages`)
- [x] Floating nav added to profile screen
- [x] Sign-out option exposed via profile settings menu
- [x] Friends + Join Requests entry points added to profile settings menu
