import 'package:flutter_test/flutter_test.dart';

import 'package:finance_reimagined/services/sms_parser.dart';
import 'package:finance_reimagined/models/transaction.dart';

void main() {
  group('SmsParser', () {
    test('parses Chase debit SMS', () {
      const sms =
          'A charge of \$42.50 has been authorized on your Chase Visa card ending 1234 at Amazon on 06/05/2026.';
      final result = SmsParser.parse(sms);
      expect(result, isNotNull);
      expect(result!.amount, 42.50);
      expect(result.type, TransactionType.debit);
      expect(result.accountLast4, '1234');
      expect(result.bankName, 'Chase');
      expect(result.merchant, contains('Amazon'));
    });

    test('parses credit/deposit SMS', () {
      const sms =
          'BofA: \$1,250.00 direct deposit received from ACME CORP to your account ending 5678 on 06/01/2026.';
      final result = SmsParser.parse(sms);
      expect(result, isNotNull);
      expect(result!.type, TransactionType.credit);
      expect(result.amount, 1250.00);
    });

    test('ignores OTP messages', () {
      const sms = 'Your Chase OTP is 123456. Do not share this code.';
      expect(SmsParser.parse(sms), isNull);
    });

    test('returns null for non-financial SMS', () {
      const sms = 'Your package has been delivered!';
      expect(SmsParser.parse(sms), isNull);
    });

    test('parses Capital One SMS', () {
      const sms =
          'Capital One: A \$15.99 transaction was approved at Netflix on 06/06/2026.';
      final result = SmsParser.parse(sms);
      expect(result, isNotNull);
      expect(result!.amount, 15.99);
      expect(result.bankName, 'Capital One');
    });

    test('handles comma-formatted amounts', () {
      const sms =
          'Wells Fargo Alert: A purchase of \$1,234.56 was made with your card ending 9999.';
      final result = SmsParser.parse(sms);
      expect(result, isNotNull);
      expect(result!.amount, 1234.56);
    });
  });
}
