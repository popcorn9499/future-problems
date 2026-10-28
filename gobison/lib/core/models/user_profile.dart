class UserProfile {
  final String userId;
  final String firstName;
  final String? lastName;
  final int? age;
  final String? pronouns;
  final String? description;

  const UserProfile({
    required this.userId,
    required this.firstName,
    this.lastName,
    this.age,
    this.pronouns,
    this.description,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      age: json['age'] as int?,
      pronouns: json['pronouns'] as String?,
      description: json['description'] as String?,
    );
  }
}
