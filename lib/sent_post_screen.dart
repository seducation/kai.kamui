import 'package:flutter/material.dart';

class SentPostScreen extends StatelessWidget {
  const SentPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Send To'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'OTM'),
              Tab(text: 'Chat'),
              Tab(text: 'Other Apps'),
              Tab(text: 'Post'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('OTM')),
            Center(child: Text('Chat')),
            Center(child: Text('Other Apps')),
            Center(child: Text('Post')),
          ],
        ),
      ),
    );
  }
}
