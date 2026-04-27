import 'package:flutter_test/flutter_test.dart';
import 'package:bhojan_frontend/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils.normalizeIndianPhone', () {
    test('normalizes plain 10-digit number to +91 format', () {
      expect(
        PhoneUtils.normalizeIndianPhone('8971100269'),
        '+918971100269',
      );
    });

    test('normalizes 91-prefixed number to +91 format', () {
      expect(
        PhoneUtils.normalizeIndianPhone('918971100269'),
        '+918971100269',
      );
    });

    test('keeps already normalized +91 number unchanged', () {
      expect(
        PhoneUtils.normalizeIndianPhone('+918971100269'),
        '+918971100269',
      );
    });

    test('strips separators and still normalizes correctly', () {
      expect(
        PhoneUtils.normalizeIndianPhone('+91 89711-00269'),
        '+918971100269',
      );
    });
  });

  group('PhoneUtils.isValidIndianPhone', () {
    test('accepts valid local number', () {
      expect(PhoneUtils.isValidIndianPhone('8971100269'), isTrue);
    });

    test('accepts valid +91 number', () {
      expect(PhoneUtils.isValidIndianPhone('+918971100269'), isTrue);
    });

    test('rejects invalid number', () {
      expect(PhoneUtils.isValidIndianPhone('12345'), isFalse);
    });
  });
}

