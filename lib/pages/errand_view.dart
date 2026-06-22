import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔥 FIX 1: Import url_launcher diperlukan di sini

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

  String? get _userPhone =>
      SupabaseService.client.auth.currentUser?.userMetadata?['phone_number']
          as String?;

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

  // FIX 2: Letakkan fungsi helper WhatsApp yang selamat terus di dalam fail ini
  Future<void> _openWhatsAppChat({
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
      cleanPhone = '6$cleanPhone'; // Format default kod negara Malaysia
    }

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp app.')),
        );
      }
    }
  }

  Future<String?> _ensureRunnerPhone() async {
    if (_userPhone != null && _userPhone!.trim().isNotEmpty) {
      return _userPhone;
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final TextEditingController phoneController = TextEditingController();
        final formKey = GlobalKey<FormState>();

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
                  'Please register your phone number first so the poster can contact you via WhatsApp later.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Your Phone Number',
                    hintText: 'e.g., 60123456789',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Cannot be empty'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF643D),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final inputPhone = phoneController.text.trim();
                  try {
                    await SupabaseService.client.auth.updateUser(
                      UserAttributes(data: {'phone_number': inputPhone}),
                    );
                    if (context.mounted)
                      Navigator.pop(dialogContext, inputPhone);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text(
                'Save & Request',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRequest(Errand errand) async {
    if (_submittingRequest) return;

    final validPhone = await _ensureRunnerPhone();
    if (validPhone == null) return;

    setState(() => _submittingRequest = true);

    try {
      final created = await _database.createOffer(
        errandId: errand.id!,
        runnerId: _userId,
        runnerName: _userName,
        runnerPhone: validPhone,
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

      final freshOffer = _loadMyOffer(); // Panggil di luar setState
      setState(() {
        _myOffer = freshOffer; // Set variable sahaja di dalam setState
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
                value: errand.timeToComplete ?? 'Not specified',
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
                errand.description ?? 'No description provided.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),

              // ================= PANARAN PERSPEKTIF RUNNER =================
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
                      return const _OfferStatusPanel(
                        status: 'Pending',
                        message:
                            'Your request has been sent. Waiting for the seller.',
                      );
                    }

                    // FIX 3: Tambah butang WhatsApp untuk Runner menghubungi Poster selepas diterima
                    if (offer?.status == 'Accepted') {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _OfferStatusPanel(
                            status: 'Accepted',
                            message:
                                'Your request was accepted. Check My Tasks.',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _openWhatsAppChat(
                                phoneNumber: errand.posterPhone,
                                message:
                                    'Hello! My request for your errand "${errand.title}" has been accepted. Let\'s coordinate!',
                              ),
                              icon: const Icon(Icons.chat, color: Colors.white),
                              label: const Text(
                                'Chat with Poster (WhatsApp)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF643D),
                            ),
                            onPressed: _submittingRequest
                                ? null
                                : () => _submitRequest(errand),
                            icon: _submittingRequest
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.volunteer_activism_outlined),
                            label: const Text('Request Errand'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],

              // ================= PAPARAN PERSPEKTIF POSTER (OWNER) =================
              if (isOwner) ...[
                if (errand.isAssigned) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openWhatsAppChat(
                        phoneNumber: errand.runnerPhone,
                        message:
                            'Hello ${errand.runnerName}! I am the creator of the errand: "${errand.title}". Let\'s coordinate our task.',
                      ),
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text(
                        'Chat with Assigned Runner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],

                if (errand.status == 'Open') ...[
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
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(128),
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
