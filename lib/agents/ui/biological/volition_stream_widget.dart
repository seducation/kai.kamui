import 'package:flutter/material.dart';
import '../../specialized/organs/volition_organ.dart';

class VolitionStreamWidget extends StatelessWidget {
  final VolitionOrgan volition;

  const VolitionStreamWidget({super.key, required this.volition});

  @override
  Widget build(BuildContext context) {
    // Similarly, we need VolitionOrgan to expose its "thought stream"
    // For now, we will inspect the drives.

    return Card(
      color: Colors.deepPurple.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.purpleAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  'Stream of Consciousness',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Drives visualization
            ...volition.drives.map((drive) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Text(
                      drive.name,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: drive.intensity,
                        backgroundColor: Colors.black26,
                        color: Colors.purpleAccent,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
