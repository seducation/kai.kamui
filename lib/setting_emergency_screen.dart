import 'package:flutter/material.dart';

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });
}

class SettingEmergencyScreen extends StatefulWidget {
  const SettingEmergencyScreen({super.key});

  @override
  State<SettingEmergencyScreen> createState() => _SettingEmergencyScreenState();
}

class _SettingEmergencyScreenState extends State<SettingEmergencyScreen> {
  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(name: 'Jane Doe', phone: '111-222-3333', relationship: 'Sister'),
    EmergencyContact(name: 'John Smith', phone: '444-555-6666', relationship: 'Friend'),
  ];

  bool _emergencySosEnabled = true;

  void _addContact() {
    // In a real app, this would open a contact picker or a form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adding a new contact...')),
    );
  }

  void _removeContact(EmergencyContact contact) {
    setState(() {
      _emergencyContacts.remove(contact);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${contact.name} has been removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'Emergency Contacts'),
          Card(
            child: Column(
              children: [
                ..._emergencyContacts.map((contact) {
                  return ListTile(
                    title: Text(contact.name),
                    subtitle: Text(contact.relationship),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeContact(contact),
                    ),
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                  title: const Text('Add Emergency Contact'),
                  onTap: _addContact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Emergency SOS'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Emergency SOS'),
                  subtitle: const Text('Press the power button 5 times to call emergency services'),
                  value: _emergencySosEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _emergencySosEnabled = value;
                    });
                  },
                  secondary: const Icon(Icons.sos),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'When you use Emergency SOS, your device automatically calls the local emergency number. You can also choose to send a message to your emergency contacts.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
