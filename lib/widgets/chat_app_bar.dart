import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/profile_page_screen.dart';
import 'package:shimmer/shimmer.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String urlImage;
  final String title;
  final String onOff;
  final VoidCallback? onCallPressed;

  const ChatAppBar({
    super.key,
    required this.urlImage,
    required this.title,
    required this.onOff,
    this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChannelProfilePage(
                name: title,
                imageUrl: urlImage,
              ),
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: urlImage,
                  fit: BoxFit.fill,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  onOff,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: onCallPressed,
          icon: const Icon(Icons.call),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_contact',
              child: Text('View Contact'),
            ),
            const PopupMenuItem(
              value: 'media',
              child: Text('Media, links, and docs'),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Text('Search'),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Text('Mute notifications'),
            ),
            const PopupMenuItem(
              value: 'wallpaper',
              child: Text('Wallpaper'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
