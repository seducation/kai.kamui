import 'package:flutter/material.dart';

class JobsTab extends StatelessWidget {
  final String profileId;
  const JobsTab({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("JobsTab Content", style: TextStyle(color: Colors.white)),
    );
  }
}
