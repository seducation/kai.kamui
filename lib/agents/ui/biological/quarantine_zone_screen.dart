import 'package:flutter/material.dart';
import '../../coordination/reflex_system.dart';

class QuarantineZoneScreen extends StatefulWidget {
  final ReflexSystem reflexSystem;

  const QuarantineZoneScreen({super.key, required this.reflexSystem});

  @override
  State<QuarantineZoneScreen> createState() => _QuarantineZoneScreenState();
}

class _QuarantineZoneScreenState extends State<QuarantineZoneScreen> {
  @override
  Widget build(BuildContext context) {
    // In a real implementation, we would expose a stream or list of quarantined agents from ReflexSystem.
    // For now, we'll assume a method exists or add it later.
    // Since ReflexSystem doesn't expose the list publicly yet, we will mock it or need to update ReflexSystem.
    // Let's assume we update ReflexSystem to expose `quarantinedAgents`.

    // Placeholder for now as we haven't updated ReflexSystem to expose the list.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quarantine Zone ☣️'),
        backgroundColor: Colors.red[900],
      ),
      body: const Center(
        child: Text(
          'No agents in quarantine.',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
