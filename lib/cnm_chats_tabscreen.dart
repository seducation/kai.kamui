import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/chat_messaging_screen.dart';
import 'package:my_app/model/chat_model.dart';
import 'package:my_app/one_time_message_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:appwrite/models.dart' as models;

class CNMChatsTabscreen extends StatefulWidget {
  const CNMChatsTabscreen({super.key});

  @override
  State<CNMChatsTabscreen> createState() => _CNMChatsTabscreenState();
}

class _CNMChatsTabscreenState extends State<CNMChatsTabscreen> {
  late AppwriteService appwrite;
  List<ChatModel> _chatItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    appwrite = Provider.of<AppwriteService>(context, listen: false);
    _getConversations();
  }

  Future<void> _getConversations() async {
    try {
      final user = await appwrite.getUser();
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      final senderProfiles = await appwrite.getUserProfiles(ownerId: user.$id);
      if (!mounted) return;
      final userProfiles = senderProfiles.rows.where((p) => p.data['type'] == 'profile');

      if (userProfiles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Go and create a profile first'),
          ));
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final profiles = await appwrite.getProfiles();
      final profilesByOwner = <String, List<models.Row>>{};
      for (final profile in profiles.rows) {
        final ownerId = profile.data['ownerId'] as String;
        profilesByOwner.putIfAbsent(ownerId, () => []).add(profile);
      }

      final messages = await appwrite.getAllMessages();
      final conversations = <String, ChatModel>{};

      for (final message in messages.rows) {
        final chatId = message.data['chatId'] as String;
        final ids = chatId.split('_');
        final otherUserId = ids.firstWhere((id) => id != user.$id, orElse: () => '');

        if (otherUserId.isEmpty) continue;

        final otherUserProfiles = profilesByOwner[otherUserId];
        if (otherUserProfiles == null || otherUserProfiles.isEmpty) {
          continue; 
        }

        final mainProfile = otherUserProfiles.firstWhere(
          (p) => p.data['type'] == 'profile',
          orElse: () => otherUserProfiles.first,
        );

        final conversationId = _getChatId(user.$id, otherUserId);

        if (!conversations.containsKey(conversationId)) {
          conversations[conversationId] = ChatModel(
            userId: mainProfile.$id,
            name: mainProfile.data['name'] as String,
            message: message.data['message'] as String,
            time: message.$createdAt,
            imgPath: mainProfile.data['profileImageUrl'] as String,
            hasStory: false,
            messageCount: 0,
          );
        } else {
          conversations[conversationId]!.message = message.data['message'] as String;
          conversations[conversationId]!.time = message.$createdAt;
        }
      }

      if (mounted) {
        setState(() {
          _chatItems = conversations.values.toList();
          _chatItems.sort((a, b) => b.time.compareTo(a.time));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  void _viewStory(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneTimeMessageScreen(
          message: "This is a one-time message from ${_chatItems[index].name}",
          onStoryViewed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildShimmerLoading()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: StatusBar(
                      chatItems: _chatItems,
                      onViewStory: (index) => _viewStory(context, index)),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chat = _chatItems[index];
                      return ChatListItem(
                          chat: chat,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatMessagingScreen(
                                  chat: chat,
                                  onMessageSent: (message) {},
                                ),
                              ),
                            );
                          });
                    },
                    childCount: _chatItems.length,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) => const ShimmerChatListItem(),
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  final List<ChatModel> chatItems;
  final Function(int) onViewStory;

  const StatusBar({super.key, required this.chatItems, required this.onViewStory});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: chatItems.length,
        itemBuilder: (context, index) {
          final chat = chatItems[index];
          return GestureDetector(
            onTap: () => onViewStory(index),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: chat.hasStory ? Colors.pinkAccent : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundImage: chat.imgPath.startsWith('http')
                          ? CachedNetworkImageProvider(chat.imgPath)
                          : null,
                      child: !chat.imgPath.startsWith('http')
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.name,
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatListItem({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CircleAvatar(
          radius: 30,
          backgroundImage: chat.imgPath.startsWith('http')
              ? CachedNetworkImageProvider(chat.imgPath)
              : null,
          child: !chat.imgPath.startsWith('http')
              ? const Icon(Icons.person)
              : null,
        ),
      ),
      title: Text(chat.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      subtitle: Text(chat.message, style: const TextStyle(color: Colors.grey)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(chat.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          if (chat.messageCount != null && chat.messageCount! > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.pinkAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.messageCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class ShimmerChatListItem extends StatelessWidget {
  const ShimmerChatListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: CircleAvatar(radius: 30, backgroundColor: Colors.white),
      title: SizedBox(
          height: 20, width: 150, child: ColoredBox(color: Colors.white)),
      subtitle: SizedBox(
          height: 15, width: 100, child: ColoredBox(color: Colors.white)),
    );
  }
}