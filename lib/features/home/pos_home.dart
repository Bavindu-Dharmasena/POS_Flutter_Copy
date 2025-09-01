import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for DiagnosticPropertiesBuilder
import '../auth/login_page.dart'; // Adjust the import path

class POSHomePage extends StatelessWidget {
  const POSHomePage({super.key});

  static const String shopName = "Tharu Shop";

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 30),
              Text(
                shopName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: const [
                      RoleCard(
                        title: 'StockKeeper',
                        subtitle: 'Manage Stock',
                        icon: Icons.inventory_2,
                        color: Colors.orange,
                        route: '/stockkeeper',
                      ),
                      RoleCard(
                        title: 'Cashier',
                        subtitle: 'Quick Billing',
                        icon: Icons.receipt_long,
                        color: Colors.green,
                        route: '/cashier',
                      ),
                      RoleCard(
                        title: 'Admin',
                        subtitle: 'User Management',
                        icon: Icons.admin_panel_settings,
                        color: Colors.red,
                        route: '/admin',
                      ),
                      RoleCard(
                        title: 'Manager',
                        subtitle: 'Oversee Sales',
                        icon: Icons.supervisor_account,
                        color: Colors.blue,
                        route: '/manager',
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Powered by AASA IT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route; // NEW: named route to navigate

  const RoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('color', color))
      ..add(StringProperty('route', route));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (route != null && route!.isNotEmpty) {
            Navigator.pushNamed(context, route!);
          } else {
            // Fallback to login if no route provided
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
          }
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: color,
          elevation: 4,
          child: Center(
            // Prevent global text scaling from overflowing the fixed tile.
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 36, color: Colors.white),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
