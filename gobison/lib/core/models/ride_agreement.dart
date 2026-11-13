

class AgreementMember {
  final String id;
  final String firstName;
  final String? lastName;

  const AgreementMember({
    required this.id,
    required this.firstName,
    this.lastName = '',
  });

  String get fullName {
    final last = lastName?.trim() ?? '';
    return last.isEmpty ? firstName : '$firstName $last';
  }

  String get initials {
    final last = lastName?.trim() ?? '';
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final second = last.isNotEmpty ? last[0] : '';
    return '$first$second'.toUpperCase();
  }

  factory AgreementMember.fromJson(Map<String, dynamic> json) {
    return AgreementMember(
      id: json['id'].toString(),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
    );
  }
}

/// One leg of a recurring carpool arrangement.
class RideAgreement {
  final String? id;
  final String listingId;
  final String? roundTripId;
  final String rideType;
  final String origin;
  final String destination;
  final String? arrivalTime;
  final String? departureTime;
  final List<String> daysOfWeek;
  final List<AgreementMember> drivers;
  final List<AgreementMember> passengers;
  final String status;
  final bool createdByCurrentUser;

  const RideAgreement({
    required this.id,
    required this.listingId,
    this.roundTripId,
    required this.rideType,
    required this.origin,
    required this.destination,
    this.arrivalTime,
    this.departureTime,
    required this.daysOfWeek,
    required this.drivers,
    required this.passengers,
    required this.status,
    required this.createdByCurrentUser,
  });

  /// Gets the applicable time for this leg.
  String get rideTime {
    return rideType == 'ARRIVAL'
        ? arrivalTime ?? ''
        : departureTime ?? '';
  }

  /// "08:30" -> "8:30 AM"
  String get rideTimeLabel {
    final time = rideTime;
    final parts = time.split(':');

    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return time;

    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;

    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  /// "MONDAY" -> "Mon"
  static String shortDay(String day) {
    if (day.length < 3) return day;
    return day[0].toUpperCase() +
        day.substring(1, 3).toLowerCase();
  }

  factory RideAgreement.fromJson(Map<String, dynamic> json) {
    return RideAgreement(
      id: json['id']?.toString(),
      listingId: json['listingId'] as String,
      roundTripId: json['roundTripId'] as String?,
      rideType: json['rideType'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      arrivalTime: json['arrivalTime'] as String?,
      departureTime: json['departureTime'] as String?,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>)
          .map((d) => d.toString())
          .toList(),
      drivers: (json['drivers'] as List<dynamic>)
          .map((m) => AgreementMember.fromJson(
              m as Map<String, dynamic>))
          .toList(),
      passengers: (json['passengers'] as List<dynamic>)
          .map((m) => AgreementMember.fromJson(
              m as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'OPEN',
      createdByCurrentUser:
          json['createdByCurrentUser'] as bool? ?? false,
    );
  }
}
