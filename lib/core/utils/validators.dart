class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Phone number is required';
    final regex = RegExp(r'^[0-9+\-\s()]{7,15}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? number(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    if (double.tryParse(value.trim()) == null) return '$label must be a number';
    return null;
  }
}
