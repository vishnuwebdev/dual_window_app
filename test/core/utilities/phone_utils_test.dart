import 'package:flutter_test/flutter_test.dart';
import 'package:multi_window_app/core/utilities/phone_utils.dart';

void main() {
  group('PhoneUtils.validatePhoneNumber', () {
    test('accepts a South African number in +27 format', () {
      expect(PhoneUtils.validatePhoneNumber('+27821234567', false), isTrue);
    });

    test('rejects an incomplete South African number', () {
      expect(PhoneUtils.validatePhoneNumber('+2782123456', false), isFalse);
      expect(PhoneUtils.validatePhoneNumber('+27', false), isFalse);
    });

    test('rejects extra digits in non-global mode', () {
      expect(PhoneUtils.validatePhoneNumber('+278212345678', false), isFalse);
    });

    test('still allows generic international format in global mode', () {
      expect(PhoneUtils.validatePhoneNumber('+15551234567', true), isTrue);
    });
  });

  group('PhoneUtils.normalizeToSouthAfrica', () {
    test('normalizes local South African input to +27 format', () {
      expect(PhoneUtils.normalizeToSouthAfrica('0821234567'), '+27821234567');
    });

    test('collapses duplicated prefixes before validation', () {
      expect(
        PhoneUtils.normalizeToSouthAfrica('+270821234567'),
        '+27821234567',
      );
    });
  });
}
