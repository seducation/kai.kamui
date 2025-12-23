import 'package:flutter/material.dart';

import '../models/carousel_item.dart';

/// Widget to render a horizontal scrolling carousel in the feed
class CarouselWidget extends StatelessWidget {
  final CarouselItem carousel;
  final Function(String)? onItemTap;

  const CarouselWidget({super.key, required this.carousel, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  carousel.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (carousel.items.length > 5)
                  TextButton(
                    onPressed: () {
                      // Navigate to full list
                    },
                    child: const Text('See All'),
                  ),
              ],
            ),
          ),

          // Horizontal scrolling list
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: carousel.items.length,
              itemBuilder: (context, index) {
                final item = carousel.items[index];
                return _CarouselItemWidget(
                  item: item,
                  onTap: onItemTap != null ? () => onItemTap!(item.id) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual item within the carousel
class _CarouselItemWidget extends StatelessWidget {
  final CarouselItemData item;
  final VoidCallback? onTap;

  const _CarouselItemWidget({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Circular image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),

              child: ClipOval(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),

            // Subtitle (if present)
            if (item.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                item.subtitle!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
