class User {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final bool verified;
  final bool isDeleted;

  const User({
    required this.id,
    required this.firstName,
    this.lastName = '',
    required this.email,
    this.verified = false,
    this.isDeleted = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      verified: json['verified'] as bool? ?? false,
      email: json['email'] as String,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
