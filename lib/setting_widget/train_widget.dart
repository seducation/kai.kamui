import 'package:flutter/material.dart';

class TrainSearchWidget extends StatelessWidget {
  final VoidCallback onToggle;

  const TrainSearchWidget({super.key, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          // Card-like container for the main search block
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: onToggle,
                    ),
                  ],
                ),
                // --- Source and Destination Section ---
                _buildStationTile(
                  'HWH - Howrah Jn',
                  icon: Icons.train,
                  isTop: true,
                ),
                _buildDividerWithSwap(context),
                _buildStationTile(
                  'BPL - Bhopal',
                  icon: Icons.train,
                  isTop: false,
                ),

                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 8),

                // --- Date and Tatkal Section ---
                _buildDateAndTatkalRow(),

                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 8),

                // --- Alternate Travel Plan Section ---
                _buildAlternatePlanRow(),

                // --- Search Trains Button ---
                const SizedBox(height: 16),
                _buildSearchButton(context),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildStationTile(String title, {required IconData icon, required bool isTop}) {
    return Padding(
      padding: EdgeInsets.only(top: isTop ? 10.0 : 0.0, bottom: isTop ? 0.0 : 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerWithSwap(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Align the divider with the text
          const SizedBox(width: 10), // Adjust to align with the icons
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -10), // Raise the divider slightly
              child: const Divider(height: 1, color: Color(0xFFE0E0E0)),
            ),
          ),
          // Swap Button
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(
              Icons.unfold_more,
              size: 20,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndTatkalRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          const Icon(Icons.calendar_today, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          // Date Text
          const Text(
            'Sun, 23 Nov',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          // Cancel/Clear Date Icon
          const Icon(
            Icons.close,
            size: 20,
            color: Colors.grey,
          ),
          const Spacer(),
          // Tatkal Buttons
          _buildTatkalPill('Tomorrow'),
          const SizedBox(width: 8),
          _buildTatkalPill('Day After'),
        ],
      ),
    );
  }

  Widget _buildTatkalPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF008000), // Dark green background
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Tatkal open',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatePlanRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          // Checkbox (Unchecked state from image)
          Checkbox(
            value: false,
            onChanged: (bool? newValue) {
              // Handle checkbox state change (not implemented here)
            },
            activeColor: Colors.blue,
          ),
          // Text for the option
          const Expanded(
            child: Text(
              'Opt For Alternate Travel Plan or Free Cancellation',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 10),
          // Placeholder for the loyalty/shield icon
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              // Using a simple color placeholder as the exact image is complex
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars,
              color: Colors.yellow,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(102),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Action to perform on button press
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Searching Trains...')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Search Trains',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
