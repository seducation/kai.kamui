import 'package:flutter/material.dart';
import '../../coordination/organ_base.dart';

class OrganMonitorWidget extends StatelessWidget {
  final Map<String, Organ> organs;

  const OrganMonitorWidget({super.key, required this.organs});

  @override
  Widget build(BuildContext context) {
    if (organs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biological Organs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: organs.entries.map((entry) {
                return _buildOrganChip(entry.key, entry.value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganChip(String name, Organ organ) {
    final health = organ.health;
    Color healthColor;
    if (health > 0.8) {
      healthColor = Colors.greenAccent;
    } else if (health > 0.4) {
      healthColor = Colors.orangeAccent;
    } else {
      healthColor = Colors.redAccent;
    }

    return Container(
      width: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.replaceFirst('Organ', ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Icon(
                Icons.favorite,
                size: 12,
                color: healthColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: health,
            backgroundColor: Colors.grey[800],
            color: healthColor,
            minHeight: 2,
          ),
          const SizedBox(height: 4),
          Text(
            'Tokens: ${organ.tokenUsage} / ${organ.tokenLimit}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          if (organ.isFatigued)
            const Text(
              'FATIGUED',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
