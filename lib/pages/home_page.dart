import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../services/database_service.dart';
import 'errand_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Errand>> _errandsFuture;

  @override
  void initState() {
    super.initState();
    _errandsFuture = DatabaseService.instance.getErrands();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UniMove')),
      body: FutureBuilder<List<Errand>>(
        future: _errandsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load errands right now.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final errands = snapshot.data ?? [];
          if (errands.isEmpty) {
            return const Center(child: Text('No errands posted yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: errands.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _ErrandListTile(errand: errands[index]);
            },
          );
        },
      ),
    );
  }
}

class _ErrandListTile extends StatelessWidget {
  const _ErrandListTile({required this.errand});

  final Errand errand;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        title: Text(
          errand.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${errand.timeToComplete} - RM ${errand.reward.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ErrandView(errandId: errand.id!),
            ),
          );
        },
      ),
    );
  }
}
