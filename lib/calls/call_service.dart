import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/calls/constants/call_constants.dart';
import 'package:my_app/calls/models/call_models.dart';
import 'package:my_app/calls/services/media_manager.dart';
import 'package:my_app/calls/services/signaling_service.dart';
import 'package:my_app/environment.dart';

/// Enhanced service for managing LiveKit room connections and call lifecycle
class CallService {
  final AppwriteService _appwriteService;
  final SignalingService _signalingService;
  final MediaManager mediaManager;

  lk.Room? _room;
  String? _currentRoomName;
  CallData? _activeCall;
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  bool _isDisposed = false;

  final _connectionStateController =
      StreamController<lk.ConnectionState>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _incomingCallController = StreamController<CallData>.broadcast();

  Stream<lk.ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<CallData> get incomingCallStream => _incomingCallController.stream;
  CallData? get activeCall => _activeCall;

  lk.Room? get room => _room;
  bool get isConnected =>
      _room?.connectionState == lk.ConnectionState.connected;

  CallService(this._appwriteService, this._signalingService,
      {MediaManager? mediaManager})
      : mediaManager = mediaManager ?? MediaManager();

  void _log(String message) {
    log('[CallService] $message');
  }

  /// Initialize the service and start listening for signals
  Future<void> initialize() async {
    _log('Initializing...');
    await _signalingService.startListening();
    _signalingService.callEvents.listen(_handleSignalingEvent);

    // Check for any active call on startup
    final currentCall = await _signalingService.getActiveCall();
    if (currentCall != null && currentCall.status == CallState.connecting) {
      _log('Resuming active call: ${currentCall.callId}');
      _activeCall = currentCall;
      connectToRoom(currentCall.roomName);
    }
  }

  /// Handle incoming signaling events
  void _handleSignalingEvent(CallData event) {
    _log('Received signal: ${event.status}');

    switch (event.status) {
      case CallState.initiating:
        _handleIncomingCall(event);
        break;
      case CallState.ended:
      case CallState.rejected:
      case CallState.timeout:
        if (_activeCall?.callId == event.callId) {
          disconnect();
          _activeCall = null;
        }
        break;
      default:
        // Other states handled locally or irrelevant
        break;
    }
  }

  void _handleIncomingCall(CallData call) {
    if (_room != null) {
      // Busy: Auto-reject or notify
      // For now, auto-reject if we are already in a call
      _signalingService.rejectCall(call.callId);
      return;
    }
    _incomingCallController.add(call);
  }

  /// Initiate a new call
  Future<void> makeCall({
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
    bool isVideo = true,
  }) async {
    try {
      final callData = await _signalingService.createCall(
        receiverId: receiverId,
        receiverName: receiverName,
        receiverAvatar: receiverAvatar,
        callType: isVideo ? CallType.video : CallType.audio,
      );

      _activeCall = callData;
      await connectToRoom(callData.roomName);
    } catch (e) {
      _log('Error making call: $e');
      _errorController.add('Failed to start call');
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<void> acceptIncomingCall(CallData call) async {
    try {
      await _signalingService.acceptCall(call.callId);
      _activeCall = call;
      await connectToRoom(call.roomName);
    } catch (e) {
      _log('Error accepting call: $e');
      _errorController.add('Failed to accept call');
      _activeCall = null;
      rethrow;
    }
  }

  /// Reject an incoming call
  Future<void> rejectIncomingCall(String callId) async {
    try {
      await _signalingService.rejectCall(callId);
    } catch (e) {
      _log('Error rejecting call: $e');
    }
  }

  /// End the current active call
  Future<void> endCurrentCall() async {
    if (_activeCall == null) return;

    try {
      await _signalingService.endCall(
        _activeCall!.callId,
        acceptedAt: _activeCall!.acceptedAt,
      );
      await disconnect();
      _activeCall = null;
    } catch (e) {
      _log('Error ending call: $e');
      // Force local disconnect even if signaling fails
      await disconnect();
      _activeCall = null;
    }
  }

  /// Connect to a LiveKit room
  Future<lk.Room> connectToRoom(String roomName) async {
    if (_isDisposed) {
      throw Exception('CallService has been disposed');
    }

    try {
      _log('Connecting to room: $roomName');
      _currentRoomName = roomName;

      // 1. Prepare Room Options
      final roomOptions = const lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: lk.AudioPublishOptions(
          name: 'microphone',
          audioBitrate: CallConstants.defaultAudioBitrate,
        ),
        defaultVideoPublishOptions: lk.VideoPublishOptions(
          name: 'camera',
          videoEncoding: lk.VideoEncoding(
            maxBitrate: CallConstants.defaultVideoBitrate,
            maxFramerate: 24, // Reduced from 30 for stability
          ),
        ),
      );

      _room = lk.Room(roomOptions: roomOptions);
      _room!.addListener(_onRoomStateChanged);

      // 2. Parallel Execution: Fetch Token AND Initialize Local Media
      final results = await Future.wait([
        _appwriteService.getLiveKitToken(roomName: roomName),
        mediaManager.initializeLocalMedia(), // Pre-warm camera
      ]);

      final token = results[0] as String;
      // results[1] is void, media is initialized

      // 3. Set Room & Publish Tracks (in parallel with connection if possible, but safer sequential here)
      mediaManager.setRoom(_room!);

      // Connect to LiveKit
      await _room!.connect(Environment.liveKitUrl, token);

      _log('Connected to LiveKit room');

      // Publish pre-warmed tracks
      await mediaManager.publishLocalTracks();

      _reconnectionAttempts = 0;
      return _room!;
    } catch (e) {
      _log('Error connecting to room: $e');
      _errorController.add('Failed to connect: $e');
      rethrow;
    }
  }

  /// Handle room state changes
  void _onRoomStateChanged() {
    if (_room == null) return;

    final state = _room!.connectionState;
    _connectionStateController.add(state);
    _log('Room state changed: $state');

    switch (state) {
      case lk.ConnectionState.connecting:
        break;
      case lk.ConnectionState.disconnected:
        _handleDisconnection();
        break;
      case lk.ConnectionState.reconnecting:
        break;
      case lk.ConnectionState.connected:
        _reconnectionAttempts = 0;
        _reconnectionTimer?.cancel();
        break;
    }
  }

  /// Handle disconnection and attempt reconnection
  void _handleDisconnection() {
    if (_isDisposed) return;

    if (_reconnectionAttempts < CallConstants.maxReconnectionAttempts) {
      _reconnectionAttempts++;
      final delay = CallConstants.reconnectionDelay *
          CallConstants.reconnectionDelayMultiplier *
          _reconnectionAttempts;

      _log(
          'Attempting reconnection $_reconnectionAttempts in ${delay.inSeconds}s');

      _reconnectionTimer?.cancel();
      _reconnectionTimer = Timer(delay, () async {
        _log('Triggering reconnection attempt $_reconnectionAttempts');

        // If SDK hasn't reconnected by now, try manual reconnection
        if (_room?.connectionState != lk.ConnectionState.connected &&
            _currentRoomName != null) {
          try {
            await disconnect();
            await connectToRoom(_currentRoomName!);
          } catch (e) {
            _log('Manual reconnection failed: $e');
            // Allow timer to trigger next attempt if attempts < max
          }
        }
      });
    } else {
      _log('Max reconnection attempts reached');
      _errorController.add('Connection lost. Please try again.');
    }
  }

  /// Disconnect from the room
  Future<void> disconnect() async {
    try {
      _log('Disconnecting from room');
      _reconnectionTimer?.cancel();

      await mediaManager.stopLocalTracks();
      await _room?.disconnect();
      _room?.removeListener(_onRoomStateChanged);
      _room?.dispose();
      _room = null;
      _currentRoomName = null;

      _log('Disconnected successfully');
    } catch (e) {
      _log('Error disconnecting: $e');
    }
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        _log('App paused - pausing video');
        if (mediaManager.mediaState.isVideoEnabled) {
          await mediaManager.toggleVideo();
        }
        break;
      case AppLifecycleState.resumed:
        _log('App resumed - resuming video');
        if (!mediaManager.mediaState.isVideoEnabled) {
          await mediaManager.toggleVideo();
        }
        break;
      default:
        break;
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    _log('Disposing service');

    await disconnect();
    await mediaManager.dispose();

    _connectionStateController.close();
    _errorController.close();
    _incomingCallController.close();
    _reconnectionTimer?.cancel();
    _signalingService.dispose();
  }
}
