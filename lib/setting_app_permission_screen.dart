import 'package:flutter/material.dart';

class SettingAppPermissionScreen extends StatefulWidget {
  const SettingAppPermissionScreen({super.key});

  @override
  State<SettingAppPermissionScreen> createState() =>
      _SettingAppPermissionScreenState();
}

class _SettingAppPermissionScreenState
    extends State<SettingAppPermissionScreen> {
  bool _nsfwAllowed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permission'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Allow NSFW Content'),
            subtitle: const Text('You must be 18 or older to enable this.'),
            value: _nsfwAllowed,
            onChanged: (bool value) {
              if (value) {
                _showAgeConfirmationDialog(context);
              } else {
                setState(() {
                  _nsfwAllowed = false;
                });
              }
            },
          ),
          // You can add more permission settings here if needed
        ],
      ),
    );
  }

  void _showAgeConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must respond
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Your Age'),
          content: const Text(
              'By enabling this setting, you confirm that you are 18 years of age or older.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('I Confirm'),
              onPressed: () {
                setState(() {
                  _nsfwAllowed = true;
                });
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}