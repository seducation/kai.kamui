import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/calls/call_service.dart';
import 'package:my_app/calls/video_call_screen.dart';
import 'package:provider/provider.dart';

class IncomingCallScreen extends StatelessWidget {
  final String roomName;

  const IncomingCallScreen({super.key, required this.roomName});

  @override
  Widget build(BuildContext context) {
    // We can also get caller info from CallService.activeCall if it matches the room
    final callService = context.watch<CallService>();
    final activeCall = callService.activeCall;

    // Basic check to ensure we are showing the right call
    // In a real scenario we'd pass the callId or object directly
    final callerName = activeCall?.caller.name ?? 'Unknown Caller';
    final callerAvatar = activeCall?.caller.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage:
                  callerAvatar != null ? NetworkImage(callerAvatar) : null,
              child: callerAvatar == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 20),

            // Name
            Text(
              callerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Incoming Video Call...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),

            const Spacer(),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'decline_btn',
                        backgroundColor: Colors.red,
                        onPressed: () {
                          if (activeCall != null) {
                            callService.rejectIncomingCall(activeCall.callId);
                          }
                          // Since CallService handles signaling, we might just need to close the screen
                          // Or wait for the stream to update. For UI responsiveness, let's pop.
                          if (context.canPop()) context.pop();
                        },
                        child: const Icon(Icons.call_end),
                      ),
                      const SizedBox(height: 8),
                      const Text('Decline',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),

                  // Answer
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'answer_btn',
                        backgroundColor: Colors.green,
                        onPressed: () async {
                          if (activeCall != null) {
                            await callService.acceptIncomingCall(activeCall);
                            // Navigate to video screen replacement
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const VideoCallScreen(),
                                ),
                              );
                            }
                          }
                        },
                        child: const Icon(Icons.videocam),
                      ),
                      const SizedBox(height: 8),
                      const Text('Answer',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
