import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/subscription.dart';
import '../subscriptions/subscription_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsProvider);
    final items = state.valueOrNull ?? const <Subscription>[];
    final active = items.where((item) => item.isActive).toList();
    final monthlyByCurrency = _totals(active, BillingFrequencyCalculator.monthlyEquivalent);
    final yearlyByCurrency = _totals(active, BillingFrequencyCalculator.yearlyEquivalent);
    final upcoming = active.where((item) => !item.nextPaymentDate.isBefore(DateTime.now())).toList()
      ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));

    return Scaffold(
      appBar: AppBar(title: const Text('SubZero'), actions: [
        IconButton(tooltip: 'Add subscription', onPressed: () => context.push('/subscription/new'), icon: const Icon(Icons.add)),
      ]),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(message: 'Could not load subscriptions: $error', onRetry: () => ref.read(subscriptionsProvider.notifier).load()),
        data: (_) => RefreshIndicator(
          onRefresh: () => ref.read(subscriptionsProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Your subscriptions. Under control.', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _SummaryCard(title: 'Monthly estimate', totals: monthlyByCurrency, count: active.length)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(title: 'Yearly estimate', totals: yearlyByCurrency, count: active.length)),
              ]),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Upcoming payments', style: Theme.of(context).textTheme.titleLarge),
                TextButton(onPressed: () => context.go('/subscriptions'), child: const Text('See all')),
              ]),
              if (upcoming.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No upcoming payments. Add a subscription to get started.')))
              else
                ...upcoming.take(5).map((item) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(item.icon)),
                        title: Text(item.name),
                        subtitle: Text('${item.category} · ${AppFormatters.date(item.nextPaymentDate)}'),
                        trailing: Text(AppFormatters.currency(item.price, item.currency)),
                      ),
                    )),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: () => context.push('/subscription/new'), icon: const Icon(Icons.add), label: const Text('Add subscription')),
              const SizedBox(height: 20),
              Text('Totals are estimates and are shown separately by currency. SubZero does not process payments.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, double> _totals(List<Subscription> items, double Function(Subscription) calculate) {
    final totals = <String, double>{};
    for (final item in items) {
      totals.update(item.currency, (value) => value + calculate(item), ifAbsent: () => calculate(item));
    }
    return totals;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.totals, required this.count});
  final String title;
  final Map<String, double> totals;
  final int count;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            if (totals.isEmpty) Text(AppFormatters.currency(0, 'USD'), style: Theme.of(context).textTheme.titleLarge)
            else ...totals.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(AppFormatters.currency(entry.value, entry.key), style: Theme.of(context).textTheme.titleLarge),
                )),
            const SizedBox(height: 8),
            Text('$count active ${count == 1 ? 'subscription' : 'subscriptions'}'),
          ]),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message), const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Try again'))]),
      ));
}
