import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../services/database_service.dart';

class ErrandView extends StatelessWidget {
  const ErrandView({super.key, required this.errandId});

  final int errandId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Errand Details')),
      body: FutureBuilder<Errand?>(
        future: DatabaseService.instance.getErrand(errandId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final errand = snapshot.data;
          if (errand == null) {
            return const Center(child: Text('Errand not found.'));
          }

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
