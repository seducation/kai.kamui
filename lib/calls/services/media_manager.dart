import 'dart:async';
import 'dart:developer';
import 'package:livekit_client/livekit_client.dart';
import 'package:my_app/calls/models/call_models.dart';
import 'package:my_app/calls/utils/permission_handler.dart';

/// Manages media tracks and renderers
class MediaManager {
  Room? _room;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;

  final _localVideoController = StreamController<VideoTrack?>.broadcast();
  final _remoteVideoController = StreamController<VideoTrack?>.broadcast();
  final _participantsController =
      StreamController<List<Participant>>.broadcast();

  Stream<VideoTrack?> get localVideoStream => _localVideoController.stream;
  Stream<VideoTrack?> get remoteVideoStream => _remoteVideoController.stream;
  Stream<List<Participant>> get participantsStream =>
      _participantsController.stream;

  MediaState _mediaState = const MediaState();
  MediaState get mediaState => _mediaState;

  Room? get room => _room;
  LocalVideoTrack? get localVideoTrack => _localVideoTrack;
  LocalAudioTrack? get localAudioTrack => _localAudioTrack;

  /// Set the room instance
  void setRoom(Room room) {
    _room = room;
    _setupRoomListeners();
  }

  /// Setup listeners for room events
  void _setupRoomListeners() {
    if (_room == null) return;

    _room!.addListener(() {
      _participantsController.add(_room!.remoteParticipants.values.toList());
    });

    // Listen to track subscriptions
    _room!.addListener(() {
      for (final participant in _room!.remoteParticipants.values) {
        for (final trackPublication in participant.videoTrackPublications) {
          if (trackPublication.track != null) {
            _remoteVideoController.add(trackPublication.track as VideoTrack);
          }
        }
      }
    });
  }

  /// Initialize local media tracks
  Future<void> initializeLocalMedia({
    bool enableVideo = true,
    bool enableAudio = true,
  }) async {
    try {
      // Initialize state with request intent
      _mediaState = MediaState(
        isVideoEnabled: enableVideo,
        isAudioEnabled: enableAudio,
        isFrontCamera: true,
        isSpeakerOn: true,
      );

      if (enableVideo) {
        final hasVideoPerm =
            await CallPermissionHandler.requestCameraPermission();
        if (hasVideoPerm) {
          try {
            _localVideoTrack = await LocalVideoTrack.createCameraTrack(
              const CameraCaptureOptions(
                cameraPosition: CameraPosition.front,
                // Use h540_169 for better performance/battery on mobile
                params: VideoParametersPresets.h540_169,
              ),
            );
            await _localVideoTrack?.start();
            _localVideoController.add(_localVideoTrack);
            log('Local video track initialized');
          } catch (e) {
            log('Failed to create video track: $e');
            _mediaState = _mediaState.copyWith(isVideoEnabled: false);
          }
        } else {
          log('Camera permission denied');
          _mediaState = _mediaState.copyWith(isVideoEnabled: false);
        }
      }

      if (enableAudio) {
        final hasAudioPerm =
            await CallPermissionHandler.requestMicrophonePermission();
        if (hasAudioPerm) {
          try {
            _localAudioTrack = await LocalAudioTrack.create();
            await _localAudioTrack?.start();
            log('Local audio track initialized');
          } catch (e) {
            log('Failed to create audio track: $e');
            _mediaState = _mediaState.copyWith(isAudioEnabled: false);
          }
        } else {
          log('Microphone permission denied');
          _mediaState = _mediaState.copyWith(isAudioEnabled: false);
        }
      }
    } catch (e) {
      log('Error initializing local media: $e');
      // Ensure we don't leave inconsistent state
      _mediaState = const MediaState(
        isVideoEnabled: false,
        isAudioEnabled: false,
      );
      rethrow;
    }
  }

  /// Publish local tracks to the room
  Future<void> publishLocalTracks() async {
    if (_room == null) {
      log('Cannot publish tracks: Room is null');
      return;
    }

    try {
      if (_localVideoTrack != null) {
        // TODO: Enable simulcast once correct API parameter is identified in future SDK versions
        // Currently relying on adaptiveStream in RoomOptions
        await _room!.localParticipant?.publishVideoTrack(_localVideoTrack!);
        log('Published video track');
      }

      if (_localAudioTrack != null) {
        await _room!.localParticipant?.publishAudioTrack(_localAudioTrack!);
        log('Published audio track');
      }
    } catch (e) {
      log('Error publishing tracks: $e');
      rethrow;
    }
  }

  /// Toggle microphone mute state
  Future<void> toggleMicrophone() async {
    if (_localAudioTrack == null) return;

    try {
      final newState = !_mediaState.isAudioEnabled;
      if (newState) {
        await _localAudioTrack!.unmute();
      } else {
        await _localAudioTrack!.mute();
      }
      _mediaState = _mediaState.copyWith(isAudioEnabled: newState);
      log('Microphone ${newState ? 'unmuted' : 'muted'}');
    } catch (e) {
      log('Error toggling microphone: $e');
    }
  }

  /// Toggle video enable/disable
  Future<void> toggleVideo() async {
    if (_localVideoTrack == null) return;

    try {
      final newState = !_mediaState.isVideoEnabled;
      if (newState) {
        await _localVideoTrack!.unmute();
      } else {
        await _localVideoTrack!.mute();
      }
      _mediaState = _mediaState.copyWith(isVideoEnabled: newState);
      log('Video ${newState ? 'enabled' : 'disabled'}');
    } catch (e) {
      log('Error toggling video: $e');
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_localVideoTrack == null) return;

    try {
      final newPosition = _mediaState.isFrontCamera
          ? CameraPosition.back
          : CameraPosition.front;

      await _localVideoTrack!.setCameraPosition(newPosition);
      _mediaState = _mediaState.copyWith(
        isFrontCamera: !_mediaState.isFrontCamera,
      );
      log('Switched to ${_mediaState.isFrontCamera ? 'front' : 'back'} camera');
    } catch (e) {
      log('Error switching camera: $e');
    }
  }

  /// Toggle speaker on/off
  Future<void> toggleSpeaker() async {
    try {
      final newState = !_mediaState.isSpeakerOn;
      // In newer LiveKit, speakerphone is handled differently or via Hardware
      // For now, using standard setSpeakerphoneOn if available
      if (Hardware.instance.canSwitchSpeakerphone) {
        await Hardware.instance.setSpeakerphoneOn(newState);
      }
      _mediaState = _mediaState.copyWith(isSpeakerOn: newState);
      log('Speaker ${newState ? 'on' : 'off'}');
    } catch (e) {
      log('Error toggling speaker: $e');
    }
  }

  /// Get remote video track
  VideoTrack? getRemoteVideoTrack() {
    if (_room == null) return null;

    for (final participant in _room!.remoteParticipants.values) {
      for (final trackPublication in participant.videoTrackPublications) {
        final track = trackPublication.track;
        if (track is VideoTrack) {
          return track;
        }
      }
    }
    return null;
  }

  /// Stop all local tracks
  Future<void> stopLocalTracks() async {
    try {
      await _localVideoTrack?.stop();
      await _localAudioTrack?.stop();
      log('Stopped local tracks');
    } catch (e) {
      log('Error stopping local tracks: $e');
    }
  }

  /// Dispose all tracks and resources
  Future<void> dispose() async {
    await stopLocalTracks();
    await stopLocalTracks();

    // Safety check for disposals
    try {
      await _localVideoTrack?.dispose();
    } catch (e) {
      log('Error disposing video track: $e');
    }

    try {
      await _localAudioTrack?.dispose();
    } catch (e) {
      log('Error disposing audio track: $e');
    }

    _localVideoTrack = null;
    _localAudioTrack = null;
    _room = null;

    if (!_localVideoController.isClosed) await _localVideoController.close();
    if (!_remoteVideoController.isClosed) await _remoteVideoController.close();
    if (!_participantsController.isClosed) {
      await _participantsController.close();
    }

    log('MediaManager disposed');
  }
}
