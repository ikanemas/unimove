import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class ErrandView extends StatefulWidget {
  const ErrandView({super.key, required this.errandId});

  final int errandId;

  @override
  State<ErrandView> createState() => _ErrandViewState();
}

class _ErrandViewState extends State<ErrandView> {
  final _database = DatabaseService.instance;
  late Future<Errand?> _errand;
  bool _accepting = false;

  String get _userId => SupabaseService.client.auth.currentUser?.id ?? '';

  String get _userName {
    final user = SupabaseService.client.auth.currentUser;
    final metadataName = user?.userMetadata?['name'] as String?;
    if (metadataName != null && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }
    return user?.email ?? 'UniMove User';
  }

  @override
  void initState() {
    super.initState();
    _errand = _database.getErrand(widget.errandId);
  }

  Future<void> _accept(Errand errand) async {
    setState(() => _accepting = true);

    try {
      final accepted = await _database.acceptErrand(
        id: errand.id!,
        runnerId: _userId,
        runnerName: _userName,
      );
      if (!mounted) return;

      if (!accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This errand is no longer available.')),
        );
        setState(() {
          _accepting = false;
          _errand = _database.getErrand(widget.errandId);
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errand accepted. It is now in My Tasks.'),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to accept errand: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Errand Details')),
      body: FutureBuilder<Errand?>(
        future: _errand,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final errand = snapshot.data;
          if (errand == null) {
            return const Center(child: Text('Errand not found.'));
          }

          final isOwner = errand.posterId == _userId;
          final canAccept =
              _userId.isNotEmpty &&
              !isOwner &&
              errand.status == 'Open' &&
              !errand.isAssigned;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                errand.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'Reward',
                value: 'RM ${errand.reward.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Time to complete',
                value: errand.timeToComplete,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Posted by',
                value: errand.posterName ?? 'UniMove',
              ),
              if (errand.isAssigned) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.directions_run_outlined,
                  label: 'Runner',
                  value: errand.runnerName ?? 'Assigned',
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                errand.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              if (canAccept) ...[
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _accepting ? null : () => _accept(errand),
                    icon: _accepting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.task_alt),
                    label: const Text('Accept Errand'),
                  ),
                ),
              ],
              if (isOwner && errand.status == 'Open') ...[
                const SizedBox(height: 20),
                const Text(
                  'This is your own errand. Another user must accept it.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
