import 'package:flutter/material.dart';

// Auth
import '../features/auth/two_step_login_page.dart';

// Splash
import '../features/splashscreen.dart';

// import '../features/cashier/billingview.dart';
import '../features/cashier/cashier_view_page.dart';



// Stockkeeper
import '../features/stockkeeper/stockkeeper_home.dart';

// Cashier
import '../features/cashier/cashier_dashboard.dart';

// These two files both define a widget named `CashierViewPage`.
// Use aliases to disambiguate which one you want in each route.
import '../features/cashier/cashier_view_page.dart' as cashier_view;
import '../features/cashier/billingview.dart' as billing_view;

class AppRoutes {
  static Route<dynamic> generateRoute(
    RouteSettings settings,
    BuildContext context,
  ) {
    switch (settings.name) {
      // Splash
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // Two-step login
      case '/login':
        return MaterialPageRoute(builder: (_) => const TwoStepLoginPage());

      // Stockkeeper homepage
      case '/stockkeeper':
        return MaterialPageRoute(builder: (_) => const StockKeeperHome());

      // Cashier homepage (dashboard)
      case '/cashier':
        return MaterialPageRoute(builder: (_) => const CashierDashboard());

      // Cashier: product list / main view (from cashier_view_page.dart)
      case '/cashier/view':
        return MaterialPageRoute(
          builder: (_) => const cashier_view.CashierViewPage(),
        );

      // Cashier: quick billing view (from billingview.dart)
      // NOTE: That file also exports a class named CashierViewPage.
      // If you later rename the class to BillingViewPage, update here too.
      case '/cashier/billing':
        return MaterialPageRoute(
          builder: (_) => const billing_view.CashierViewPage(),
        );

      // Manager (stub until you add a real page)
      case '/manager':
        return MaterialPageRoute(
          builder: (_) => const _StubPage(title: 'Manager Home'),
        );

      // Admin (stub until you add a real page)
      case '/admin':
        return MaterialPageRoute(
          builder: (_) => const _StubPage(title: 'Admin Home'),
        );

      // Default → login (avoid falling back to role tiles)
      default:
        return MaterialPageRoute(builder: (_) => const TwoStepLoginPage());
    }
  }
}

/* Simple stub page for Admin/Manager until you plug in real widgets */
class _StubPage extends StatelessWidget {
  final String title;
  const _StubPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('$title (stub)\nReplace with your real page',
            textAlign: TextAlign.center),
      ),
    );
  }
}
