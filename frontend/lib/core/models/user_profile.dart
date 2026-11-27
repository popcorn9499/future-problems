class UserProfile {
  final String userId;
  final String firstName;
  final String? lastName;
  final int? age;
  final DateTime? dateOfBirth;
  final String? pronouns;
  final String? description;
  final String avatarColor;

  const UserProfile({
    required this.userId,
    required this.firstName,
    this.lastName,
    this.age,
    this.dateOfBirth,
    this.pronouns,
    this.description,
    this.avatarColor = '#E9DFD2',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      age: json['age'] as int?,
      dateOfBirth: json['dateOfBirth'] is String
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      pronouns: json['pronouns'] as String?,
      description: json['description'] as String?,
      avatarColor: json['avatarColor'] as String? ?? '#E9DFD2',
    );
  }

  int? get displayAge {
    final birthday = dateOfBirth;
    if (birthday == null) return age;

    final today = DateTime.now();
    var years = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      years--;
    }
    return years;
  }
}
