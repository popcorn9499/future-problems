class RideRequest {
  final String userId;
  final String rideType;
  final String city;
  final String streetAddress;
  final String? arrivalTime;
  final String? departureTime;
  final List<String> daysOfWeek;
  final String? description;

  const RideRequest({
    required this.userId,
    required this.rideType,
    required this.city,
    required this.streetAddress,
    required this.arrivalTime,
    required this.departureTime,
    required this.daysOfWeek,
    this.description,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      userId: json['userId'] as String,
      rideType: json['rideType'] as String,
      city: json['city'] as String,
      streetAddress: json['streetAddress'] as String,
      arrivalTime: json['arrivalTime'] as String?,
      departureTime: json['departureTime'] as String?,
      daysOfWeek: json['daysOfWeek'] as List<String>,
      description: json['description'] as String?,
    );
  }
}
