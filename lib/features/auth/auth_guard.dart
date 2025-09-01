import 'package:flutter/material.dart';
import '../../core/services/secure_storage_service.dart';

typedef GuardedBuilder = Widget Function(BuildContext context);

class AuthGuard extends StatelessWidget {
  const AuthGuard({
    super.key,
    required this.allowedRoles,
    required this.builder,
    this.onDenied,
  });

  final List<String> allowedRoles;
  final GuardedBuilder builder;
  final Widget? onDenied;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SecureStorageService.instance.getRole(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = (snap.data ?? '').trim();
        final ok = allowedRoles.isEmpty ||
            allowedRoles.map((e) => e.toLowerCase()).contains(role.toLowerCase());
        if (ok) return builder(context);
        return onDenied ??
            const Scaffold(body: Center(child: Text('403 • Forbidden')));
      },
    );
  }
}
