import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient(Theme.of(context).brightness),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
