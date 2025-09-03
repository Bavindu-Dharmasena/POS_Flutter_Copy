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


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/stockkeeper/settings/settings_provider.dart';
import '../features/splashscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create + preload persisted settings
  final settings = SettingsController();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp when settings change
    return Consumer<SettingsController>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Flutter SQLite CRUD',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode, // light/dark from SettingsController
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
          // Apply global text scaling from settings
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: settings.textScaleFactor,
            ),
            child: child!,
          ),
          home: const SplashScreen(), // your existing splash → pushes to pages later
        );
      },
    );
  }
}
