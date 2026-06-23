import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<String?> _ensurePhoneNumber(User user) async {
    final currentPhone = user.userMetadata?['phone_number']?.toString();

    if (currentPhone != null && currentPhone.trim().isNotEmpty) {
      return currentPhone;
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final phoneController = TextEditingController();
        final formKey = GlobalKey<FormState>();
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                'Phone Number Required',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please provide your phone number so the runner can coordinate with you via WhatsApp.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'e.g., 60123456789',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF643D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          final inputPhone = phoneController.text.trim();

                          try {
                            await SupabaseService.client.auth.updateUser(
                              UserAttributes(
                                data: {'phone_number': inputPhone},
                              ),
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext, inputPhone);
                            }
                          } catch (error) {
                            setDialogState(() => isSaving = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save profile: $error'),
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWhatsAppLinkDialog(ErrandOffer offer) {
    showDialog<void>(
      context: context,
      builder: (BuildContext popContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Errand Assigned!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You have accepted the offer from ${offer.runnerName}. You can now contact them directly on WhatsApp.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(popContext),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(popContext);

                final runnerPhone = offer.runnerPhone;
                if (runnerPhone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Runner phone number not found.'),
                    ),
                  );
                  return;
                }

                String cleanPhone = runnerPhone.replaceAll(
                  RegExp(r'[^\d+]'),
                  '',
                );
                if (!cleanPhone.startsWith('+') &&
                    !cleanPhone.startsWith('6')) {
                  cleanPhone = '6$cleanPhone';
                }

                final message = Uri.encodeComponent(
                  'Hello ${offer.runnerName}, I accepted your offer for "${widget.errandTitle}".',
                );
                final whatsappUri = Uri.parse(
                  'https://wa.me/$cleanPhone?text=$message',
                );

                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(
                    whatsappUri,
                    mode: LaunchMode.externalApplication,
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open WhatsApp.')),
                  );
                }
              },
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text(
                'Open WhatsApp',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _accept(ErrandOffer offer) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    final phone = await _ensurePhoneNumber(user);
    if (phone == null) return;

    setState(() => _processingOfferId = offer.id);
    try {
      final accepted = await _database.acceptOffer(
        offerId: offer.id,
        posterId: _posterId,
        posterPhone: phone,
      );

      if (!mounted) return;

      if (accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${offer.runnerName} is now assigned to this errand.',
            ),
          ),
        );
        _showWhatsAppLinkDialog(offer);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This request can no longer be accepted.'),
          ),
        );
      }
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
                        'Reward: RM ${offer.proposedReward.toStringAsFixed(2)}',
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
                                        color: Colors.white,
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
