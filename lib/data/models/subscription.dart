import 'package:uuid/uuid.dart';

enum BillingFrequency { weekly, monthly, quarterly, halfYearly, yearly, custom }

extension BillingFrequencyLabel on BillingFrequency {
  String get label => switch (this) {
        BillingFrequency.weekly => 'Weekly',
        BillingFrequency.monthly => 'Monthly',
        BillingFrequency.quarterly => 'Quarterly',
        BillingFrequency.halfYearly => 'Half-yearly',
        BillingFrequency.yearly => 'Yearly',
        BillingFrequency.custom => 'Custom interval',
      };
}

class Subscription {
  Subscription({
    String? id,
    required this.name,
    required this.price,
    required this.currency,
    required this.frequency,
    required this.nextPaymentDate,
    required this.category,
    this.notes = '',
    this.icon = '💳',
    this.isActive = true,
    this.customIntervalDays = 30,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final double price;
  final String currency;
  final BillingFrequency frequency;
  final DateTime nextPaymentDate;
  final String category;
  final String notes;
  final String icon;
  final bool isActive;
  final int customIntervalDays;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'currency': currency,
        'frequency': frequency.name,
        'nextPaymentDate': nextPaymentDate.toIso8601String(),
        'category': category,
        'notes': notes,
        'icon': icon,
        'isActive': isActive,
        'customIntervalDays': customIntervalDays,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Subscription',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'USD',
        frequency: BillingFrequency.values.firstWhere(
          (value) => value.name == json['frequency'],
          orElse: () => BillingFrequency.monthly,
        ),
        nextPaymentDate: DateTime.tryParse(json['nextPaymentDate'] as String? ?? '') ?? DateTime.now(),
        category: json['category'] as String? ?? 'Other',
        notes: json['notes'] as String? ?? '',
        icon: json['icon'] as String? ?? '💳',
        isActive: json['isActive'] as bool? ?? true,
        customIntervalDays: json['customIntervalDays'] as int? ?? 30,
      );

  Subscription copyWith({String? name, double? price, String? currency, BillingFrequency? frequency,
    DateTime? nextPaymentDate, String? category, String? notes, String? icon, bool? isActive,
    int? customIntervalDays}) => Subscription(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        frequency: frequency ?? this.frequency,
        nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        icon: icon ?? this.icon,
        isActive: isActive ?? this.isActive,
        customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      );
}

/// Estimates equivalent recurring spend. Currency conversion is deliberately not
/// performed: callers must keep totals separated by currency.
class BillingFrequencyCalculator {
  static const double _daysPerYear = 365.2425;

  static double yearlyEquivalent(Subscription subscription) {
    return switch (subscription.frequency) {
      BillingFrequency.weekly => subscription.price * 52.1775,
      BillingFrequency.monthly => subscription.price * 12,
      BillingFrequency.quarterly => subscription.price * 4,
      BillingFrequency.halfYearly => subscription.price * 2,
      BillingFrequency.yearly => subscription.price,
      BillingFrequency.custom => subscription.customIntervalDays <= 0
          ? subscription.price * 12
          : subscription.price * (_daysPerYear / subscription.customIntervalDays),
    };
  }

  static double monthlyEquivalent(Subscription subscription) => yearlyEquivalent(subscription) / 12;
}
