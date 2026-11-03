import 'package:flutter_test/flutter_test.dart';
import 'package:subzero/data/models/subscription.dart';

void main() {
  Subscription make(BillingFrequency frequency, double price, {int days = 30}) => Subscription(
        name: 'Test plan', price: price, currency: 'USD', frequency: frequency,
        nextPaymentDate: DateTime(2026, 1, 1), category: 'Other', customIntervalDays: days,
      );

  group('BillingFrequencyCalculator', () {
    test('monthly and yearly billing use expected annual commitments', () {
      expect(BillingFrequencyCalculator.monthlyEquivalent(make(BillingFrequency.monthly, 12)), 12);
      expect(BillingFrequencyCalculator.yearlyEquivalent(make(BillingFrequency.yearly, 120)), 120);
    });

    test('quarterly and half-yearly convert to monthly estimates', () {
      expect(BillingFrequencyCalculator.monthlyEquivalent(make(BillingFrequency.quarterly, 30)), 10);
      expect(BillingFrequencyCalculator.monthlyEquivalent(make(BillingFrequency.halfYearly, 60)), 10);
    });

    test('weekly uses annualized 52.1775 weeks', () {
      expect(BillingFrequencyCalculator.yearlyEquivalent(make(BillingFrequency.weekly, 10)), closeTo(521.775, 0.001));
    });

    test('custom intervals convert to an annual estimate', () {
      expect(BillingFrequencyCalculator.yearlyEquivalent(make(BillingFrequency.custom, 30, days: 30)), closeTo(365.2425, 0.001));
    });

    test('invalid custom interval falls back to monthly', () {
      expect(BillingFrequencyCalculator.yearlyEquivalent(make(BillingFrequency.custom, 15, days: 0)), 180);
    });
  });
}
