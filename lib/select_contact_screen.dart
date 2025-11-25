import 'package:flutter/material.dart';
import 'package:my_app/chat_messaging_screen.dart';
import 'package:my_app/find_account_page_screen.dart';
import 'package:my_app/model/chat_model.dart';

class SelectContactScreen extends StatelessWidget {
  const SelectContactScreen({super.key, required this.onNewChat});

  final Function(ChatModel) onNewChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<ChatModel> contacts = [
      ChatModel(
        userId: "691948bf001eb3eccd78",
        name: "Baby (You)",
        message: "Message yourself",
        time: "",
        imgPath: "https://picsum.photos/200/300",
      ),
      ChatModel(
          userId: "691948bf001eb3eccd79",
          name: "Alice",
          message: "Busy",
          time: "",
          imgPath: "https://picsum.photos/200/300",
          isOnline: true),
      ChatModel(
          userId: "691948bf001eb3eccd80",
          name: "Alex Smith",
          message: "At the gym",
          time: "",
          imgPath: "https://picsum.photos/200/300"),
      ChatModel(
          userId: "691948bf001eb3eccd81",
          name: "Andrew",
          message: "Urgent calls only",
          time: "",
          imgPath: "https://picsum.photos/200/300"),
      ChatModel(
          userId: "691948bf001eb3eccd82",
          name: "Mom",
          message: "Hey there! I am using WhatsApp.",
          time: "",
          imgPath: "https://picsum.photos/200/300"),
      ChatModel(
          userId: "691948bf001eb3eccd83",
          name: "John Doe",
          message: "Battery about to die",
          time: "",
          imgPath: "https://picsum.photos/200/300"),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select contact"),
            Text(
              "256 contacts",
              style: TextStyle(
                fontSize: 13,
                color: theme.appBarTheme.titleTextStyle?.color?.withAlpha(179),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // Static Action Items
          const ActionItem(
            icon: Icons.group,
            label: "New group",
          ),
          const ActionItem(
            icon: Icons.person_add,
            label: "New contact",
            trailingIcon: Icons.qr_code,
          ),
          ActionItem(
            icon: Icons.search,
            label: "Find",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindAccountPageScreen(),
                ),
              );
            },
          ),
          ActionItem(
            icon: Icons.smart_toy_outlined,
            label: "Chat with AIs",
            onTap: () {
              final aiChat = ChatModel(
                userId: "kai_ai_user",
                name: "KAI",
                message: "How can I help you?",
                time: "",
                imgPath: "",
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatMessagingScreen(
                    chat: aiChat,
                    onMessageSent: (newMessage) {
                      final newChat = aiChat;
                      newChat.message = newMessage;
                      newChat.time = "Now"; // Or format current time
                      onNewChat(newChat); // Call the callback from ChatsScreen
                    },
                  ),
                ),
              );
            },
          ),

          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              "Contacts on WhatsApp",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          // Contact Items
          ...contacts.map((contact) => ContactItem(
                contact: contact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatMessagingScreen(
                        chat: contact,
                        onMessageSent: (newMessage) {
                          final newChat = contact;
                          newChat.message = newMessage;
                          newChat.time = "Now"; // Or format current time
                          onNewChat(newChat); // Call the callback from ChatsScreen
                        },
                      ),
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

// Widget for the top action buttons (New Group, New Contact, etc.)
class ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const ActionItem({
    super.key,
    required this.icon,
    required this.label,
    this.trailingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(
          icon,
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium,
      ),
      trailing: trailingIcon != null
          ? Icon(trailingIcon, color: Colors.grey)
          : null,
    );
  }
}

// Widget for individual contacts
class ContactItem extends StatelessWidget {
  final ChatModel contact;
  final VoidCallback onTap;

  const ContactItem({super.key, required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[300],
        backgroundImage: contact.imgPath.isNotEmpty
            ? NetworkImage(contact.imgPath)
            : null,
        child: contact.imgPath.isEmpty
            ? Text(
                contact.name.isNotEmpty ? contact.name[0] : "",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Text(
            contact.name,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          contact.message,
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
