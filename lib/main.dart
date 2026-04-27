import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/app_pages.dart';
import 'app/controllers/app_controller.dart';
import 'app/routes.dart';
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

  // ── GetX global controllers ───────────────────────────────────────────────
  Get.put(AppController(), permanent: true);
  // Get.put(AuthController(), permanent: true); // enable after Firebase setup

  runApp(const PadelPartnerApp());
}

class PadelPartnerApp extends StatelessWidget {
  const PadelPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Padel Partner',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: Routes.signUp,
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
