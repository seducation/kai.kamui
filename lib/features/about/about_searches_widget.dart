import 'package:flutter/material.dart';
import 'package:my_app/features/about/widgets/apple_store_difference_card_widget.dart';
import 'package:my_app/features/about/widgets/carousel_screen_widget.dart';
import 'package:my_app/features/about/widgets/dashboard_widget.dart';
import 'package:my_app/features/about/widgets/shorts_rail_widget.dart';
import 'package:my_app/features/about/widgets/subscription_tile.dart';
import 'package:my_app/features/about/widgets/tool_icon.dart';
import 'package:my_app/features/about/widgets/train_widget.dart';
import 'package:my_app/features/about/widgets/travel_navigation_card.dart';

class AboutSearchesWidget extends StatelessWidget {
  const AboutSearchesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Searches'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const DashboardWidget(),
              const SizedBox(height: 20),
              const TravelNavigationCard(),
              const SizedBox(height: 20),
              TrainSearchWidget(onToggle: () {}),
              const SizedBox(height: 20),
              const CarouselScreen(),
              const SizedBox(height: 20),
              const ShortsRail(),
              const SizedBox(height: 20),
              const AppleStoreDifferenceCard(),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ToolIcon(icon: Icons.cut, label: 'Cut'),
                  ToolIcon(icon: Icons.copy, label: 'Copy'),
                  ToolIcon(icon: Icons.paste, label: 'Paste'),
                  ToolIcon(icon: Icons.select_all, label: 'Select All'),
                ],
              ),
              const SizedBox(height: 20),
              const SubscriptionTile(name: "Premium Subscription"),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
