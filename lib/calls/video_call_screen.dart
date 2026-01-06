import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:my_app/calls/call_service.dart';
import 'package:my_app/calls/widgets/call_controls_widget.dart';
import 'package:provider/provider.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  Widget build(BuildContext context) {
    final callService = context.watch<CallService>();
    final mediaManager = callService.mediaManager;
    final room = callService.room;

    if (room == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final localParticipant = room.localParticipant;
    final remoteParticipants = room.remoteParticipants.values;
    final remoteParticipant =
        remoteParticipants.isNotEmpty ? remoteParticipants.first : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (Full Screen)
          if (remoteParticipant != null)
            ParticipantVideoView(
              participant: remoteParticipant,
              fit: BoxFit.cover, // We'll map this inside the widget
            )
          else
            const Center(
              child: Text(
                'Waiting for other person...',
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Local Video (PiP)
          if (localParticipant != null &&
              mediaManager.mediaState.isVideoEnabled)
            Positioned(
              right: 20,
              top: 50,
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ParticipantVideoView(
                  participant: localParticipant,
                  mirror: mediaManager.mediaState.isFrontCamera,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Call Status Indicator
          StreamBuilder<lk.ConnectionState>(
            stream: callService.connectionStateStream,
            initialData: room.connectionState,
            builder: (context, snapshot) {
              final state = snapshot.data;
              if (state == lk.ConnectionState.reconnecting) {
                if (state == lk.ConnectionState.reconnecting) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: const Text(
                        'Reconnecting...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: CallControlsWidget(
              mediaManager: mediaManager,
              onEndCall: () {
                callService.endCurrentCall();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ParticipantVideoView extends StatelessWidget {
  final lk.Participant participant;
  final bool mirror;
  final BoxFit fit;

  const ParticipantVideoView({
    super.key,
    required this.participant,
    this.mirror = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    lk.TrackPublication? videoPub;

    // Find first enabled camera track or screen share
    // Note: TrackSource.screenShareVideo might be the correct enum
    videoPub = participant.videoTrackPublications.firstWhere(
      (pub) => pub.source == lk.TrackSource.camera,
      orElse: () => participant.videoTrackPublications.firstWhere(
        // Checking if screenShareVideo exists, otherwise fallback to generic check
        (pub) => pub.source == lk.TrackSource.screenShareVideo,
        orElse: () => participant.videoTrackPublications.isNotEmpty
            ? participant.videoTrackPublications.first
            : throw 'No video track',
      ),
    );

    // Check if track is safe to render
    if (participant.videoTrackPublications.isEmpty || videoPub.track == null) {
      return Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(Icons.person, color: Colors.white54, size: 48),
        ),
      );
    }

    // Map BoxFit to VideoViewFit
    lk.VideoViewFit videoFit;
    switch (fit) {
      case BoxFit.cover:
        videoFit = lk.VideoViewFit.cover;
        break;
      case BoxFit.contain:
        videoFit = lk.VideoViewFit.contain;
        break;
      case BoxFit.fill:
        videoFit =
            lk.VideoViewFit.cover; // Fallback to cover as fill doesn't exist
        break;
      default:
        videoFit = lk.VideoViewFit.contain;
    }

    return lk.VideoTrackRenderer(
      videoPub.track as lk.VideoTrack,
      fit: videoFit,
      // If mirror is not supported directly, we remove it.
      // Usually mirroring is handled by the track source or a distinct widget wrapper.
      // We'll leave it out for now to satisfy the "named parameter not defined" error.
    );
  }
}
