import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/app_pages.dart';
import 'app/controllers/app_controller.dart';
import 'app/routes.dart';
import 'core/mock_data.dart';
import 'core/services/auth_service.dart';
import 'core/services/billing_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/identity_service.dart';
import 'core/services/user_storage.dart';
import 'core/theme/tokens.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  // Initialise on every platform that has options configured (Android + Web
  // today; iOS/macOS still throw `UnsupportedError`).
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // ── System UI ─────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ── Seed the two demo accounts the team uses for sign-in testing ─────────
  // Idempotent — won't overwrite real edits made to those profiles after
  // the first launch.
  await UserStorage.ensureSeedUsers();

  // ── Load persisted user (if any) before deciding initial route ────────────
  final saved = await UserStorage.load();
  if (saved != null) kMe = saved;

  // ── Cross-device sync identity ────────────────────────────────────────────
  // Pin the IdentityService UID to the saved user's email so the same
  // login resolves to the same Firestore identity across devices /
  // sessions. Without this, anonymous Firebase auth would mint a fresh
  // uid on every sign-in and friend requests / hosted games would
  // dangle off the previous identity.
  if (saved?.email != null) {
    final pinned = await UserStorage.getUidForEmail(saved!.email!);
    if (pinned != null) IdentityService.instance.setOverrideUid(pinned);
  }
  await IdentityService.instance.uid();

  // ── Firebase Auth (anonymous) for verifiable sync identity ────────────────
  // Sign in BEFORE wiring AppController so its Firestore listeners
  // (games feed, friend list) carry an auth.uid from the very first
  // request. With our security rules requiring `request.auth != null`,
  // a fire-and-forget sign-in races the listeners and silently drops
  // their initial reads. Best-effort — failure here means the app
  // degrades to in-memory only, which is acceptable.
  await AuthService.instance.ensureSignedIn().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );

  // ── GetX global controllers ───────────────────────────────────────────────
  Get.put(AppController(), permanent: true);

  // ── Deep links (padelpartner://join?d=…) ──────────────────────────────────
  // Skip on web — app_links is mobile-only and has no purpose without an
  // installed app to receive the URL.
  if (!kIsWeb) {
    // Fire-and-forget: cold-start link is dispatched via Future.microtask so
    // it runs after the navigator mounts.
    DeepLinkService.instance.init();
  }

  // ── Billing (in-app purchases) ────────────────────────────────────────────
  // Subscribed at launch so pending purchases (e.g. resumed after a kill)
  // are still acknowledged and Pro is granted even if the upgrade sheet has
  // been dismissed.
  BillingService.instance.init();

  runApp(PadelPartnerApp(initialRoute: saved != null ? Routes.home : Routes.signUp));
}

class PadelPartnerApp extends StatelessWidget {
  const PadelPartnerApp({super.key, required this.initialRoute});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Padel Partner',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue900,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      // Remove the default splash / highlight effects
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
