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
    final appwriteService = context.read<AppwriteService>();
    final featureResults = searchResults
        .where(
          (result) => result['type'] == 'post' || result['type'] == 'profile',
        )
        .toList();

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
        final profileId =
            (profiles?.isNotEmpty ?? false) ? profiles!.first.$id : '';

        return ListView.builder(
          itemCount: featureResults.length + 1, // Add 1 for AI Overview
          itemBuilder: (context, index) {
            if (index == 0) {
              return const AiOverviewWidget();
            }

            final item = featureResults[index - 1];
            if (item['type'] == 'profile') {
              return _buildProfileResult(context, item['data']);
            } else if (item['type'] == 'post') {
              final postData = item['data'];
              if (postData == null) return const SizedBox.shrink();

              final profileIds = postData['profile_id'] as List?;
              final authorProfileId = (profileIds?.isNotEmpty ?? false)
                  ? profileIds!.first as String?
                  : null;

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

                  final originalAuthorIds = postData['author_id'] as List?;
                  final originalAuthorId =
                      (originalAuthorIds?.isNotEmpty ?? false)
                          ? originalAuthorIds!.first as String?
                          : null;

                  PostType type = PostType.text;
                  List<String> mediaUrls = [];
                  final fileIds = postData['file_ids'] as List?;
                  if (fileIds != null && fileIds.isNotEmpty) {
                    type = PostType
                        .image; // Assuming image for now, could be video
                    mediaUrls = fileIds
                        .map((id) => appwriteService.getFileViewUrl(id))
                        .toList();
                  }

                  if (originalAuthorId != null &&
                      originalAuthorId != authorProfileId) {
                    return FutureBuilder<Profile>(
                      future: _getAuthorProfile(context, originalAuthorId),
                      builder: (context, originalAuthorSnapshot) {
                        if (originalAuthorSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        Profile? originalAuthor;
                        if (originalAuthorSnapshot.hasData) {
                          originalAuthor = originalAuthorSnapshot.data!;
                        }

                        final post = Post(
                          id: postData['\$id'],
                          author: author,
                          originalAuthor: originalAuthor,
                          timestamp:
                              DateTime.tryParse(postData['timestamp'] ?? '') ??
                                  DateTime.now(),
                          contentText: postData['caption'] ?? '',
                          stats: PostStats(
                            likes: postData['likes'] ?? 0,
                            comments: 0,
                            shares: 0,
                            views: 0,
                          ),
                          authorIds: (postData['author_id'] as List<dynamic>?)
                              ?.map((e) => e as String)
                              .toList(),
                          profileIds: (postData['profile_id'] as List<dynamic>?)
                              ?.map((e) => e as String)
                              .toList(),
                          mediaUrls: mediaUrls,
                          linkUrl: postData['linkUrl'] as String?,
                          linkTitle: postData['titles'] as String? ?? '',
                          type: type,
                        );
                        return PostItem(post: post, profileId: profileId);
                      },
                    );
                  } else {
                    final post = Post(
                      id: postData['\$id'],
                      author: author,
                      timestamp:
                          DateTime.tryParse(postData['timestamp'] ?? '') ??
                              DateTime.now(),
                      contentText: postData['caption'] ?? '',
                      stats: PostStats(
                        likes: postData['likes'] ?? 0,
                        comments: 0,
                        shares: 0,
                        views: 0,
                      ),
                      authorIds: (postData['author_id'] as List<dynamic>?)
                          ?.map((e) => e as String)
                          .toList(),
                      profileIds: (postData['profile_id'] as List<dynamic>?)
                          ?.map((e) => e as String)
                          .toList(),
                      mediaUrls: mediaUrls,
                      linkUrl: postData['linkUrl'] as String?,
                      linkTitle: postData['titles'] as String? ?? '',
                      type: type,
                    );
                    return PostItem(post: post, profileId: profileId);
                  }
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
    final profileDocs =
        await appwriteService.getUserProfiles(ownerId: user.$id);
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
          backgroundImage: data['profileImageUrl'] != null &&
                  data['profileImageUrl'].isNotEmpty
              ? NetworkImage(data['profileImageUrl'])
              : null,
          child:
              data['profileImageUrl'] == null || data['profileImageUrl'].isEmpty
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

class AiOverviewWidget extends StatefulWidget {
  const AiOverviewWidget({super.key});

  @override
  State<AiOverviewWidget> createState() => _AiOverviewWidgetState();
}

class _AiOverviewWidgetState extends State<AiOverviewWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
            Colors.pink.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.blue, Colors.purple, Colors.pink],
                  ).createShader(bounds),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based on your search results, here is a quick overview of the top features and profiles relevant to your query.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'The search results include a variety of content types. Key profiles found include experts in tech and design, while the posts cover recent updates in the ecosystem.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip('Recent Posts'),
                      const SizedBox(width: 8),
                      _buildChip('Top Profiles'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
