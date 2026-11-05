import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'providers/theme_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 250 << 20; // 250 MB
  await dotenv.load(fileName: ".env");
  // Always clear previous session on app launch so closing the app automatically logs out
  await AuthService.logout();
  runApp(const ProviderScope(child: SirfBillApp()));
}

class SirfBillApp extends ConsumerStatefulWidget {
  const SirfBillApp({super.key});

  @override
  ConsumerState<SirfBillApp> createState() => _SirfBillAppState();
}

class _SirfBillAppState extends ConsumerState<SirfBillApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await AuthService.logout();
        return AppExitResponse.exit;
      },
      onDetach: () {
        AuthService.logout();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    const noSwipePageTransitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      },
    );

    return MaterialApp.router(
      title: 'Sirfbill Restaurant',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      themeMode: themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        cardColor: Colors.white,
        useMaterial3: true,
        pageTransitionsTheme: noSwipePageTransitionsTheme,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        cardColor: const Color(0xFF1E293B),
        useMaterial3: true,
        pageTransitionsTheme: noSwipePageTransitionsTheme,
      ),
      routerConfig: goRouter,
    );
  }
}
