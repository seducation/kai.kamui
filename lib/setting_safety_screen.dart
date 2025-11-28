import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingSafetyScreen extends StatefulWidget {
  const SettingSafetyScreen({super.key});

  @override
  State<SettingSafetyScreen> createState() => _SettingSafetyScreenState();
}

class _SettingSafetyScreenState extends State<SettingSafetyScreen> {
  bool _sensitiveContentFilter = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          ListTile(
            leading: const Icon(Icons.emergency_outlined),
            title: const Text('Emergency'),
            subtitle: const Text('Manage your emergency contacts and settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.go('/setting_emergency');
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Sensitive Content Filter'),
            subtitle: const Text(
                'Blur photos and videos that may contain sensitive content'),
            value: _sensitiveContentFilter,
            onChanged: (bool value) {
              setState(() {
                _sensitiveContentFilter = value;
              });
            },
            secondary: const Icon(Icons.visibility_off_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Blocked Accounts'),
            subtitle: const Text('Manage the accounts you have blocked'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Blocked Accounts screen'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Login & Security'),
            subtitle: const Text('Manage 2FA, password, and login alerts'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Login & Security screen'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
