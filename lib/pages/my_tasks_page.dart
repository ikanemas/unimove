import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'errand_view.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  final _database = DatabaseService.instance;
  late Future<List<Errand>> _tasks;
  int? _updatingId;

  String get _userId => SupabaseService.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tasks = _loadTasks();
    _database.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _database.changes.removeListener(_reload);
    super.dispose();
  }

  Future<List<Errand>> _loadTasks() {
    if (_userId.isEmpty) return Future.value([]);
    return _database.getAssignedErrands(_userId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _tasks = _loadTasks());
  }

  Future<void> _markCompleted(Errand errand) async {
    setState(() => _updatingId = errand.id);
    try {
      await _database.updateAssignedErrandStatus(
        id: errand.id!,
        runnerId: _userId,
        status: 'Completed',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as completed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update task: $error')));
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: FutureBuilder<List<Errand>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load your tasks.'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No accepted errands yet.\nOpen an errand from Home to accept it.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final canComplete = task.status == 'Open';

              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            task.displayStatus,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posted by ${task.posterName ?? 'UniMove User'}'
                        '\nRM ${task.reward.toStringAsFixed(2)} | '
                        '${task.timeToComplete}',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ErrandView(errandId: task.id!),
                                ),
                              );
                            },
                            child: const Text('View details'),
                          ),
                          const SizedBox(width: 8),
                          if (canComplete)
                            FilledButton.icon(
                              onPressed: _updatingId == task.id
                                  ? null
                                  : () => _markCompleted(task),
                              icon: _updatingId == task.id
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: const Text('Complete'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
