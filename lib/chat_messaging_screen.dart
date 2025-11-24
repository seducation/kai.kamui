import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/chat_call_screen.dart';
import 'package:my_app/model/chat_model.dart';
import 'package:my_app/widgets/chat_app_bar.dart';

class ChatMessagingScreen extends StatelessWidget {
  final ChatModel chat;
  final Function(String) onMessageSent;

  const ChatMessagingScreen(
      {super.key, required this.chat, required this.onMessageSent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        urlImage: chat.imgPath,
        title: chat.name,
        onOff: chat.isOnline ? "Online" : "Offline",
        onCallPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Panggilan()),
          );
        },
        onProfileTap: () {
          final name = Uri.encodeComponent(chat.name);
          final imageUrl = Uri.encodeComponent(chat.imgPath);
          context.go('/profile_page?name=$name&imageUrl=$imageUrl');
        },
      ),
      body: ChatScr(onMessageSent: onMessageSent, message: chat.message),
    );
  }
}

class ChatScr extends StatefulWidget {
  final Function(String) onMessageSent;
  final String message;
  const ChatScr({super.key, required this.onMessageSent, required this.message});

  @override
  State<ChatScr> createState() => _ChatScrState();
}

class _ChatScrState extends State<ChatScr> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final List<String> _messages = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.message.isNotEmpty) {
      _messages.insert(0, widget.message);
    }
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.insert(0, text);
    });
    widget.onMessageSent(text);
    _focusNode.requestFocus();
    Navigator.pop(context); // Go back to the previous screen
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                hintText: 'Message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ),
              focusNode: _focusNode,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("web/icons/Icon-512.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Flexible(
            child: _messages.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "No messages here yet...",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Send a message to start the conversation.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(message, style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}
