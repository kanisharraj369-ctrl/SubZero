import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/subscription.dart';
import 'subscription_providers.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            onPressed: () => context.push('/subscription/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load subscriptions: $error')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No subscriptions yet. Add one to start tracking recurring costs.'),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(item.icon)),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.category} · ${item.frequency.label}${item.isActive ? '' : ' · Paused'}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            context.push('/subscription/${item.id}');
                          }
                          if (action == 'pause') {
                            await ref
                                .read(subscriptionsProvider.notifier)
                                .update(item.copyWith(isActive: !item.isActive));
                          }
                          if (action == 'delete') {
                            await ref.read(subscriptionsProvider.notifier).delete(item.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'pause',
                            child: Text(item.isActive ? 'Pause' : 'Resume'),
                          ),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () => context.push('/subscription/${item.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key, this.subscriptionId});

  final String? subscriptionId;

  @override
  ConsumerState<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();

  BillingFrequency _frequency = BillingFrequency.monthly;
  String _currency = 'USD';
  String _category = 'Entertainment';
  String _icon = '💳';
  DateTime _date = DateTime.now();
  bool _active = true;
  bool _initialized = false;
  bool _saving = false;
  int _customDays = 30;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _initialize(List<Subscription> items) {
    if (_initialized) return;
    _initialized = true;
    final id = widget.subscriptionId;
    if (id == null) return;

    Subscription? item;
    for (final candidate in items) {
      if (candidate.id == id) item = candidate;
    }
    if (item == null) return;

    _name.text = item.name;
    _price.text = item.price.toString();
    _notes.text = item.notes;
    _frequency = item.frequency;
    _currency = item.currency;
    _category = item.category;
    _icon = item.icon;
    _date = item.nextPaymentDate;
    _active = item.isActive;
    _customDays = item.customIntervalDays;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsProvider);
    state.whenData(_initialize);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subscriptionId == null ? 'Add subscription' : 'Edit subscription'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load subscriptions: $error')),
        data: (_) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a subscription name.'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        return parsed == null || !parsed.isFinite || parsed <= 0
                            ? 'Enter a valid amount greater than zero.'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: const ['USD', 'EUR', 'GBP', 'INR', 'CAD', 'AUD', 'JPY']
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) => setState(() => _currency = value ?? 'USD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<BillingFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Billing frequency'),
                items: BillingFrequency.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) => setState(
                  () => _frequency = value ?? BillingFrequency.monthly,
                ),
              ),
              if (_frequency == BillingFrequency.custom) ...[
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: _customDays.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Interval in days'),
                  onChanged: (value) => _customDays = int.tryParse(value) ?? 30,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        'Entertainment',
                        'Productivity',
                        'Health',
                        'Utilities',
                        'Shopping',
                        'Learning',
                        'Other',
                      ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setState(() => _category = value ?? 'Other'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _icon,
                      decoration: const InputDecoration(labelText: 'Icon'),
                      items: const ['💳', '🎬', '📱', '🎧', '📚', '🍏', '🛒']
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) => setState(() => _icon = value ?? '💳'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Next payment date'),
                subtitle: Text(AppFormatters.date(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (value != null) setState(() => _date = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final id = widget.subscriptionId;
    final item = Subscription(
      id: id,
      name: _name.text.trim(),
      price: double.parse(_price.text.trim()),
      currency: _currency,
      frequency: _frequency,
      nextPaymentDate: _date,
      category: _category,
      notes: _notes.text.trim(),
      icon: _icon,
      isActive: _active,
      customIntervalDays: _customDays,
    );

    await (id == null
        ? ref.read(subscriptionsProvider.notifier).add(item)
        : ref.read(subscriptionsProvider.notifier).update(item));
    if (!mounted) return;

    setState(() => _saving = false);
    final result = ref.read(subscriptionsProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save subscription: ${result.error}')),
      );
      return;
    }
    context.pop();
  }
}
