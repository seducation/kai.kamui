import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PsvHomeTabscreen extends StatelessWidget {
  const PsvHomeTabscreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Featured Video Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://i.ytimg.com/vi/I2j2-DqrMgM/maxresdefault.jpg',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.black),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("1:25", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),

            // Video Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Callofdutyblackops4.png/220px-Callofdutyblackops4.png',
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Call of Duty: Black Ops 7 | Launch Trailer (PC Features Spotlight)",
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Call of Duty and Treyarch • 8.8M views • 2 weeks ago",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  )
                ],
              ),
            ),
          ],
        ),

        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Call of Duty: Black Ops 7", style: theme.textTheme.titleLarge),
        ),

        // More items would go here...
      ],
    );
  }
}
