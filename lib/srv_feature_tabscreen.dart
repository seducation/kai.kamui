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
        .where(
          (result) => result['type'] == 'post' || result['type'] == 'profile',
        )
        .toList();

    if (featureResults.isEmpty) {
      return const Center(child: Text('No features found.'));
    }

    return FutureBuilder<List<dynamic>>(
      future: _getCurrentUserProfile(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final profiles = snapshot.data;
        final profileId = (profiles?.isNotEmpty ?? false) ? profiles!.first.$id : '';

        return ListView.builder(
          itemCount: featureResults.length,
          itemBuilder: (context, index) {
            final item = featureResults[index];
            if (item['type'] == 'profile') {
              return _buildProfileResult(context, item['data']);
            } else if (item['type'] == 'post') {
              final postData = item['data'];
              if (postData == null) return const SizedBox.shrink();

              final profileIds = postData['profile_id'] as List?;
              final authorProfileId =
                  (profileIds?.isNotEmpty ?? false) ? profileIds!.first as String? : null;

              if (authorProfileId == null) {
                return const SizedBox.shrink(); // Skip if no author
              }

              return FutureBuilder<Profile>(
                future: _getAuthorProfile(context, authorProfileId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final author = snapshot.data!;
                  final post = Post(
                    id: postData['\$id'],
                    author: author,
                    timestamp: DateTime.tryParse(postData['timestamp'] ?? '') ?? DateTime.now(),
                    contentText: postData['caption'] ?? '',
                    stats: PostStats(
                      likes: postData['likes'] ?? 0,
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

  Future<List<dynamic>> _getCurrentUserProfile(BuildContext context) async {
    final appwriteService = context.read<AppwriteService>();
    final user = await appwriteService.getUser();
    if (user == null) {
      return [];
    }
    final profileDocs = await appwriteService.getUserProfiles(ownerId: user.$id);
    return profileDocs.rows;
  }

  Future<Profile> _getAuthorProfile(BuildContext context, String profileId) {
    final appwriteService = context.read<AppwriteService>();
    return appwriteService
        .getProfile(profileId)
        .then((row) => Profile.fromRow(row));
  }

  Widget _buildProfileResult(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              data['profileImageUrl'] != null && data['profileImageUrl'].isNotEmpty
                  ? NetworkImage(data['profileImageUrl'])
                  : null,
          child: data['profileImageUrl'] == null || data['profileImageUrl'].isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(data['name'] ?? 'No name'),
        subtitle: Text(data['bio'] ?? ''),
        onTap: () => context.push('/profile/${data['\$id']}'),
      ),
    );
  }
}
