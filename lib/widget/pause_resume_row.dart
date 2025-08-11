import 'package:flutter/material.dart';

class PauseResumeRow extends StatelessWidget {
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final bool hasPaused;
  final bool hasCart;
  final double horizontalPadding;

  const PauseResumeRow({
    super.key,
    required this.onPause,
    required this.onResume,
    required this.hasPaused,
    required this.hasCart,
    this.horizontalPadding = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: hasCart ? onPause : null,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(130, 40),
            ),
          ),
          ElevatedButton.icon(
            onPressed: hasPaused ? onResume : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(130, 40),
            ),
          ),
        ],
      ),
    );
  }
}
