import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SrvFeatureTabscreen extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;

  const SrvFeatureTabscreen({super.key, required this.searchResults});

  @override
  Widget build(BuildContext context) {
    final featureResults = searchResults.where((result) => result['type'] == 'post' || result['type'] == 'profile').toList();

    if (featureResults.isEmpty) {
      return const Center(child: Text('No features found.'));
    }

    return ListView.builder(
      itemCount: featureResults.length,
      itemBuilder: (context, index) {
        final item = featureResults[index];
        if (item['type'] == 'profile') {
          return _buildProfileResult(context, item['data']);
        } else if (item['type'] == 'post') {
          return _buildPostResult(context, item['data']);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileResult(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: data['profileImageUrl'] != null && data['profileImageUrl'].isNotEmpty
              ? NetworkImage(data['profileImageUrl'])
              : null,
          child: data['profileImageUrl'] == null || data['profileImageUrl'].isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(data['name'] ?? 'No name'),
        subtitle: Text(data['bio'] ?? ''),
        onTap: () => context.go('/profile/${data['\$id']}'),
      ),
    );
  }

  Widget _buildPostResult(BuildContext context, Map<String, dynamic> data) {
    final title = data['titles'] ?? data['caption'] ?? '';
    final subtitle = data['caption'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.article),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post navigation is not implemented yet.')),
          );
        },
      ),
    );
  }
}
