import 'package:flutter/material.dart';

import '../ride_request_controller.dart' show extractErrorCode;
import '../ride_request_service.dart';

class EditRideRequestDialog extends StatefulWidget {
  const EditRideRequestDialog({
    super.key,
    required this.legs,
    required this.service,
  });

  final List<Map<String, dynamic>> legs;
  final RideRequestService service;

  @override
  State<EditRideRequestDialog> createState() => _EditRideRequestDialogState();
}

class _EditRideRequestDialogState extends State<EditRideRequestDialog> {
  static const weekdays = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
    'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];
  static final timeFormat = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  final form = GlobalKey<FormState>();
  late final first = widget.legs.first;
  late String city = first['city'] as String;
  late String street = first['streetAddress'] as String;
  late String description = first['description'] as String? ?? '';
  late final days = Set<String>.from(first['daysOfWeek'] as List);
  late String? arrival = _time('arriving', 'arrivalTime');
  late String? departure = _time('departing', 'departureTime');

  bool saving = false;
  String? error;

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
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      enabled: !saving,
      onChanged: change,
      validator: (text) {
        final input = text?.trim() ?? '';
        if (time) {
          return timeFormat.hasMatch(input) ? null : 'Use HH:mm, for example 08:30.';
        }
        if (input.isEmpty) return 'Required';
        return input.length > 255 ? 'Use at most 255 characters.' : null;
      },
    );
  }

  Future<void> _save() async {
    if (saving || !form.currentState!.validate()) return;

    if (days.isEmpty) {
      setState(() => error = 'Choose at least one day.');
      return;
    }

    if (arrival != null &&
        departure != null &&
        departure!.trim().compareTo(arrival!.trim()) <= 0) {
      setState(() => error = 'Departure must be later than arrival.');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await widget.service.updateRideRequest(
        requestId: first['requestId'] as String,
        roundTrip: first['roundTripId'] != null,
        city: city.trim(),
        streetAddress: street.trim(),
        arrivalTime: arrival?.trim(),
        departureTime: departure?.trim(),
        daysOfWeek: weekdays.where(days.contains).toList(),
        description: description.trim().isEmpty ? null : description.trim(),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = switch (extractErrorCode(e)) {
          401 => 'Your session expired. Sign in again.',
          403 => 'You do not have permission to edit this request.',
          404 || 409 => 'This request has changed or can no longer be edited. Close and refresh.',
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
        title: Text(first['roundTripId'] == null ? 'Edit ride request' : 'Edit both legs'),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('City', city, (value) => city = value),
                _field('Street address', street, (value) => street = value),
                if (arrival != null)
                  _field('Arrival (HH:mm)', arrival!, (value) => arrival = value, time: true),
                if (departure != null)
                  _field('Departure (HH:mm)', departure!, (value) => departure = value, time: true),
                const SizedBox(height: 12),
                const Text('Days of the week'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final day in weekdays)
                      FilterChip(
                        label: Text(day.substring(0, 3)),
                        selected: days.contains(day),
                        onSelected: saving ? null : (selected) {
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
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  enabled: !saving,
                  onChanged: (value) => description = value,
                ),
                if (error != null)
                  Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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