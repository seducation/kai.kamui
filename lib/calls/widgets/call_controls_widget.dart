import 'package:flutter/material.dart';
import 'package:my_app/calls/services/media_manager.dart';

class CallControlsWidget extends StatelessWidget {
  final MediaManager mediaManager;
  final VoidCallback onEndCall;

  const CallControlsWidget({
    super.key,
    required this.mediaManager,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    // We listen to the MediaState via a simplified StreamBuilder or ValueListenable
    // Since MediaManager exposes mediaState but not as a stream directly for individual properties,
    // we might need to wrap it or rely on parent rebuilding.
    // However, to make this widget reactive, let's assume the parent rebuilds it or we can modify MediaManager to be a ChangeNotifier.
    // For now, let's use a StatefulWidget wrapper or simple buttons that toggle and assume local state updates fast.
    // Better yet, let's make this a StatefulWidget to handle its own UI updates or listen to a stream if available.

    // Actually, MediaManager in the previous steps didn't extend ChangeNotifier.
    // It has a mediaState getter.
    // To properly update icons, we should probably wrap this in a StatefulWidget
    // and rely on setState when buttons are pressed, assuming the operation succeeds.
    // Or simpler: pass the current state in.

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute/Unmute Audio
        _ControlButton(
          icon: mediaManager.mediaState.isAudioEnabled
              ? Icons.mic
              : Icons.mic_off,
          color: mediaManager.mediaState.isAudioEnabled
              ? Colors.white
              : Colors.red,
          onPressed: () async {
            await mediaManager.toggleMicrophone();
            (context as Element).markNeedsBuild(); // Simple rebuild trigger
          },
        ),

        // Enable/Disable Video
        _ControlButton(
          icon: mediaManager.mediaState.isVideoEnabled
              ? Icons.videocam
              : Icons.videocam_off,
          color: mediaManager.mediaState.isVideoEnabled
              ? Colors.white
              : Colors.red,
          onPressed: () async {
            await mediaManager.toggleVideo();
            (context as Element).markNeedsBuild();
          },
        ),

        // Switch Camera
        _ControlButton(
          icon: Icons.cameraswitch,
          color: Colors.white,
          onPressed: () async {
            await mediaManager.switchCamera();
            (context as Element).markNeedsBuild();
          },
        ),

        // End Call
        _ControlButton(
          icon: Icons.call_end,
          color: Colors.red,
          onPressed: onEndCall,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: color,
        onPressed: onPressed,
        iconSize: 32,
      ),
    );
  }
}
