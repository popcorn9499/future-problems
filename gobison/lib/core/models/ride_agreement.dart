/// A person attached to a ride agreement (a driver or a passenger).
class AgreementMember {
  final String id;
  final String firstName;
  final String? lastName;
  final String? address;

  const AgreementMember({
    required this.id,
    required this.firstName,
    this.lastName = '',
    this.address = '',
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
      address: json['address'] as String?,
    );
  }
}

/// A recurring carpool agreement the current user is part of.
///
/// [daysOfWeek] uses Java's `DayOfWeek` names ("MONDAY" ... "SUNDAY") and
/// [departureTime] is "HH:mm" (24h), matching how `LocalTime` / `DayOfWeek`
/// serialize by default in Spring Boot.
class RideAgreement {
  final String id;
  final String origin;
  final String destination;
  final String departureTime;
  final List<String> daysOfWeek;
  final List<AgreementMember> drivers;
  final List<AgreementMember> passengers;
  final String status;

  const RideAgreement({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.daysOfWeek,
    required this.drivers,
    required this.passengers,
    this.status = 'ACTIVE',
  });

  /// "08:30" -> "8:30 AM"
  String get departureTimeLabel {
    final parts = departureTime.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null) return departureTime;

    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  /// "MONDAY" -> "Mon"
  static String shortDay(String day) {
    if (day.length < 3) return day;
    return day[0].toUpperCase() + day.substring(1, 3).toLowerCase();
  }

  factory RideAgreement.fromJson(Map<String, dynamic> json) {
    return RideAgreement(
      id: json['id'].toString(),
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      departureTime: json['departureTime'] as String,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>)
          .map((d) => d.toString())
          .toList(),
      drivers: (json['drivers'] as List<dynamic>)
          .map((m) => AgreementMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      passengers: (json['passengers'] as List<dynamic>)
          .map((m) => AgreementMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}