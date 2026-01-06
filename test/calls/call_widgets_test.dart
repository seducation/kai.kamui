import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/calls/models/call_models.dart';
import 'package:my_app/calls/services/media_manager.dart';
import 'package:my_app/calls/widgets/call_controls_widget.dart';

// Manual Mocks
class MockMediaManager extends MediaManager {
  @override
  MediaState get mediaState => const MediaState(
        isVideoEnabled: true,
        isAudioEnabled: true,
        isFrontCamera: true,
        isSpeakerOn: true,
      );

  @override
  Future<void> toggleMicrophone() async {}

  @override
  Future<void> toggleVideo() async {}

  @override
  Future<void> switchCamera() async {}
}

void main() {
  group('Call UI Tests', () {
    testWidgets('CallControlsWidget renders all buttons',
        (WidgetTester tester) async {
      final mockMediaManager = MockMediaManager();
      bool endCallPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallControlsWidget(
              mediaManager: mockMediaManager,
              onEndCall: () {
                endCallPressed = true;
              },
            ),
          ),
        ),
      );

      // Verify buttons exist (by Icon)
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
      expect(find.byIcon(Icons.call_end), findsOneWidget);

      // Verify End Call interaction
      await tester.tap(find.byIcon(Icons.call_end));
      expect(endCallPressed, isTrue);
    });
  });
}
