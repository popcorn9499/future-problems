class UserProfile {
  final String userId;
  final String firstName;
  final String? lastName;
  final int? age;
  final String? pronouns;
  final String? description;
  final String avatarColor;

  const UserProfile({
    required this.userId,
    required this.firstName,
    this.lastName,
    this.age,
    this.pronouns,
    this.description,
    this.avatarColor = '#E9DFD2',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      age: json['age'] as int?,
      pronouns: json['pronouns'] as String?,
      description: json['description'] as String?,
      avatarColor: json['avatarColor'] as String? ?? '#E9DFD2',
    );
  }
}
