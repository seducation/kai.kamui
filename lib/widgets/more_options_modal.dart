import 'package:flutter/material.dart';

class MoreOptionsModal extends StatelessWidget {
  const MoreOptionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Send friend request'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Send friend request functionality not implemented yet.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('Subscribe'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Subscribe functionality not implemented yet.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_off),
            title: const Text('Mute'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mute functionality not implemented yet.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Block functionality not implemented yet.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Report'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Report functionality not implemented yet.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
