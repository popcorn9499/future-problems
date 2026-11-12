class RideOffer {
  final String? arrivalId;
  final String? departureId;
  final String? roundTripId;
  final String userId;
  final String? offerId;
  final String status;
  final String rideType;
  final String city;
  final String streetAddress;
  final String? arrivalTime;
  final String? departureTime;
  final List<String> daysOfWeek;
  final int passengerNum;
  final String? description;
  final bool askingForDrivers;

  const RideOffer({
    this.arrivalId,
    this.departureId,
    this.roundTripId,
    required this.userId,
    this.offerId,
    this.status = 'OPEN',
    required this.rideType,
    required this.city,
    required this.streetAddress,
    required this.arrivalTime,
    required this.departureTime,
    required this.daysOfWeek,
    required this.passengerNum,
    this.description,
    required this.askingForDrivers,
  });

  factory RideOffer.fromJson(Map<String, dynamic> json) {
    return RideOffer(
      arrivalId: json['arrivalId'] as String?,
      departureId: json['departureId'] as String?,
      roundTripId: json['roundTripId'] as String?,
      userId: json['userId'] as String,
      offerId: json['offerId'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      rideType: json['rideType'] as String,
      city: json['city'] as String,
      streetAddress: json['streetAddress'] as String,
      arrivalTime: json['arrivalTime'] as String?,
      departureTime: json['departureTime'] as String?,
      daysOfWeek: List<String>.from(json['daysOfWeek'] as List),
      passengerNum: json['passengerNum'] as int,
      description: json['description'] as String?,
      askingForDrivers: json['askingForDrivers'] as bool,
    );
  }
}
