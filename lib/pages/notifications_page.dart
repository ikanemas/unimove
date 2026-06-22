import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'errand_view.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _database = DatabaseService.instance;
  late Future<List<AppNotification>> _notifications;
  List<AppNotification> _cachedNotifications = [];

  String get _userId => SupabaseService.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _notifications = _loadNotifications();
    _database.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _database.changes.removeListener(_reload);
    super.dispose();
  }

  Future<List<AppNotification>> _loadNotifications() {
    if (_userId.isEmpty) return Future.value([]);
    return _database.getNotifications(_userId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _notifications = _loadNotifications();
    });
  }

  void _setCachedNotifications(List<AppNotification> notifications) {
    _cachedNotifications = notifications;
    setState(() {
      _notifications = Future.value(notifications);
    });
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      await _database.markNotificationRead(notification.id);
      if (mounted) {
        _setCachedNotifications([
          for (final item in _cachedNotifications)
            item.id == notification.id ? item.copyWith(isRead: true) : item,
        ]);
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ErrandView(errandId: notification.errandId),
      ),
    );
  }

  Future<void> _markAllRead() async {
    if (_userId.isEmpty) return;
    await _database.markAllNotificationsRead(_userId);
    if (!mounted) return;
    _setCachedNotifications([
      for (final notification in _cachedNotifications)
        notification.copyWith(isRead: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load notifications.'));
          }

          final notifications = snapshot.data ?? [];
          _cachedNotifications = notifications;
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56),
                  SizedBox(height: 12),
                  Text('No notifications yet.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                tileColor: notification.isRead
                    ? null
                    : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                leading: CircleAvatar(
                  child: Icon(
                    notification.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${notification.message}\n'
                  '${_formatNotificationTime(notification.createdAt)}',
                ),
                isThreeLine: true,
                trailing: notification.isRead
                    ? const Icon(Icons.chevron_right)
                    : const Badge(),
                onTap: () => _openNotification(notification),
              );
            },
          );
        },
      ),
    );
  }
}

String _formatNotificationTime(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} at $hour:$minute';
}
