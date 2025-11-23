import 'package:flutter/material.dart';
import 'package:my_app/chat_messaging_screen.dart';
import 'package:my_app/model/chat_model.dart';

class SelectContactScreen extends StatelessWidget {
  const SelectContactScreen({super.key, required this.onNewChat});

  final Function(ChatModel) onNewChat;

  @override
  Widget build(BuildContext context) {
    final List<ChatModel> contacts = [
      ChatModel(
        name: "Baby (You)",
        message: "Message yourself",
        time: "",
        imgPath: "assets/baby.jpg", // Placeholder logic handles missing asset
      ),
      ChatModel(
          name: "Alice",
          message: "Busy",
          time: "",
          imgPath: "",
          isOnline: true),
      ChatModel(
          name: "Alex Smith",
          message: "At the gym",
          time: "",
          imgPath: ""),
      ChatModel(
          name: "Andrew",
          message: "Urgent calls only",
          time: "",
          imgPath: ""),
      ChatModel(name: "Mom", message: "Hey there! I am using WhatsApp.", time: "", imgPath: ""),
      ChatModel(
          name: "John Doe",
          message: "Battery about to die",
          time: "",
          imgPath: ""),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Select contact"),
            Text(
              "256 contacts",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
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
          const ActionItem(
            icon: Icons.groups,
            label: "New community",
          ),
          const ActionItem(
            icon: Icons.smart_toy_outlined,
            label: "Chat with AIs",
          ),

          // Section Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              "Contacts on WhatsApp",
              style: TextStyle(
                color: Colors.grey,
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

  const ActionItem({
    super.key,
    required this.icon,
    required this.label,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF00A884), // WhatsApp Green
        child: Icon(
          icon,
          color: const Color(0xFF111B21), // Dark icon color
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[800],
        backgroundImage:
            contact.imgPath.isNotEmpty ? AssetImage(contact.imgPath) : null,
        child: contact.imgPath.isEmpty
            ? Text(
                contact.name.isNotEmpty ? contact.name[0] : "",
                style: const TextStyle(
                  color: Colors.white,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          contact.message,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
