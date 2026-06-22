import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../models/errand_offer.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'offers_page.dart';

class ErrandView extends StatefulWidget {
  const ErrandView({super.key, required this.errandId});

  final int errandId;

  @override
  State<ErrandView> createState() => _ErrandViewState();
}

class _ErrandViewState extends State<ErrandView> {
  final _database = DatabaseService.instance;
  late Future<Errand?> _errand;
  late Future<ErrandOffer?> _myOffer;
  bool _submittingRequest = false;

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
    _myOffer = _loadMyOffer();
  }

  Future<ErrandOffer?> _loadMyOffer() {
    if (_userId.isEmpty) return Future.value();
    return _database.getRunnerOffer(
      errandId: widget.errandId,
      runnerId: _userId,
    );
  }

  Future<void> _submitRequest(Errand errand) async {
    if (_submittingRequest) return;
    setState(() => _submittingRequest = true);

    try {
      final created = await _database.createOffer(
        errandId: errand.id!,
        runnerId: _userId,
        runnerName: _userName,
        message: 'I can complete this errand using the original terms.',
        proposedReward: errand.reward,
        estimatedTime: errand.timeToComplete,
      );
      if (!mounted) return;

      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Request cannot be sent. The errand may be unavailable.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _myOffer = _loadMyOffer();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent. Waiting for the seller.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to send request: $error')));
    } finally {
      if (mounted) setState(() => _submittingRequest = false);
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
          final canMakeOffer =
              _userId.isNotEmpty &&
              !isOwner &&
              errand.posterId != null &&
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
              if (canMakeOffer) ...[
                const SizedBox(height: 28),
                FutureBuilder<ErrandOffer?>(
                  future: _myOffer,
                  builder: (context, offerSnapshot) {
                    final offer = offerSnapshot.data;
                    if (offerSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (offer?.status == 'Pending') {
                      return _OfferStatusPanel(
                        status: 'Pending',
                        message:
                            'Your request has been sent. Waiting for the seller.',
                      );
                    }
                    if (offer?.status == 'Accepted') {
                      return _OfferStatusPanel(
                        status: 'Accepted',
                        message: 'Your request was accepted. Check My Tasks.',
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (offer?.status == 'Rejected') ...[
                          const _OfferStatusPanel(
                            status: 'Rejected',
                            message:
                                'Your previous request was rejected. You may try again.',
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _submittingRequest
                                ? null
                                : () => _submitRequest(errand),
                            icon: _submittingRequest
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.volunteer_activism_outlined),
                            label: const Text('I Can Do This'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              if (isOwner && errand.status == 'Open') ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => OffersPage(
                            errandId: errand.id!,
                            errandTitle: errand.title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('View Runner Requests'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OfferStatusPanel extends StatelessWidget {
  const _OfferStatusPanel({required this.status, required this.message});

  final String status;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message),
        ],
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
