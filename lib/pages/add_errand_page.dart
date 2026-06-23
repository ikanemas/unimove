import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/errand.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_button.dart';
import 'offers_page.dart';

class AddErrandPage extends StatefulWidget {
  const AddErrandPage({super.key, this.refreshVersion = 0});

  final int refreshVersion;

  @override
  State<AddErrandPage> createState() => _AddErrandPageState();
}

class _AddErrandPageState extends State<AddErrandPage> {
  final _database = DatabaseService.instance;
  late Future<List<Errand>> _errands;
  List<Errand> _cachedErrands = [];
  bool _formOpen = false;
  int? _updatingErrandId;

  User? get _user => SupabaseService.client.auth.currentUser;
  String get _userId => _user?.id ?? '';
  String get _userName =>
      (_user?.userMetadata?['name'] as String?)?.trim().isNotEmpty == true
      ? _user!.userMetadata!['name'] as String
      : (_user?.email ?? 'UniMove User');
  String get _userPhone =>
      (_user?.userMetadata?['phone_number'] as String?)?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _errands = _loadErrands();
    _database.changes.addListener(_refresh);
  }

  @override
  void dispose() {
    _database.changes.removeListener(_refresh);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AddErrandPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _errands = _loadErrands();
    }
  }

  Future<List<Errand>> _loadErrands() {
    if (_userId.isEmpty) return Future.value([]);
    return _database.getUserPostedErrands(_userId);
  }

  void _refresh() {
    if (!mounted) return;
    if (_formOpen) return;
    _refreshErrands(showLoading: _cachedErrands.isEmpty);
  }

  List<Errand> _withSavedErrand(Errand savedErrand, List<Errand> errands) {
    return [
      savedErrand,
      for (final errand in errands)
        if (errand.id != savedErrand.id) errand,
    ];
  }

  void _showSavedErrand(Errand savedErrand) {
    final errands = _withSavedErrand(savedErrand, _cachedErrands);
    _cachedErrands = errands;
    setState(() {
      _errands = Future.value(errands);
    });
  }

  Future<void> _refreshErrands({
    Errand? includeErrand,
    bool showLoading = true,
  }) async {
    final errands = _loadErrands().then((rows) {
      final nextErrands = includeErrand == null
          ? rows
          : _withSavedErrand(includeErrand, rows);
      _cachedErrands = nextErrands;
      return nextErrands;
    });

    if (showLoading && mounted) {
      setState(() {
        _errands = errands;
      });
    }

    try {
      final loadedErrands = await errands;
      if (!mounted) return;
      setState(() {
        _errands = Future.value(loadedErrands);
      });
    } catch (_) {
      if (showLoading && mounted) {
        setState(() {
          _errands = errands;
        });
      }
    }
  }

  Future<void> _showForm([Errand? errand]) async {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before posting an errand.'),
        ),
      );
      return;
    }

    Object? result;
    _formOpen = true;
    try {
      result = await showModalBottomSheet<Object?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _ErrandForm(
          errand: errand,
          posterId: _userId,
          posterName: _userName,
          posterPhone: _userPhone,
        ),
      );
    } finally {
      _formOpen = false;
    }

    if (!mounted) return;

    if (result is Errand) {
      _showSavedErrand(result);
      await _refreshErrands(includeErrand: result, showLoading: false);
    } else if (result == true) {
      await _refreshErrands(showLoading: false);
    }
  }

  Future<void> _setStatus(Errand errand, String status) async {
    setState(() => _updatingErrandId = errand.id);

    try {
      await _database.updateErrandStatus(
        id: errand.id!,
        posterId: _userId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errand marked $status.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update status: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingErrandId = null);
    }
  }

  Future<void> _delete(Errand errand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete errand?'),
        content: Text('"${errand.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _database.deleteErrand(id: errand.id!, posterId: _userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Errands'),
        actions: [
          const NotificationButton(),
          IconButton(
            tooltip: 'Post errand',
            onPressed: _showForm,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshErrands,
        child: FutureBuilder<List<Errand>>(
          future: _errands,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ScrollableMessage(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return const _ScrollableMessage(
                child: Text('Unable to load your errands.'),
              );
            }

            final errands = snapshot.data ?? [];
            _cachedErrands = errands;
            if (errands.isEmpty) {
              return _ScrollableMessage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 56),
                    const SizedBox(height: 12),
                    const Text('You have not posted any errands yet.'),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _showForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Post errand'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: errands.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final errand = errands[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
                    title: Text(
                      errand.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${errand.displayStatus}  |  RM ${errand.reward.toStringAsFixed(2)}'
                        '\n${errand.timeToComplete}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: _updatingErrandId == errand.id
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : PopupMenuButton<String>(
                            tooltip: 'Errand actions',
                            onSelected: (action) {
                              if (action == 'edit') {
                                _showForm(errand);
                              } else if (action == 'offers') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => OffersPage(
                                      errandId: errand.id!,
                                      errandTitle: errand.title,
                                    ),
                                  ),
                                );
                              } else if (action == 'delete') {
                                _delete(errand);
                              } else {
                                _setStatus(errand, action);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              if (errand.status == 'Open')
                                const PopupMenuItem(
                                  value: 'offers',
                                  child: Text('View runner requests'),
                                ),
                              for (final status in [
                                'Open',
                                'Completed',
                                'Closed',
                              ])
                                PopupMenuItem(
                                  value: status,
                                  enabled: errand.status != status,
                                  child: Text('Mark $status'),
                                ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showForm,
        icon: const Icon(Icons.add),
        label: const Text('Post errand'),
      ),
    );
  }
}

class _ErrandForm extends StatefulWidget {
  const _ErrandForm({
    required this.posterId,
    required this.posterName,
    required this.posterPhone,
    this.errand,
  });

  final String posterId;
  final String posterName;
  final String posterPhone;
  final Errand? errand;

  @override
  State<_ErrandForm> createState() => _ErrandFormState();
}

class _ErrandFormState extends State<_ErrandForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _reward;
  late final TextEditingController _time;
  late final TextEditingController _description;
  late String _status;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.errand?.title);
    _reward = TextEditingController(
      text: widget.errand?.reward.toStringAsFixed(2),
    );
    _time = TextEditingController(text: widget.errand?.timeToComplete);
    _description = TextEditingController(text: widget.errand?.description);
    _status = widget.errand?.status ?? 'Open';
  }

  @override
  void dispose() {
    _title.dispose();
    _reward.dispose();
    _time.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _validReward(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    return amount == null || amount <= 0 ? 'Enter a valid reward' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final database = DatabaseService.instance;
      if (widget.errand == null) {
        final savedErrand = await database.insertErrand(
          title: _title.text.trim(),
          reward: double.parse(_reward.text.trim()),
          description: _description.text.trim(),
          timeToComplete: _time.text.trim(),
          posterId: widget.posterId,
          posterName: widget.posterName,
          posterPhone: widget.posterPhone,
        );
        if (!mounted) return;
        Navigator.pop(context, savedErrand);
      } else {
        await database.updateErrand(
          id: widget.errand!.id!,
          posterId: widget.posterId,
          title: _title.text.trim(),
          reward: double.parse(_reward.text.trim()),
          description: _description.text.trim(),
          timeToComplete: _time.text.trim(),
          status: _status,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Unable to save errand. ${error.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.errand == null ? 'Post New Errand' : 'Edit Errand',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                validator: _required,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reward,
                validator: _validReward,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Reward',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _time,
                validator: _required,
                decoration: const InputDecoration(
                  labelText: 'Time to complete',
                  hintText: 'Example: Today before 5:00 PM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                validator: _required,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.errand != null) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Open', 'Completed', 'Closed']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _status = value!,
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                  ),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    widget.errand == null ? 'Post errand' : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
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
