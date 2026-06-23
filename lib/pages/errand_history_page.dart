import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'errand_view.dart';

class ErrandHistoryPage extends StatefulWidget {
  const ErrandHistoryPage({super.key});

  @override
  State<ErrandHistoryPage> createState() => _ErrandHistoryPageState();
}

class _ErrandHistoryPageState extends State<ErrandHistoryPage> {
  final _database = DatabaseService.instance;
  late Future<List<Errand>> _postedErrands;
  late Future<List<Errand>> _acceptedTasks;
  String _statusFilter = 'All';

  String get _userId => SupabaseService.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _postedErrands = _loadPostedErrands();
    _acceptedTasks = _loadAcceptedTasks();
    _database.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _database.changes.removeListener(_reload);
    super.dispose();
  }

  Future<List<Errand>> _loadPostedErrands() {
    if (_userId.isEmpty) return Future.value([]);
    return _database.getUserPostedErrands(_userId);
  }

  Future<List<Errand>> _loadAcceptedTasks() {
    if (_userId.isEmpty) return Future.value([]);
    return _database.getAssignedErrands(_userId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _postedErrands = _loadPostedErrands();
      _acceptedTasks = _loadAcceptedTasks();
    });
  }

  List<Errand> _applyFilter(List<Errand> errands) {
    if (_statusFilter == 'All') return errands;
    return errands
        .where((errand) => errand.displayStatus == _statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Errand History'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.upload_outlined), text: 'Posted by Me'),
              Tab(icon: Icon(Icons.task_alt_outlined), text: 'Tasks Accepted'),
            ],
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = _statusFilters[index];
                  return FilterChip(
                    label: Text(status),
                    selected: _statusFilter == status,
                    onSelected: (_) {
                      setState(() => _statusFilter = status);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _HistoryList(
                    future: _postedErrands,
                    filter: _applyFilter,
                    emptyMessage: 'No errands posted yet.',
                    filteredEmptyMessage:
                        'No posted errands match this status.',
                    perspective: _HistoryPerspective.poster,
                  ),
                  _HistoryList(
                    future: _acceptedTasks,
                    filter: _applyFilter,
                    emptyMessage: 'No errands accepted yet.',
                    filteredEmptyMessage:
                        'No accepted tasks match this status.',
                    perspective: _HistoryPerspective.runner,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.future,
    required this.filter,
    required this.emptyMessage,
    required this.filteredEmptyMessage,
    required this.perspective,
  });

  final Future<List<Errand>> future;
  final List<Errand> Function(List<Errand>) filter;
  final String emptyMessage;
  final String filteredEmptyMessage;
  final _HistoryPerspective perspective;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Errand>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load errand history.'));
        }

        final allErrands = snapshot.data ?? [];
        final errands = filter(allErrands);
        if (errands.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                allErrands.isEmpty ? emptyMessage : filteredEmptyMessage,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: errands.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _HistoryCard(
              errand: errands[index],
              perspective: perspective,
            );
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.errand, required this.perspective});

  final Errand errand;
  final _HistoryPerspective perspective;

  @override
  Widget build(BuildContext context) {
    final isPoster = perspective == _HistoryPerspective.poster;
    final personLabel = isPoster ? 'Runner' : 'Posted by';
    final personName = isPoster
        ? (errand.runnerName ?? 'Not assigned yet')
        : (errand.posterName ?? 'UniMove User');
    final eventLabel = isPoster ? 'Posted' : 'Accepted';
    final eventDate = isPoster
        ? errand.createdAt
        : (errand.acceptedAt ?? errand.createdAt);
    final statusColor = _statusColor(errand.displayStatus);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ErrandView(errandId: errand.id!),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      errand.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      errand.displayStatus,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HistoryInfo(
                icon: Icons.person_outline,
                label: '$personLabel: $personName',
              ),
              const SizedBox(height: 6),
              _HistoryInfo(
                icon: Icons.calendar_today_outlined,
                label: '$eventLabel: ${_formatDate(eventDate)}',
              ),
              const SizedBox(height: 6),
              _HistoryInfo(
                icon: Icons.schedule_outlined,
                label: errand.timeToComplete,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'RM ${errand.reward.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Text('View details'),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryInfo extends StatelessWidget {
  const _HistoryInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'Completed' => const Color(0xFF267A4B),
    'Closed' => const Color(0xFFB3261E),
    'Accepted' => const Color(0xFF725A00),
    _ => const Color(0xFF27638C),
  };
}

String _formatDate(DateTime date) {
  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  return '$day/$month/${localDate.year}';
}

enum _HistoryPerspective { poster, runner }

const _statusFilters = ['All', 'Open', 'Accepted', 'Completed', 'Closed'];
