class ProfileValidators {
  ProfileValidators._();

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your first name';
    }

    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final age = int.tryParse(value.trim());

    if (age == null || age < 18 || age > 100) {
      return 'Enter an age between 18 and 100';
    }

    return null;
  }
}
