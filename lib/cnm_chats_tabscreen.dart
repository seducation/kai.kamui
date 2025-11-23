import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/chat_messaging_screen.dart';
import 'package:my_app/model/chat_model.dart';
import 'package:my_app/one_time_message_screen.dart';
import 'package:shimmer/shimmer.dart';

class CNMChatsTabscreen extends StatelessWidget {
  final List<ChatModel> chatItems;
  final bool isLoading;

  const CNMChatsTabscreen(
      {super.key, required this.chatItems, this.isLoading = false});

  void _viewStory(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneTimeMessageScreen(
          message: "This is a one-time message from ${chatItems[index].name}",
          onStoryViewed: () {
            // This should be handled by the parent widget
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? _buildShimmerLoading()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: StatusBar(
                      chatItems: chatItems,
                      onViewStory: (index) => _viewStory(context, index)),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chat = chatItems[index];
                      return ChatListItem(
                          chat: chat,
                          onTap: () => _viewStory(context, index));
                    },
                    childCount: chatItems.length,
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
                      radius: 35,
                      backgroundImage: CachedNetworkImageProvider(chat.imgPath),
                    ),
                  ),
                  const SizedBox(height: 8),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatMessagingScreen(
              chat: chat,
              onMessageSent: (newMessage) {
                // This should be handled by the parent widget
              },
            ),
          ),
        );
      },
      leading: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(chat.imgPath),
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
