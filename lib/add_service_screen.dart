import 'package:flutter/material.dart';

class AddServiceScreen extends StatelessWidget {
  final String profileId;
  const AddServiceScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Service')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.miscellaneous_services,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text('Add Service for Profile: $profileId'),
            const SizedBox(height: 8),
            const Text('Placeholder Screen'),
          ],
        ),
      ),
    );
  }
}
