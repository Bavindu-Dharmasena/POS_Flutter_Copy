// lib/widgets/risk_chip.dart
import 'package:flutter/material.dart';
import '../models/creditor_model.dart';

class RiskChip extends StatelessWidget {
  final int creditLimit;
  
  const RiskChip({
    super.key,
    required this.creditLimit,
  });

  RiskLevel get _riskLevel {
    if (creditLimit >= 1000000) return RiskLevel.high;
    if (creditLimit >= 250000) return RiskLevel.medium;
    if (creditLimit > 0) return RiskLevel.low;
    return RiskLevel.none;
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = _riskLevel;
    final color = riskLevel.color(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Risk: ${riskLevel.label}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}