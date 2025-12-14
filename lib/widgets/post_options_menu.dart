import 'package:flutter/material.dart';
import 'package:my_app/model/post.dart';
import 'package:my_app/widgets/add_to_playlist.dart';

class PostOptionsMenu extends StatelessWidget {
  final Post post;
  final String profileId;

  const PostOptionsMenu(
      {super.key, required this.post, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.more_horiz, color: Colors.grey[600], size: 22),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: const Text('Add to Playlist'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => AddToPlaylistScreen(
                        postId: post.id,
                        profileId: profileId,
                      ),
                    );
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.high_quality),
                  title: Text('Quality Setting'),
                ),
                const ListTile(
                  leading: Icon(Icons.translate),
                  title: Text('Translate Transcript'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
