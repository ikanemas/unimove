import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../services/database_service.dart';
import 'errand_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.refreshVersion = 0});

  final int refreshVersion;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Errand>> _errandsFuture;
  final _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _errandsFuture = _loadErrands();
    _databaseService.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _databaseService.changes.removeListener(_reload);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _errandsFuture = _loadErrands();
    }
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _errandsFuture = _loadErrands();
    });
  }

  Future<List<Errand>> _loadErrands() {
    return _databaseService.getOpenErrands();
  }

  Future<void> _refreshErrands() async {
    final errands = _loadErrands();
    if (!mounted) return;
    setState(() {
      _errandsFuture = errands;
    });
    try {
      await errands;
    } catch (_) {
      // FutureBuilder renders the error state from the same future.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UniMove')),
      body: RefreshIndicator(
        onRefresh: _refreshErrands,
        child: FutureBuilder<List<Errand>>(
          future: _errandsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ScrollableMessage(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _ScrollableMessage(
                child: Text(
                  'Unable to load errands right now.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              );
            }

            final errands = snapshot.data ?? [];
            if (errands.isEmpty) {
              return const _ScrollableMessage(
                child: Text('No errands posted yet.'),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: errands.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ErrandListTile(errand: errands[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ],
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
