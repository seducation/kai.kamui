import 'package:flutter/material.dart';
import '../services/proactive_alert/proactive_alert_engine.dart';
import '../services/proactive_alert/machine_abstraction.dart';
import '../services/proactive_alert/alert_intent.dart';
import '../services/mission_choreographer.dart';
import '../coordination/motor_system.dart';
import '../specialized/systems/simulation_agent.dart';
import '../specialized/systems/thermal_controller.dart';
import '../specialized/systems/user_context.dart';
import '../services/proactive_alert/affect_engine.dart';
import '../services/proactive_alert/affective_state.dart';

/// UI for managing and connecting "Machinery" (MAL components) ⚙️🦾
class MachineControlScreen extends StatefulWidget {
  const MachineControlScreen({super.key});

  @override
  State<MachineControlScreen> createState() => _MachineControlScreenState();
}

class _MachineControlScreenState extends State<MachineControlScreen> {
  final ProactiveAlertEngine _pae = ProactiveAlertEngine();
  final MotorSystem _motor = MotorSystem();
  SimulationAgent? _simAgent;
  bool _isSimRunning = false;

  void _toggleSimulation() {
    setState(() {
      _isSimRunning = !_isSimRunning;
      if (_isSimRunning) {
        final thermal =
            _pae.machines.whereType<ThermalController>().firstOrNull;
        if (thermal != null) {
          _simAgent = SimulationAgent(thermal);
          _simAgent!.start();
        }
      } else {
        _simAgent?.stop();
        _simAgent = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Machine Control & Connectors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 2)),
        builder: (context, snapshot) {
          final machines = _pae.machines;
          final alerts = _pae.activeAlerts;
          final connectors = _motor.availableActuators;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('📡 System Connectors (Actuators)'),
              _buildConnectorGrid(connectors),
              const SizedBox(height: 12),
              _buildMultiAiIndicator(),
              const SizedBox(height: 12),
              _buildPersonnelSelector(),
              const SizedBox(height: 12),
              _buildMissionControl(),
              const SizedBox(height: 24),
              _buildSectionHeader('⚙️ Registered Machinery (MAL)'),
              if (machines.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No machines registered.',
                      style: TextStyle(color: Colors.grey)),
                ))
              else
                ...machines.map((m) => _buildMachineCard(m)),
              const SizedBox(height: 24),
              _buildSectionHeader('📜 Proactive Alert History'),
              _buildAlertHistory(alerts),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildConnectorGrid(List<String> connectors) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3,
      ),
      itemCount: connectors.length,
      itemBuilder: (context, index) {
        final name = connectors[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMachineCard(Machine machine) {
    IconData typeIcon;
    Color typeColor;
    switch (machine.type) {
      case DeviceType.robot:
        typeIcon = Icons.precision_manufacturing;
        typeColor = Colors.orange;
        break;
      case DeviceType.server:
        typeIcon = Icons.dns;
        typeColor = Colors.blue;
        break;
      case DeviceType.phone:
        typeIcon = Icons.smartphone;
        typeColor = Colors.green;
        break;
    }

    final asv = machine.affectiveState;
    final bias = AffectEngine().calculateBias(machine.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: typeColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(machine.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                        'DOI: ${machine.type.name.toUpperCase()} | Priority: ${machine.priorityLevel.name.toUpperCase()}',
                        style:
                            const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(machine.controlPolicy.mode,
                      style: TextStyle(fontSize: 10, color: typeColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAffectiveState(asv, bias),
            const Divider(),
            Row(
              children: [
                const Text('AI Autonomous Control',
                    style: TextStyle(fontSize: 12)),
                const Spacer(),
                Switch(
                  value: machine.controlPolicy.isAiControlled,
                  onChanged: (val) => setState(
                      () => machine.controlPolicy.isAiControlled = val),
                  activeThumbColor: Colors.teal,
                ),
              ],
            ),
            Row(
              children: [
                const Text('Connected Connector:',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: machine.controlPolicy.connectedConnectorName,
                    hint: const Text('None', style: TextStyle(fontSize: 12)),
                    items: _motor.availableActuators.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() =>
                          machine.controlPolicy.connectedConnectorName = val);
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text('Sensors:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 12,
              children: machine.sensors.entries.map((e) {
                final isOverLimit =
                    machine.safetyEnvelope.limits.containsKey(e.key) &&
                        e.value is num &&
                        e.value > machine.safetyEnvelope.limits[e.key];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                      Text('${e.value}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOverLimit ? Colors.red : Colors.black,
                          )),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Manual Actuators:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: machine.machineActuators.map((a) {
                return ElevatedButton.icon(
                  onPressed: () => _manualActuate(machine, 'ACTUATE_COOLING'),
                  icon: const Icon(Icons.flash_on, size: 14),
                  label: Text(a.name, style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    foregroundColor: Colors.orange[800],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiAiIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.hub, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Multi-AI Coordination Hub',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Shared Connectors: JARVIS (PAE) + Stress Agent',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Switch(
                value: _isSimRunning,
                onChanged: (_) => _toggleSimulation(),
                activeThumbColor: Colors.purple,
              ),
            ],
          ),
          if (_isSimRunning)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertHistory(List<AlertIntent> alerts) {
    if (alerts.isEmpty) {
      return const Center(child: Text('No proactive alerts logged.'));
    }
    return Column(
      children: alerts.reversed.take(5).map((a) {
        return ListTile(
          dense: true,
          leading: Icon(
            a.isHighRisk ? Icons.warning : Icons.info_outline,
            color: a.isHighRisk ? Colors.red : Colors.blue,
          ),
          title: Text(a.description, style: const TextStyle(fontSize: 12)),
          subtitle: Text(
              'Domain: ${a.domain.name} | Conf: ${(a.confidence * 100).toInt()}%',
              style: const TextStyle(fontSize: 10)),
          trailing: Text(a.id.split('_').last,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        );
      }).toList(),
    );
  }

  Widget _buildPersonnelSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personnel Management',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Switch between Stark (Sir) and Operator styles',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          DropdownButton<PersonnelProfile>(
            value: userContext.personnel,
            items: PersonnelProfile.values.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => userContext.personnel = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissionControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mission Choreography',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Ready: Deep Compute Synchronization',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () =>
                    MissionChoreographer().beginDeepComputeMission(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('LAUNCH',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAffectiveState(AffectiveState asv, EmotionBias bias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AFFECTIVE STATE (ASV)',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1)),
            Text(bias.posture.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: bias.lightColor == 'Red'
                        ? Colors.red
                        : bias.lightColor == 'Yellow'
                            ? Colors.orange
                            : Colors.blue)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildAsvBadge('CONF', asv.confidence, Colors.blue),
            const SizedBox(width: 4),
            _buildAsvBadge('STRS', asv.stress, Colors.red),
            const SizedBox(width: 4),
            _buildAsvBadge('URG', asv.urgency, Colors.orange),
            const Spacer(),
            Text('Speed: ${bias.speedMultiplier.toStringAsFixed(1)}x',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAsvBadge(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label: ${(value * 100).toInt()}%',
          style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _manualActuate(Machine machine, String command) async {
    // print('🦾 Manual Actuation: $command on ${machine.name}');
    for (final actuator in machine.machineActuators) {
      await actuator.act(command);
    }
    setState(() {});
  }
}
