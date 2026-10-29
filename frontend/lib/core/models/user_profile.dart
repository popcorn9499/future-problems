class UserProfile {
  final String userId;
  final String firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final String? description;

  const UserProfile({
    required this.userId,
    required this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.description,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      description: json['description'] as String?,
    );
  }
}
