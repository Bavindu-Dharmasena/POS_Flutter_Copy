import 'package:flutter/material.dart';
import 'package:pos_system/features/manager/pages/add_user.dart';

// Auth
import '../features/auth/login_page.dart';
// import '../features/auth/auth_guard.dart'; // Temporarily commented out

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
  static Route<dynamic> generateRoute(
    RouteSettings settings,
    BuildContext context,
  ) {
    print('🚀 Navigating to: ${settings.name}'); // Debug log

    switch (settings.name) {
      // ---------- Auth ----------
      case '/':
      case '/login':
        print('✅ Loading LoginPage');
        return MaterialPageRoute(builder: (_) => const LoginPage());

      // ---------- Cashier ----------
      case '/cashier':
        print('✅ Loading CashierViewPage');
        return MaterialPageRoute(builder: (_) => const CashierViewPage());

      // ---------- StockKeeper ----------
      case '/stockkeeper':
        print('✅ Loading StockKeeperHome');
        return MaterialPageRoute(builder: (_) => const StockKeeperHome());

      // ---------- Manager: Home ----------
      case '/manager':
        print('✅ Loading ManagerHomePage');
        return MaterialPageRoute(builder: (_) => const ManagerHomePage());

      // ---------- Manager: User management ----------
      case '/manager/user-management':
        print('✅ Loading UserManagementPasswordChangePage');
        return MaterialPageRoute(
          builder: (_) => const UserManagementPasswordChangePage(),
        );

      //------------Manager: add user ----------------
      case '/manager/add-user':
        print('loading adduserpage');
        return MaterialPageRoute(builder: (_) =>const AddUserPage()
        );

      // ---------- Manager: Reports ----------
      case '/manager/reports/sales-summaries':
        print('✅ Loading SalesSummariesReportPage');
        return MaterialPageRoute(
          builder: (_) => const SalesSummariesReportPage(),
        );

      case '/manager/reports/trending-items':
        print('✅ Loading TrendingItemsReportPage');
        return MaterialPageRoute(
          builder: (_) => const TrendingItemsReportPage(),
        );

      case '/manager/reports/profit-margins':
        print('✅ Loading ProfitMarginsReportPage');
        return MaterialPageRoute(
          builder: (_) => const ProfitMarginsReportPage(),
        );

      case '/manager/reports/creditors':
        print('✅ Loading CreditorsReportPage');
        return MaterialPageRoute(builder: (_) => const CreditorsReportPage());

      // ---------- Manager: Other ----------
      case '/manager/audit-logs':
        print('✅ Loading AuditLogsPage');
        return MaterialPageRoute(builder: (_) => const AuditLogsPage());

      case '/manager/price-rules':
        print('✅ Loading PriceRulesPage');
        return MaterialPageRoute(builder: (_) => const PriceRulesPage());

      case '/manager/create-creditor':
        print('✅ Loading CreateCreditorPage');
        return MaterialPageRoute(builder: (_) => const CreateCreditorPage());

      // ---------- Admin stub ----------
      case '/admin':
        print('✅ Loading Admin Stub');
        return MaterialPageRoute(
          builder: (_) => const _Stub(title: 'Admin (stub)'),
        );

      // ---------- Unknown ----------
      default:
        print('❌ Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) =>
              _Stub(title: '404 • Route "${settings.name}" not found'),
        );
    }
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Colors.grey[700],
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    ),
  );
}
