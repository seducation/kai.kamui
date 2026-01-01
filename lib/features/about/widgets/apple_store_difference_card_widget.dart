import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppleStoreDifferenceCard extends StatelessWidget {
  const AppleStoreDifferenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 28, height: 1.1),
              children: [
                TextSpan(
                  text: "The gvone Store difference. ",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: "Even more reasons to shop with us.",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF86868b), // Apple's distinct grey
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 240, // Height constraint for the horizontal list
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24), // Left/Right padding for the list
            physics: const BouncingScrollPhysics(), // iOS style bounce
            children: [
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(), // Push content roughly to middle/top visually
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(text: "No Cost EMI."),
                          _buildSuperscript("§"),
                          const TextSpan(text: " Plus Instant\nCashback."),
                          _buildSuperscript("§§"),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(width: 20), // Spacing between cards
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Stack(
                        children: [
                          Icon(CupertinoIcons.device_laptop, size: 36, color: Colors.blue.shade600),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(CupertinoIcons.device_phone_portrait, size: 20, color: Colors.blue.shade600),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(CupertinoIcons.arrow_2_circlepath, size: 18, color: Colors.blue.shade600),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: "Exchange your smartphone, ",
                            style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: "get ₹3350.00 – ₹64000.00 credit towards a new one.*"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_shipping_outlined, color: Colors.green.shade600, size: 40),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 15, color: Colors.black, height: 1.4),
                        children: [
                          TextSpan(
                            text: "Free delivery, ",
                            style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: "on all orders. Get it delivered to your doorstep quickly and safely."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: 300, // Fixed width for the cards
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Large rounded corners
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  WidgetSpan _buildSuperscript(String text) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.top,
      child: Transform.translate(
        offset: const Offset(2, 0), // Move slightly right
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
