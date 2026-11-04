class RideOffer {
  final String userId;
  final String city;
  final String streetAddress;
  final String arrivalTime;
  final List<String> daysOfWeek;
  final int passengerNum;
  final String? description;

  const RideOffer({
    required this.userId,
    required this.city,
    required this.streetAddress,
    required this.arrivalTime,
    required this.daysOfWeek,
    required this.passengerNum,
    this.description,
  });

  factory RideOffer.fromJson(Map<String, dynamic> json) {
    return RideOffer(
      userId: json['userId'] as String,
      city: json['city'] as String,
      streetAddress: json['streetAddress'] as String,
      arrivalTime: json['arrivalTime'] as String,
      daysOfWeek: json['daysOfWeek'] as List<String>,
      passengerNum: json['passengerNum'] as int,
      description: json['description'] as String?,
    );
  }
}
