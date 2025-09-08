import 'package:flutter/material.dart';

// Auth
import '../features/auth/login_page.dart';
import '../features/auth/auth_guard.dart';

// Cashier / StockKeeper
import '../features/cashier/cashier_view_page.dart';
import '../features/stockkeeper/stockkeeper_home.dart';

// Manager Home
import '../features/manager/manager_home.dart';

// Manager pages
import '../features/manager/pages/user_management_password_change.dart';
import '../features/manager/pages/reports_sales_summaries.dart';
import '../features/manager/pages/reports_trending_items.dart';
import '../features/manager/pages/reports_profit_margins.dart';
import '../features/manager/pages/reports_creditors.dart';
import '../features/manager/pages/audit_logs.dart';
import '../features/manager/pages/price_rules.dart';
import '../features/manager/pages/create_creditor.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings, BuildContext context) {
    switch (settings.name) {
      // ---------- Auth ----------
      case '/':
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());

      // ---------- Cashier ----------
      // case '/cashier':
      //   return MaterialPageRoute(
      //     builder: (_) => AuthGuard(
      //       allowedRoles: const ['Cashier'],
      //       builder: (ctx) => const CashierViewPage(),
      //     ),
      //   );

      // ---------- StockKeeper ----------
      case '/stockkeeper':
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            allowedRoles: const ['StockKeeper'],
            builder: (ctx) => const StockKeeperHome(),
          ),
        );

      // ---------- Manager: Home ----------
      case '/manager':
        return _manager(const ManagerHomePage());

      // ---------- Manager: User management (your page shows password change list) ----------
      case '/manager/user-management':
        return _manager(const UserManagementPasswordChangePage());

      // ---------- Manager: Reports ----------
      case '/manager/reports/sales-summaries':
        return _manager(const SalesSummariesReportPage());
      case '/manager/reports/trending-items':
        return _manager(const TrendingItemsReportPage());
      case '/manager/reports/profit-margins':
        return _manager(const ProfitMarginsReportPage());
      case '/manager/reports/creditors':
        return _manager(const CreditorsReportPage());

      // ---------- Manager: Other ----------
      case '/manager/audit-logs':
        return _manager(const AuditLogsPage());
      case '/manager/price-rules':
        return _manager(const PriceRulesPage());
      case '/manager/create-creditor':
        return _manager(const CreateCreditorPage());

      // ---------- (Optional) Admin stub so login doesn't bounce to /login ----------
      case '/admin':
        return MaterialPageRoute(builder: (_) => const _Stub(title: 'Admin (stub)'));

      // ---------- Unknown ----------
      default:
        // Show 404-style page instead of silently sending to Login
        return MaterialPageRoute(
          builder: (_) => const _Stub(title: '404 • Page not found'),
        );
    }
  }

  // Small helper to avoid repeating the guard
  static MaterialPageRoute _manager(Widget child) {
    return MaterialPageRoute(
      builder: (_) => AuthGuard(
        allowedRoles: const ['Manager'],
        builder: (ctx) => child,
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}
