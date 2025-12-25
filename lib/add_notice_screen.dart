import 'package:flutter/material.dart';

class AddNoticeScreen extends StatelessWidget {
  final String profileId;
  const AddNoticeScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Notice')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notification_add, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Add Notice for Profile: $profileId'),
            const SizedBox(height: 8),
            const Text('Placeholder Screen'),
          ],
        ),
      ),
    );
  }
}
