import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'routes/app_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

// ✅ Settings + Theming
import 'features/stockkeeper/settings/settings_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try{
    // 1. First load environment variables
    await dotenv.load(fileName: ".env");
    
    // 2. Then initialize services
    final authService = AuthService();
    await authService.autoLogin();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authService), // Use .value to avoid creating twice
          ChangeNotifierProvider(create: (_) => SettingsController()),
        ],
        child: const MyApp(),
      ),
    );
  }catch (e) {
    // 3. Fallback error handling
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization failed: ${e.toString()}'),
          ),
        ),
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    // While SharedPreferences loads, we can still render with a sensible default.
    // The app will rebuild automatically when settings finish loading.
    return MaterialApp(
      title: 'AASA POS System',
      debugShowCheckedModeBanner: false,

      // ✅ Use centralized themes that respect the chosen base font size
      theme: buildLightTheme(settings.fontSize),
      darkTheme: buildDarkTheme(settings.fontSize),
      themeMode: settings.themeMode,

      // ✅ Optional: ensure consistent scaling across all widgets
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settings.textScaleFactor, // derived from font size
          ),
          child: child!,
        );
      },

      // ✅ Your existing routing stays the same
      initialRoute: '/',
      onGenerateRoute: (routeSettings) =>
          AppRoutes.generateRoute(routeSettings, context),
    );
  }
}
