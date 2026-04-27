import 'package:flutter_test/flutter_test.dart';
import 'package:bhojan_frontend/features/auth/models/auth_response_models.dart';

void main() {
  group('Auth request model serialization', () {
    test('RegisterRequest serializes normalized phone', () {
      final request = RegisterRequest(
        userType: 'GUEST',
        fullName: 'Test User',
        phone: '8971100269',
        password: 'Password@1',
      );

      final json = request.toJson();
      expect(json['phone'], '+918971100269');
      expect(json['user_type'], 'GUEST');
    });

    test('OtpVerifyRequest serializes normalized phone', () {
      final request = OtpVerifyRequest(
        phone: '918971100269',
        otp: '123456',
      );

      final json = request.toJson();
      expect(json['phone'], '+918971100269');
      expect(json['otp'], '123456');
    });

    test('PasswordLoginRequest serializes normalized phone', () {
      final request = PasswordLoginRequest(
        phone: '+91 89711-00269',
        password: 'Password@1',
      );

      final json = request.toJson();
      expect(json['phone'], '+918971100269');
    });

    test('PasswordResetVerifyRequest serializes normalized phone', () {
      final request = PasswordResetVerifyRequest(
        phone: '8971100269',
        otp: '123456',
        newPassword: 'Password@1',
      );

      final json = request.toJson();
      expect(json['phone'], '+918971100269');
      expect(json['new_password'], 'Password@1');
    });
  });
}

