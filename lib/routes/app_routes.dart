import 'package:flutter/material.dart';

// Auth
import '../features/auth/two_step_login_page.dart';

// Splash
import '../features/splashscreen.dart';

// Cashier
import '../features/cashier/cashier_view_page.dart';

// Stockkeeper
import '../features/stockkeeper/stockkeeper_home.dart';

/// ---------------- Manager / Owner Module ----------------
import '../features/manager/manager_home.dart';
import '../features/manager/pages/user_management_password_change.dart';
import '../features/manager/pages/reports_sales_summaries.dart';
import '../features/manager/pages/reports_trending_items.dart';
import '../features/manager/pages/reports_profit_margins.dart';
import '../features/manager/pages/reports_creditors.dart';
import '../features/manager/pages/audit_logs.dart';
import '../features/manager/pages/price_rules.dart';
import '../features/manager/pages/create_creditor.dart';

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

      // ---------------- Manager / Owner ----------------
      case '/manager':
        return MaterialPageRoute(builder: (_) => const ManagerHomePage());

      // User Management
      case '/manager/user-management':
        return MaterialPageRoute(builder: (_) => const UserManagementPasswordChangePage());

      // Reports
      case '/manager/reports/sales-summaries':
        return MaterialPageRoute(builder: (_) => const SalesSummariesReportPage());
      case '/manager/reports/trending-items':
        return MaterialPageRoute(builder: (_) => const TrendingItemsReportPage());
      case '/manager/reports/profit-margins':
        return MaterialPageRoute(builder: (_) => const ProfitMarginsReportPage());
      case '/manager/reports/creditors':
        return MaterialPageRoute(builder: (_) => const CreditorsReportPage());

      // Audit Logs
      case '/manager/audit-logs':
        return MaterialPageRoute(builder: (_) => const AuditLogsPage());

      // Price Rules
      case '/manager/price-rules':
        return MaterialPageRoute(builder: (_) => const PriceRulesPage());

      // Create Creditor
      case '/manager/create-creditor':
        return MaterialPageRoute(builder: (_) => const CreateCreditorPage());

      // ---------------- Quick Access From Manager ----------------
      case '/cashier':
        return MaterialPageRoute(builder: (_) => const CashierViewPage());
      case '/stockkeeper':
        return MaterialPageRoute(builder: (_) => const StockKeeperHome());

      // ---------------- Admin (placeholder) ----------------
      case '/admin':
        return MaterialPageRoute(
          builder: (_) => const _StubPage(title: 'Admin Home'),
        );

      // Default → login
      default:
        return MaterialPageRoute(builder: (_) => const TwoStepLoginPage());
    }
  }
}

/* Simple stub page for Admin until you plug in real widgets */
class _StubPage extends StatelessWidget {
  final String title;
  const _StubPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$title (stub)\nReplace with your real page',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
