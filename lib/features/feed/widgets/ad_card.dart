import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ad_item.dart';
import '../controllers/feed_controller.dart';

/// Widget to render a sponsored ad in the feed
class AdCard extends StatelessWidget {
  final AdItem ad;
  final FeedController controller;

  const AdCard({super.key, required this.ad, required this.controller});

  Future<void> _handleAdClick() async {
    // Track click
    controller.trackSignal(ad.adId, 'ad_click');

    // Open ad link if available
    if (ad.linkUrl != null) {
      final uri = Uri.parse(ad.linkUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sponsored label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Sponsored',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),

          // Ad media
          GestureDetector(
            onTap: _handleAdClick,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Image.network(
                    ad.mediaUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ad content
          if (ad.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.content,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // CTA button
                  if (ad.linkUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleAdClick,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Learn More'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
