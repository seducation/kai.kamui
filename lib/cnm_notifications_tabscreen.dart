import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/appwrite_service.dart';
import 'package:my_app/model/notification_model.dart';
import 'package:intl/intl.dart';

class CNMNotificationsTabscreen extends StatefulWidget {
  const CNMNotificationsTabscreen({super.key});

  @override
  State<CNMNotificationsTabscreen> createState() =>
      _CNMNotificationsTabscreenState();
}

class _CNMNotificationsTabscreenState extends State<CNMNotificationsTabscreen> {
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final appwriteService = context.read<AppwriteService>();
    _notificationsFuture = _fetchNotifications(appwriteService);
  }

  Future<List<NotificationModel>> _fetchNotifications(
    AppwriteService service,
  ) async {
    try {
      final response = await service.getNotifications();
      return response.rows
          .map((doc) => NotificationModel.fromMap(doc.data, doc.$id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadNotifications();
        });
      },
      child: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getNotificationColor(notification.type),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.body),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(
                        notification.timestamp,
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  // Handle notification tap
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'follow':
        return Icons.person_add;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}
