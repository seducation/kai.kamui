import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/model/post.dart';
import 'package:my_app/model/profile.dart';
import 'package:my_app/widgets/post_item.dart';
import 'package:provider/provider.dart';

class SrvFeatureTabscreen extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;

  const SrvFeatureTabscreen({super.key, required this.searchResults});

  @override
  Widget build(BuildContext context) {
    final featureResults = searchResults
        .where((result) => result['type'] == 'post' || result['type'] == 'profile')
        .toList();

    if (featureResults.isEmpty) {
      return const Center(child: Text('No features found.'));
    }

    return FutureBuilder<List<dynamic>>(
      future: _getProfiles(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final profiles = snapshot.data as List<dynamic>;
        final profileId = profiles.isNotEmpty ? profiles[0].$id : '';
        return ListView.builder(
          itemCount: featureResults.length,
          itemBuilder: (context, index) {
            final item = featureResults[index];
            if (item['type'] == 'profile') {
              return _buildProfileResult(context, item['data']);
            } else if (item['type'] == 'post') {
              return FutureBuilder<Profile>(
                future: _getAuthorProfile(context, item['data']['profile_id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  final author = snapshot.data!;
                  final post = Post(
                    id: item['data']['\$id'],
                    author: author,
                    timestamp: DateTime.parse(item['data']['timestamp']),
                    contentText: item['data']['caption'] ?? '',
                    stats: PostStats(
                      likes: item['data']['likes'] ?? 0,
                      comments: 0,
                      shares: 0,
                      views: 0,
                    ),
                  );
                  return PostItem(post: post, profileId: profileId);
                },
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<List<dynamic>> _getProfiles(BuildContext context) {
    final appwriteService = context.read<AppwriteService>();
    return appwriteService.getProfiles().then((value) => value.rows);
  }

  Future<Profile> _getAuthorProfile(BuildContext context, String profileId) {
    final appwriteService = context.read<AppwriteService>();
    return appwriteService.getProfile(profileId).then((row) => Profile.fromRow(row));
  }

  Widget _buildProfileResult(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: data['profileImageUrl'] != null &&
                  data['profileImageUrl'].isNotEmpty
              ? NetworkImage(data['profileImageUrl'])
              : null,
          child: data['profileImageUrl'] == null ||
                  data['profileImageUrl'].isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(data['name'] ?? 'No name'),
        subtitle: Text(data['bio'] ?? ''),
        onTap: () => context.go('/profile/${data['\$id']}'),
      ),
    );
  }
}
