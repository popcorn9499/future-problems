class RideOffer {
  final String userId;
  final String? offerId;
  final String status;
  final String city;
  final String streetAddress;
  final String arrivalTime;
  final List<String> daysOfWeek;
  final int passengerNum;
  final String? description;
  final bool askingForDrivers;

  const RideOffer({
    required this.userId,
    this.offerId,
    this.status = 'OPEN',
    required this.city,
    required this.streetAddress,
    required this.arrivalTime,
    required this.daysOfWeek,
    required this.passengerNum,
    this.description,
    required this.askingForDrivers
  });

  factory RideOffer.fromJson(Map<String, dynamic> json) {
    return RideOffer(
      userId: json['userId'] as String,
      offerId: json['offerId'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      city: json['city'] as String,
      streetAddress: json['streetAddress'] as String,
      arrivalTime: json['arrivalTime'] as String,
      daysOfWeek: List<String>.from(json['daysOfWeek'] as List),
      passengerNum: json['passengerNum'] as int,
      description: json['description'] as String?,
      askingForDrivers: json['askingForDrivers'] as bool,
    );
  }
}
