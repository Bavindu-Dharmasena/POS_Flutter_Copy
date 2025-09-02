import 'package:flutter/material.dart';

// Auth
import '../features/auth/login_page.dart';
import '../features/auth/auth_guard.dart';

// Features
import '../features/cashier/cashier_view_page.dart';
import '../features/stockkeeper/stockkeeper_home.dart';
import '../features/manager/manager_home.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings, BuildContext context) {
    switch (settings.name) {
      case '/':
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/cashier':
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            allowedRoles: const ['Cashier'],
            builder: (ctx) => const CashierViewPage(),
          ),
        );

      case '/stockkeeper':
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            allowedRoles: const ['StockKeeper'],
            builder: (ctx) => const StockKeeperHome(),
          ),
        );

      case '/manager':
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            allowedRoles: const ['Manager'],
            builder: (ctx) => const ManagerHomePage(),
          ),
        );

      case '/admin':
        return MaterialPageRoute(
          builder: (_) => AuthGuard(
            allowedRoles: const ['Admin'],
            builder: (ctx) => const _Stub(title: 'Admin Home'),
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}
