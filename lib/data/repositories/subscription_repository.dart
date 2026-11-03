import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';

class SubscriptionRepository {
  static const _key = 'subzero.subscriptions.v1';

  Future<List<Subscription>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('Saved subscription data is invalid.');
    return decoded.map((item) {
      if (item is! Map<String, dynamic>) throw const FormatException('A saved subscription is invalid.');
      return Subscription.fromJson(item);
    }).toList();
  }

  Future<void> save(List<Subscription> subscriptions) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(subscriptions.map((item) => item.toJson()).toList());
    final success = await preferences.setString(_key, encoded);
    if (!success) throw Exception('Could not save your subscriptions on this device.');
  }
}
