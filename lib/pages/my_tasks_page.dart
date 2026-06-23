import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/errand.dart';
import '../models/errand_offer.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'errand_view.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: const Scaffold(
        appBar: _RunnerActivityAppBar(),
        body: TabBarView(children: [_AssignedTasksTab(), _MyOffersTab()]),
      ),
    );
  }
}

class _RunnerActivityAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _RunnerActivityAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Runner Activity'),
      bottom: const TabBar(
        tabs: [
          Tab(text: 'My Tasks', icon: Icon(Icons.task_alt_outlined)),
          Tab(text: 'My Requests', icon: Icon(Icons.handshake_outlined)),
        ],
      ),
    );
  }
}

Future<void> _openWhatsAppChat({
  required BuildContext context,
  required String? phoneNumber,
  required String message,
}) async {
  if (phoneNumber == null || phoneNumber.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact phone number not available.')),
    );
    return;
  }

  String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  if (!cleanPhone.startsWith('+') && !cleanPhone.startsWith('6')) {
    cleanPhone =
        '6$cleanPhone'; // Standard fallback prefix for Malaysia context
  }

  final Uri whatsappUri = Uri.parse(
    'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
  );

  if (await canLaunchUrl(whatsappUri)) {
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp app.')),
      );
    }
  }
}

class _AssignedTasksTab extends StatefulWidget {
  const _AssignedTasksTab();

  @override
  State<_AssignedTasksTab> createState() => _AssignedTasksTabState();
}

class _AssignedTasksTabState extends State<_AssignedTasksTab> {
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
    setState(() {
      _tasks = _loadTasks();
    });
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
    return FutureBuilder<List<Errand>>(
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
          return const _EmptyRunnerState(
            icon: Icons.task_alt_outlined,
            message:
                'No assigned tasks yet.\nAccepted requests will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final task = tasks[index];
            final canComplete = task.status == 'Closed';
            final isChatAvailable = task.status == 'Closed';

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
                        _StatusBadge(status: task.displayStatus),
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
                        if (isChatAvailable) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.chat,
                              color: Color(0xFF25D366),
                            ),
                            tooltip: 'Chat with Poster',
                            onPressed: () {
                              _openWhatsAppChat(
                                context: context,
                                phoneNumber: task.posterPhone,
                                message:
                                    'Hello! I am the runner for your errand: "${task.title}". Let\'s coordinate.',
                              );
                            },
                          ),
                          const Spacer(),
                        ],
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ErrandView(errandId: task.id!),
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
    );
  }
}

class _MyOffersTab extends StatefulWidget {
  const _MyOffersTab();

  @override
  State<_MyOffersTab> createState() => _MyOffersTabState();
}

class _MyOffersTabState extends State<_MyOffersTab> {
  final _database = DatabaseService.instance;
  late Future<List<ErrandOffer>> _offers;

  String get _userId => SupabaseService.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _offers = _loadOffers();
    _database.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _database.changes.removeListener(_reload);
    super.dispose();
  }

  Future<List<ErrandOffer>> _loadOffers() {
    if (_userId.isEmpty) return Future.value([]);
    return _database.getOffersByRunner(_userId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _offers = _loadOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ErrandOffer>>(
      future: _offers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load your requests.'));
        }

        final offers = snapshot.data ?? [];
        if (offers.isEmpty) {
          return const _EmptyRunnerState(
            icon: Icons.handshake_outlined,
            message:
                'No requests submitted yet.\nOpen an errand from Home and tap I Can Do This.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final offer = offers[index];
            if (offer.status == 'Accepted') {
              return const SizedBox.shrink();
            }
            final isAccepted = offer.status == 'Accepted';

            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.errandTitle ?? 'Errand',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _StatusBadge(status: offer.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reward: RM ${offer.proposedReward.toStringAsFixed(2)}'
                      '\nRequired time: ${offer.estimatedTime}',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isAccepted) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.chat,
                              color: Color(0xFF25D366),
                            ),
                            tooltip: 'Chat with Requester',
                            onPressed: () {
                              _openWhatsAppChat(
                                context: context,
                                phoneNumber: offer.posterPhone,
                                message:
                                    'Hi! You accepted my request for "${offer.errandTitle}". I am ready to start.',
                              );
                            },
                          ),
                          const Spacer(),
                        ],
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ErrandView(errandId: offer.errandId),
                              ),
                            );
                          },
                          child: const Text('View details'),
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Accepted' || 'Completed' => const Color(0xFF267A4B),
      'Rejected' || 'Closed' => const Color(0xFFB3261E),
      _ => const Color(0xFF725A00),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyRunnerState extends StatelessWidget {
  const _EmptyRunnerState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
