import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:my_app/calls/call_service.dart';
import 'package:my_app/calls/video_call_screen.dart';
import 'package:provider/provider.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String roomName;

  const OutgoingCallScreen({super.key, required this.roomName});

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  CallService? _callService;

  @override
  void initState() {
    super.initState();
    _callService = context.read<CallService>();
    // We assume the call is already initiated by the caller before navigating here
    // or we are just waiting for connection.

    // Listen for connection
    _callService?.connectionStateStream.listen((state) {
      if (!mounted) return;

      if (state == lk.ConnectionState.connected) {
        // Navigate to video screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VideoCallScreen()),
        );
      } else if (state == lk.ConnectionState.disconnected) {
        // Call failed or ended
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // We can also get the callee info if we passed it or store it in CallService
    final activeCall = context.select<CallService, dynamic>(
        (s) => s.activeCall); // Use dynamic or precise type
    final receiverName = activeCall?.receiver.name ?? 'Unknown';
    final receiverAvatar = activeCall?.receiver.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundImage:
                  receiverAvatar != null ? NetworkImage(receiverAvatar) : null,
              child: receiverAvatar == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              receiverName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Calling...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () async {
                  await _callService?.endCurrentCall();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Icon(Icons.call_end),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
