import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/subscription.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository());

final subscriptionsProvider = StateNotifierProvider<SubscriptionsController, AsyncValue<List<Subscription>>>((ref) {
  final controller = SubscriptionsController(ref.watch(subscriptionRepositoryProvider));
  controller.load();
  return controller;
});

class SubscriptionsController extends StateNotifier<AsyncValue<List<Subscription>>> {
  SubscriptionsController(this._repository) : super(const AsyncValue.loading());

  final SubscriptionRepository _repository;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      state = AsyncValue.data(await _repository.load());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> add(Subscription value) => _mutate((items) => [...items, value]);

  Future<void> update(Subscription value) => _mutate((items) => [
        for (final item in items) if (item.id == value.id) value else item,
      ]);

  Future<void> delete(String id) => _mutate((items) => items.where((item) => item.id != id).toList());

  Future<void> _mutate(List<Subscription> Function(List<Subscription>) change) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = change(current);
    try {
      await _repository.save(updated);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
