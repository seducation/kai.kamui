import 'package:flutter/material.dart';

class AddJobScreen extends StatelessWidget {
  final String profileId;
  const AddJobScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Job')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Add Job for Profile: $profileId'),
            const SizedBox(height: 8),
            const Text('Placeholder Screen'),
          ],
        ),
      ),
    );
  }
}
