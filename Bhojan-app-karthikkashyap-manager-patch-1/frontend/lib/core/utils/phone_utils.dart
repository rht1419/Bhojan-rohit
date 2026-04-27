class PhoneUtils {
  static String normalizeIndianPhone(String input) {
    final raw = input.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return '+91$digits';
    }
    if (RegExp(r'^91[6-9]\d{9}$').hasMatch(digits)) {
      return '+$digits';
    }
    if (RegExp(r'^\+91[6-9]\d{9}$').hasMatch(raw)) {
      return raw;
    }

    return raw;
  }

  static bool isValidIndianPhone(String input) {
    final normalized = normalizeIndianPhone(input);
    return RegExp(r'^\+91[6-9]\d{9}$').hasMatch(normalized);
  }
}

