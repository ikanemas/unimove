import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'add_errand_page.dart';
import 'home_page.dart';
import 'my_tasks_page.dart';
import 'profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _database = DatabaseService.instance;
  int _selectedIndex = 0;
  int _refreshVersion = 0;
  late Future<int> _unreadCount;

  String get _userId => SupabaseService.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _unreadCount = _loadUnreadCount();
    _database.changes.addListener(_reloadUnreadCount);
    _database.unreadNotificationCount.addListener(_useLatestUnreadCount);
  }

  @override
  void dispose() {
    _database.unreadNotificationCount.removeListener(_useLatestUnreadCount);
    _database.changes.removeListener(_reloadUnreadCount);
    super.dispose();
  }

  Future<int> _loadUnreadCount() {
    if (_userId.isEmpty) return Future.value(0);
    return _database.getUnreadNotificationCount(_userId);
  }

  void _reloadUnreadCount() {
    if (!mounted) return;
    setState(() {
      _unreadCount = _loadUnreadCount();
      _refreshVersion++;
    });
  }

  void _useLatestUnreadCount() {
    final count = _database.unreadNotificationCount.value;
    if (!mounted || count == null) return;
    setState(() {
      _unreadCount = Future.value(count);
    });
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      _refreshVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(refreshVersion: _refreshVersion),
      const MyTasksPage(),
      AddErrandPage(refreshVersion: _refreshVersion),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: FutureBuilder<int>(
        future: _unreadCount,
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectPage,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.task_outlined),
                selectedIcon: Icon(Icons.task),
                label: 'My Tasks',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                  child: const Icon(Icons.assignment_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                  child: const Icon(Icons.assignment),
                ),
                label: 'Manage',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
