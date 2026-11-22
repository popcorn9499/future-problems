import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/pickup_map_picker.dart';
import '../ride_request_controller.dart' show extractErrorCode;
import '../../ride_offer/ride_offer_service.dart';
import '../ride_request_service.dart';

class EditRideRequestDialog extends StatefulWidget {
  const EditRideRequestDialog({
    super.key,
    required this.legs,
    required this.service,
  }) : offerService = null;

  const EditRideRequestDialog.offer({
    super.key,
    required this.legs,
    required RideOfferService service,
  }) : offerService = service,
       service = null;

  final List<Map<String, dynamic>> legs;
  final RideRequestService? service;
  final RideOfferService? offerService;

  @override
  State<EditRideRequestDialog> createState() => _EditRideRequestDialogState();
}

class _EditRideRequestDialogState extends State<EditRideRequestDialog> {
  static const weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
  ];
  static final timeFormat = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  final form = GlobalKey<FormState>();
  late final first = widget.legs.first;
  late String city = first['city'] as String;
  late String street = first['streetAddress'] as String;
  LatLng? pickupPoint;
  late String description = first['description'] as String? ?? '';
  late final legacyDays = [
    for (final day in const ['SATURDAY', 'SUNDAY'])
      if (widget.legs.any((leg) => (leg['daysOfWeek'] as List).contains(day)))
        day,
  ];
  late final availableDays = [...weekdays, ...legacyDays];
  late final days = {
    ...List<String>.from(first['daysOfWeek'] as List),
    ...legacyDays,
  };
  late String? arrival = _time('arriving', 'arrivalTime');
  late String? departure = _time('departing', 'departureTime');

  late String seats = (first['passengerNum'] as int).toString();
  late bool askingForDrivers = first['askingForDrivers'] as bool;
  String get kind => widget.offerService == null ? 'request' : 'offer';
  bool saving = false;
  String? error;

  LatLng? get savedPoint {
    final location = first['location'];
    if (location is! Map) return null;
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    if (latitude is! num || longitude is! num) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }

  String? _time(String type, String field) {
    for (final leg in widget.legs) {
      if (leg['rideType'] == type) return leg[field] as String? ?? '';
    }
    return null;
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> change, {
    bool time = false,
    bool required = true,
    Key? key,
  }) {
    return TextFormField(
      key: key,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      enabled: !saving,
      onChanged: change,
      validator: (text) {
        final input = text?.trim() ?? '';
        if (time) {
          return timeFormat.hasMatch(input)
              ? null
              : 'Use HH:mm, for example 08:30.';
        }
        if (required && input.isEmpty) return 'Required';
        return input.length > 255 ? 'Use at most 255 characters.' : null;
      },
    );
  }

  Future<void> _save() async {
    if (saving || !form.currentState!.validate()) return;

    final needsWeekday =
        !weekdays.any(days.contains) &&
        widget.legs.any(
          (leg) => !(leg['daysOfWeek'] as List).any(days.contains),
        );
    if (days.isEmpty || needsWeekday) {
      setState(() => error = 'Choose at least one day for each leg.');
      return;
    }

    if (arrival != null &&
        departure != null &&
        departure!.trim().compareTo(arrival!.trim()) <= 0) {
      setState(() => error = 'Your campus departure must be after your campus arrival.');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final selectedDays = availableDays.where(days.contains).toList();
      final note = description.trim().isEmpty ? null : description.trim();
      final offerService = widget.offerService;
      if (offerService == null) {
        await widget.service!.updateRideRequest(
          requestId: first['requestId'] as String,
          roundTrip: first['roundTripId'] != null,
          city: city.trim(),
          streetAddress: street.trim(),
          location: pickupPoint,
          daysOfWeek: selectedDays,
          arrivalTime: arrival?.trim(),
          departureTime: departure?.trim(),
          description: note,
        );
      } else {
        await offerService.updateRideOffer(
          offerId: first['offerId'] as String,
          city: city.trim(),
          streetAddress: street.trim(),
          location: pickupPoint,
          daysOfWeek: selectedDays,
          arrivalTime: arrival?.trim(),
          departureTime: departure?.trim(),
          description: note,
          passengerNum: int.parse(seats.trim(), radix: 10),
          askingForDrivers: askingForDrivers,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = switch (extractErrorCode(e)) {
          401 => 'Your session expired. Sign in again.',
          403 => 'You do not have permission to edit this $kind.',
          404 || 409 =>
            'This $kind has changed or can no longer be edited. Close and refresh.',
          422 => 'Address not found. Check the city and street address.',
          _ => 'Unable to save your changes. Please try again.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: Text(
          first['roundTripId'] == null ? 'Edit ride $kind' : 'Edit both legs',
        ),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('City', city, (value) => city = value),
                _field(
                  pickupPoint == null ? 'Street address' : 'Pickup label',
                  street,
                  (value) => street = value,
                  required: pickupPoint == null,
                  key: ValueKey(pickupPoint == null),
                ),
                PickupMapButton(
                  point: pickupPoint,
                  savedPoint: savedPoint,
                  onChanged: saving
                      ? null
                      : (point) => setState(() {
                          if (point == null) street = '';
                          pickupPoint = point;
                        }),
                ),
                if (arrival != null)
                  _field(
                    'Arrive at campus by (HH:mm)',
                    arrival!,
                    (value) => arrival = value,
                    time: true,
                  ),
                if (departure != null)
                  _field(
                    'Leave campus at (HH:mm)',
                    departure!,
                    (value) => departure = value,
                    time: true,
                  ),
                const SizedBox(height: 12),
                const Text('Days of the week'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final day in availableDays)
                      FilterChip(
                        label: Text(day.substring(0, 3)),
                        selected: days.contains(day),
                        onSelected: saving
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    days.add(day);
                                  } else {
                                    days.remove(day);
                                  }
                                });
                              },
                      ),
                  ],
                ),
                if (widget.offerService != null) ...[
                  TextFormField(
                    initialValue: seats,
                    enabled: !saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Available seats',
                    ),
                    onChanged: (value) => seats = value,
                    validator: (value) {
                      final count = int.tryParse(
                        value?.trim() ?? '',
                        radix: 10,
                      );
                      if (count == null || count < 1 || count > 9) {
                        return 'Enter 1 to 9 seats.';
                      }
                      return null;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Looking for a driver'),
                    value: askingForDrivers,
                    onChanged: saving
                        ? null
                        : (value) => setState(() => askingForDrivers = value),
                  ),
                ],
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  enabled: !saving,
                  onChanged: (value) => description = value,
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Saving...' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
