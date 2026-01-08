import 'package:flutter/material.dart';
import '../services/proactive_alert/swarm_engine.dart';
import '../services/proactive_alert/swarm_affect.dart';
import '../services/proactive_alert/proactive_alert_engine.dart';

/// IMOTION SCREEN (Emotion Visualization UI) 🎛️🧠
///
/// Visualizes the system's "behavioral weather" using swarm affect data.
class ImotionScreen extends StatefulWidget {
  const ImotionScreen({super.key});

  @override
  State<ImotionScreen> createState() => _ImotionScreenState();
}

class _ImotionScreenState extends State<ImotionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final SwarmEngine _swarm = SwarmEngine();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final affect = _swarm.calculateSwarmAffect();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      appBar: AppBar(
        title: const Text('IMOTION HUD',
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _swarm.propagateAffect()),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background Grid Effect
          _buildBackgroundGrid(),

          // 2. Central Swarm Core & Radial Rings
          Center(
            child: _buildSwarmHub(affect),
          ),

          // 3. Top Corner Badge
          Positioned(
            top: 20,
            left: 20,
            child: _buildModeBadge(affect),
          ),

          // 4. Emotional Weather Bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildWeatherBar(affect),
          ),

          // 5. Agent Heat Map (Bottom Side)
          Positioned(
            bottom: 120,
            right: 20,
            child: _buildAgentMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGrid() {
    return Opacity(
      opacity: 0.05,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
        itemBuilder: (_, __) => Container(
            decoration:
                BoxDecoration(border: Border.all(color: Colors.blueAccent))),
      ),
    );
  }

  Widget _buildSwarmHub(SwarmAffect affect) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Pulse speed controlled by urgency
        final pulseVal = _pulseController.value;
        final sizeMult = 1.0 + (pulseVal * 0.1 * (1.0 + affect.meanUrgency));

        return Transform.scale(
          scale: sizeMult,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial Rings (Confidence to Urgency)
              _buildRadialRing(0.8, affect.meanConfidence, Colors.cyan),
              _buildRadialRing(0.65, affect.meanCuriosity, Colors.purple),
              _buildRadialRing(0.5, affect.meanStress, Colors.orange),
              _buildRadialRing(0.35, affect.meanUrgency, Colors.red),

              // Swarm Core Node Cloud
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getColorForMode(affect.dominantMode)
                          .withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${(affect.coherence * 100).toInt()}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadialRing(double radiusMult, double intensity, Color color) {
    return Container(
      width: 400 * radiusMult,
      height: 400 * radiusMult,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.1 + (intensity * 0.4)),
          width: 2 + (intensity * 10),
        ),
      ),
    );
  }

  Widget _buildModeBadge(SwarmAffect affect) {
    final color = _getColorForMode(affect.dominantMode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COHERENCE: ${(affect.coherence * 100).toInt()}%',
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          Text('MODE: ${affect.dominantMode.name.toUpperCase()}',
              style: TextStyle(
                  fontSize: 18,
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildWeatherBar(SwarmAffect affect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weatherLabel('CALM', affect.dominantMode == SwarmMode.calm),
              _weatherLabel('FLOW', affect.dominantMode == SwarmMode.flow),
              _weatherLabel('ALERT', affect.dominantMode == SwarmMode.alert),
              _weatherLabel(
                  'DEFENSIVE', affect.dominantMode == SwarmMode.defensive),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: affect.meanStress,
            backgroundColor: Colors.blueGrey.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForMode(affect.dominantMode)),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _weatherLabel(String label, bool active) {
    return Text(label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? Colors.white : Colors.grey.withValues(alpha: 0.5),
          letterSpacing: 1.5,
        ));
  }

  Widget _buildAgentMap() {
    final machines = ProactiveAlertEngine().machines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('AGENT COORDINATES',
            style:
                TextStyle(fontSize: 8, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        ...machines.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getStressColor(m.affectiveState.stress),
                shape: BoxShape.circle,
              ),
            )),
      ],
    );
  }

  Color _getColorForMode(SwarmMode mode) {
    switch (mode) {
      case SwarmMode.calm:
        return Colors.green;
      case SwarmMode.flow:
        return Colors.cyan;
      case SwarmMode.alert:
        return Colors.yellow;
      case SwarmMode.defensive:
        return Colors.red;
      case SwarmMode.explore:
        return Colors.purple;
      case SwarmMode.recovery:
        return Colors.blue;
    }
  }

  Color _getStressColor(double stress) {
    if (stress < 0.3) return Colors.green;
    if (stress < 0.6) return Colors.orange;
    return Colors.red;
  }
}
