import 'package:livekit_client/livekit_client.dart';
import 'package:my_app/appwrite_service.dart';

class CallService {
  final String _url = 'wss://my-new-project-21vhn4cm.livekit.cloud';
  final AppwriteService _appwriteService;

  CallService(this._appwriteService);

  Future<Room> connectToRoom(String roomName) async {
    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    final token = await _appwriteService.getLiveKitToken(roomName: roomName);

    await room.connect(
      _url,
      token,
    );

    return room;
  }
}
