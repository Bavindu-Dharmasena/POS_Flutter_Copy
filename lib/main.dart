// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import 'core/services/auth_service.dart';
// import 'features/stockkeeper/settings/settings_provider.dart';
// import 'routes/app_routes.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthService()),
//         ChangeNotifierProvider<SettingsController>(
//           create: (_) {
//             final c = SettingsController();
//             // load persisted theme/font size once
//             c.load();
//             return c;
//           },
//         ),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Listen to settings to apply theme + text scale
//     final settings = context.watch<SettingsController>();

//     return MaterialApp(
//       title: 'AASA POS',
//       debugShowCheckedModeBanner: false,
//       // Apply theme mode (defaults to dark until load() finishes)
//       themeMode: settings.themeMode,
//       theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.light),
//       darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
//       // Apply global text scaling from SettingsController
//       builder: (context, child) {
//         final media = MediaQuery.of(context);
//         return MediaQuery(
//           data: media.copyWith(textScaleFactor: settings.textScaleFactor),
//           child: child ?? const SizedBox.shrink(),
//         );
//       },
//       initialRoute: '/',
//       onGenerateRoute: (s) => AppRoutes.generateRoute(s, context),
//     );
//   }
// }

// lib/features/splashscreen.dart
// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

import 'dart:io' show Platform;

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'features/stockkeeper/settings/settings_provider.dart';
// import 'features/splashscreen.dart';
import 'routes/app_routes.dart';

// ✅ import your database helper and installation page
import 'data/db/database_helper.dart';
import 'features/installation/installation_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    Zone.current.handleUncaughtError(
        details.exception, details.stack ?? StackTrace.current);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('UNCAUGHT (PlatformDispatcher): $error\n$stack');
    return true;
  };

  // sqflite factory per platform
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi; // desktop
  }
  // Android/iOS → default sqflite

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settings = SettingsController();
  await settings.load();

  // ✅ Check if user exists in DB
  final db = await DatabaseHelper.instance.database;
  final users = await db.query('user');
  final bool hasUser = users.isNotEmpty;

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsController>.value(value: settings),
          ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ],
        child: App(hasUser: hasUser),
      ),
    );
  }, (error, stack) {
    debugPrint('UNCAUGHT (Zone): $error\n$stack');
  });
}

class App extends StatelessWidget {
  final bool hasUser;
  const App({super.key, required this.hasUser});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'AASA POS',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
            brightness: Brightness.dark,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.textScaleFactor),
            ),
            child: child!,
          ),

          // ✅ if no user → go to installation
          home: const InstallationPage(),

          // ✅ routes
          onGenerateRoute: (RouteSettings s) =>
              AppRoutes.generateRoute(s, context),

          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Page Not Found')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Route "${settings.name}" not found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed('/'),
                        child: const Text('Go Home'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },

        );
      },
    );
  }
}
