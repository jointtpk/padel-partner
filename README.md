# Padel Partner

Find a padel game near you, or host one and let other players request to join. Pakistan-first (Karachi, Lahore, Islamabad, …) with a clean Flutter UI and live cross-device sync via Firebase.

## What it does

- **Sign up / sign in** with email + 4-digit OTP (no passwords)
- **Host a match** — pick club, court, day, time, vibe, cost, open spots, manual or auto-approve
- **Browse open courts** — discover games hosted by other users on any device
- **Request to join** — send a request; the host approves or declines
- **Manage requests** — host sees pending requests with each player's profile, level, and stats
- **Court line-up** — host assigns approved players to specific 2v2 court positions
- **Game chat** — team thread per game, synced live across devices
- **Friends** — send and accept friend requests, manage your list, DM friends
- **Profile** — stats, level progression, history, partners
- **Subscription** — Pro tier (in-app purchase) gives a verified gold tick

## Quick start

```bash
flutter pub get
flutter run
```

## Build a release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Test accounts

The app seeds two demo profiles on first launch (idempotent):

| Email                       | Role   | Tier   |
|-----------------------------|--------|--------|
| `manooazad@gmail.com`       | Host   | Pro    |
| `taqiratnani@hotmail.com`   | Player | Regular|

Sign in with either email — the OTP flow still runs (you'll receive a real code), but the profile is restored from local storage so you don't have to re-enter it. The two accounts share stable cross-device UIDs (`demo_manoo_uid`, `demo_taqi_uid`) so a friend request from one always lands at the right inbox on the other device.

## Configuration

Detailed Firebase / Google Maps / Android setup lives in [`SETUP.md`](SETUP.md).

For the architecture deep-dive, see [`TECHNICAL.md`](TECHNICAL.md).

For the work-in-progress / known issues list, see [`TODO.md`](TODO.md).

## Stack

- **Flutter** 3.3+ (Dart 3)
- **GetX** for state, routing, and reactive bindings
- **Firebase** — Auth (anonymous), Firestore (games / requests / chat / friendships), Storage
- **Google Maps Flutter** for the host's pin picker
- **In-App Purchase** for the Pro subscription
- **shared_preferences** for local persistence
- **app_links** for deep-link sharing (`padelpartner://join?…`)

## License

Proprietary. © Padel Partner.
