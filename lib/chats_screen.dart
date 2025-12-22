import 'package:flutter/material.dart';
import 'package:my_app/add_post_screen.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/profile_screen.dart';
import 'package:my_app/search_screen.dart';
import 'package:my_app/select_contact_screen.dart';
import 'package:my_app/cnm_calls_tabscreen.dart';
import 'package:my_app/cnm_chats_tabscreen.dart';
import 'package:my_app/cnm_reply_tabscreen.dart';
import 'package:my_app/model/chat_model.dart';
import 'package:my_app/cnm_notifications_tabscreen.dart';
import 'package:my_app/cnm_updates_tabscreen.dart';
import 'package:provider/provider.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  late List<ChatModel> _chatItems;

  @override
  void initState() {
    super.initState();
    _chatItems = [
      ChatModel(
        userId: "691948bf001eb3eccd78",
        name: "User 1",
        message: "Hello there!",
        time: "12:30 PM",
        imgPath: "https://picsum.photos/seed/p1/200/200",
        isOnline: true,
        messageCount: 2,
        hasStory: true,
      ),
      ChatModel(
        userId: "691948bf001eb3eccd79",
        name: "User 2",
        message: "How are you?",
        time: "12:35 PM",
        imgPath: "https://picsum.photos/seed/p2/200/200",
        hasStory: true,
      ),
      ChatModel(
        userId: "691948bf001eb3eccd80",
        name: "User 3",
        message: "See you soon.",
        time: "12:40 PM",
        imgPath: "https://picsum.photos/seed/p3/200/200",
        isOnline: true,
        messageCount: 1,
      ),
    ];
  }

  void _addNewChat(ChatModel newChat) {
    setState(() {
      final index = _chatItems.indexWhere(
        (chat) => chat.userId == newChat.userId,
      );
      if (index != -1) {
        _chatItems[index] = newChat;
      } else {
        _chatItems.insert(0, newChat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appwriteService = context.read<AppwriteService>();
    return DefaultTabController(
      length: 5,
      initialIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SearchScreen(appwriteService: appwriteService),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          title: const Text("gvone"),
          centerTitle: true,
          actions: [
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPostScreen(),
                    ),
                  );
                }),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.notifications)),
              Tab(text: "Updates"),
              Tab(text: "Chat"),
              Tab(text: "Reply"),
              Tab(icon: Icon(Icons.call)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CNMNotificationsTabscreen(),
            CNMUpdatesTabscreen(),
            CNMChatsTabscreen(),
            CNMReplyTabscreen(),
            CNMCallsTabscreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SelectContactScreen(onNewChat: _addNewChat),
              ),
            );
          },
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }
}
