import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HeroBanner extends StatefulWidget {
  final List<HeroItem> items;

  const HeroBanner({super.key, required this.items});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _HeroBannerItem(item: item);
            },
          ),

          // Indicator
          Positioned(
            bottom: 20,
            child: SmoothPageIndicator(
              controller: _controller,
              count: widget.items.length,
              effect: WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Colors.white,
                dotColor: Colors.white24,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class HeroItem {
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;

  HeroItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
  });
}

class _HeroBannerItem extends StatelessWidget {
  final HeroItem item;

  const _HeroBannerItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[700]!,
              child: Container(
                color: Colors.black,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[800],
              child: const Icon(Icons.error, color: Colors.white),
            ),
          ),
        ),

        // Gradient Overlay (bottom fade)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color.fromRGBO(0, 0, 0, 0.6),
                  const Color.fromRGBO(0, 0, 0, 0.8),
                ],
              ),
            ),
          ),
        ),

        // Content
        Positioned(
          left: 20,
          right: 20,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 25),

              // Buttons Row
              Row(
                children: [
                  // CTA Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "Accept Free Trial",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Add Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  )
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
