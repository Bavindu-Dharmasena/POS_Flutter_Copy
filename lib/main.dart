import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'routes/app_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'features/auth/two_step_login_page.dart'; // <-- New login page


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

    return MaterialApp(
      title: 'AASA POS System',
      debugShowCheckedModeBanner: false,

 //     theme: ThemeData(
 //       colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
 //       useMaterial3: true,
 //     ),
 //     // Start with the two-step login page
 //     home: const TwoStepLoginPage(),
 //     onGenerateRoute: (settings) => AppRoutes.generateRoute(settings, context),


      // ✅ Centralized themes (font size handled via MediaQuery scaling)
      theme: buildLightTheme(settings.fontSize),
      darkTheme: buildDarkTheme(settings.fontSize),
      themeMode: settings.themeMode, // defaults to DARK on first launch

      // ✅ Uniform scaling across widgets based on settings.fontSize
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settings.textScaleFactor,
          ),
          child: child!,
        );
      },

      // ✅ Your existing routing
      initialRoute: '/',
      onGenerateRoute: (routeSettings) =>
          AppRoutes.generateRoute(routeSettings, context),

    );
  }
}
