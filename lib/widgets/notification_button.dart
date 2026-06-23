import 'package:flutter/material.dart';

import '../pages/notifications_page.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  final _database = DatabaseService.instance;
  late Future<int> _unreadCount;

  String get _userId => SupabaseService.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _unreadCount = _loadUnreadCount();
    _database.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _database.changes.removeListener(_reload);
    super.dispose();
  }

  Future<int> _loadUnreadCount() {
    if (_userId.isEmpty) return Future.value(0);
    return _database.getUnreadNotificationCount(_userId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _unreadCount = _loadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _unreadCount,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
