import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/themes/app_theme.dart';
import 'data/local/shared_prefs_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/residence_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/marketplace_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/profile_provider.dart';
import 'providers/bookmark_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FIX: Initialize sqflite untuk Windows/Linux/macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize SharedPreferences
  await SharedPrefsHelper.init();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        // Profile Provider - NEW!
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(),
        ),

        // Bookmark Provider - NEW!
        ChangeNotifierProvider(
          create: (_) => BookmarkProvider(),
        ),

        // Residence Provider - SQLite
        ChangeNotifierProvider(
          create: (_) {
            final provider = ResidenceProvider();
            provider.initialize(); // Initialize dengan SQLite
            return provider;
          },
        ),
        // Activity Provider - SQLite
        ChangeNotifierProvider(
          create: (_) {
            final provider = ActivityProvider();
            provider.initialize(); // Initialize dengan SQLite
            return provider;
          },
        ),
        // Marketplace Provider - SQLite
        ChangeNotifierProvider(
          create: (_) {
            final provider = MarketplaceProvider();
            provider.initialize(); // Initialize dengan SQLite
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'InfoMA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
