import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/app_pages.dart';
import 'app/controllers/app_controller.dart';
import 'app/routes.dart';
import 'core/mock_data.dart';
import 'core/services/user_storage.dart';
import 'core/theme/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  // Replace placeholder values in firebase_options.dart first, then uncomment:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── System UI ─────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ── Load persisted user (if any) before deciding initial route ────────────
  final saved = await UserStorage.load();
  if (saved != null) kMe = saved;

  // ── GetX global controllers ───────────────────────────────────────────────
  Get.put(AppController(), permanent: true);

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
