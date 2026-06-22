import 'package:flutter/material.dart';

import '../models/errand_offer.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({
    super.key,
    required this.errandId,
    required this.errandTitle,
  });

  final int errandId;
  final String errandTitle;

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final _database = DatabaseService.instance;
  late Future<List<ErrandOffer>> _offers;
  int? _processingOfferId;

  String get _posterId => SupabaseService.client.auth.currentUser?.id ?? '';

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
    return _database.getOffersForErrand(widget.errandId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _offers = _loadOffers();
    });
  }

  Future<void> _accept(ErrandOffer offer) async {
    setState(() => _processingOfferId = offer.id);
    try {
      final accepted = await _database.acceptOffer(
        offerId: offer.id,
        posterId: _posterId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? '${offer.runnerName} is now assigned to this errand.'
                : 'This request can no longer be accepted.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _processingOfferId = null);
    }
  }

  Future<void> _reject(ErrandOffer offer) async {
    setState(() => _processingOfferId = offer.id);
    try {
      await _database.rejectOffer(offerId: offer.id, posterId: _posterId);
    } finally {
      if (mounted) setState(() => _processingOfferId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Runner Requests')),
      body: FutureBuilder<List<ErrandOffer>>(
        future: _offers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load requests.'));
          }

          final offers = snapshot.data ?? [];
          if (offers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No runner requests for "${widget.errandTitle}" yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final pending = offer.status == 'Pending';

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
                              offer.runnerName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          _OfferBadge(status: offer.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Reward: RM '
                        '${offer.proposedReward.toStringAsFixed(2)}',
                      ),
                      Text('Required time: ${offer.estimatedTime}'),
                      if (pending) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _processingOfferId == offer.id
                                  ? null
                                  : () => _reject(offer),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: _processingOfferId == offer.id
                                  ? null
                                  : () => _accept(offer),
                              child: _processingOfferId == offer.id
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Accept'),
                            ),
                          ],
                        ),
                      ],
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

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Accepted' => const Color(0xFF267A4B),
      'Rejected' => const Color(0xFFB3261E),
      _ => const Color(0xFF725A00),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
