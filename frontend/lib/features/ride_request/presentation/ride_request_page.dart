import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/invalid_address_dialog.dart';
import '../../../core/widgets/pickup_map_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ride_form_widgets.dart';
import '../ride_request_controller.dart';
import '../ride_request_service.dart';

class RideRequestPage extends StatefulWidget {
  const RideRequestPage({super.key, required this.userId, this.service});

  final String userId;
  final RideRequestService? service;

  @override
  State<RideRequestPage> createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage> {
  final _formKey = GlobalKey<FormState>();

  late final RideRequestService _rideRequestService;
  late final RideRequestController _rideRequestController;

  final _cityController = TextEditingController();
  final _streetAddressController = TextEditingController();
  LatLng? _pickupPoint;
  final _descriptionController = TextEditingController();
  final List<String> _selectedDays = [];
  String _rideType = 'arriving';

  TimeOfDay? _arrivalTime;
  TimeOfDay? _departureTime;

  @override
  void initState() {
    super.initState();

    _rideRequestService = widget.service ?? RideRequestService();
    _rideRequestController = RideRequestController(_rideRequestService);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _streetAddressController.dispose();
    _descriptionController.dispose();
    _rideRequestController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rideType == 'arriving' || _rideType == 'roundTrip') {
      if (_arrivalTime == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Choose when you need to arrive at campus.')));
        return;
      }
    }

    if (_rideType == 'departing' || _rideType == 'roundTrip') {
      if (_departureTime == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Choose when you want to leave campus.')));
        return;
      }
    }

    if ((_rideType == 'roundTrip') &&
        _departureTime != null &&
        _arrivalTime != null) {
      final arrivalMinutes =
          _arrivalTime!.hour * 60 + _arrivalTime!.minute;

      final departureMinutes =
          _departureTime!.hour * 60 + _departureTime!.minute;

      if (departureMinutes <= arrivalMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your campus departure must be after your campus arrival.',
            ),
          ),
        );
        return;
      }
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select at least one day.')));
      return;
    }

    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;

      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }

    await _rideRequestController.createRideRequest(
      userId: widget.userId,
      rideType: _rideType,
      city: _cityController.text.trim(),
      streetAddress: _streetAddressController.text.trim(),
      location: _pickupPoint,
      arrivalTime: formatTime(_arrivalTime),
      departureTime: formatTime(_departureTime),
      daysOfWeek: _selectedDays,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (_rideRequestController.invalidAddress) {
      await showInvalidAddressDialog(context, _rideRequestController.errorMessage!);
      return;
    }

    if (_rideRequestController.createdRideRequest != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ride request created successfully!')));

      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _cityController.clear();
      _streetAddressController.clear();
      _pickupPoint = null;
      _descriptionController.clear();

      _arrivalTime = null;
      _departureTime = null;

      _rideType = 'arriving';

      _selectedDays.clear();
    });

    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListenableBuilder(
                listenable: _rideRequestController,
                builder: (context, child) {
                  return Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEAE6DF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Request a Ride',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Let fellow Bisons know when and where you need a ride.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                          ),

                          const SizedBox(height: 32),

                          RideFormPair(
                            first: RideTextField(
                              label: 'City',
                              hint: 'Enter your city',
                              controller: _cityController,
                              icon: Icons.location_city_outlined,
                            ),
                            second: RideTextField(
                              label: _pickupPoint == null ? 'Street Address' : 'Pickup label',
                              hint: _pickupPoint == null ? 'Enter your address' : 'Pinned pickup',
                              includesAsterisk: _pickupPoint == null,
                              controller: _streetAddressController,
                              icon: Icons.location_on_outlined,
                              suffixIcon: PickupMapButton(
                                point: _pickupPoint,
                                onChanged: _rideRequestController.isLoading
                                    ? null
                                    : (point) => setState(() => _pickupPoint = point),
                              ),
                            ),
                          ),
                          if (_pickupPoint != null)
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: _rideRequestController.isLoading
                                    ? null
                                    : () => setState(() {
                                        _streetAddressController.clear();
                                        _pickupPoint = null;
                                      }),
                                child: const Text('Use street address'),
                              ),
                            ),

                          const SizedBox(height: 24),

                          RideTypeSelector(
                            rideType: _rideType,
                            onChanged: (value) {
                              setState(() {
                                _rideType = value;

                                if (value == 'arriving') {
                                  _departureTime = null;
                                } else if (value == 'departing') {
                                  _arrivalTime = null;
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          RideTimeSelectors(
                            rideType: _rideType,
                            arrivalTime: _arrivalTime,
                            departureTime: _departureTime,
                            onArrivalChanged: (time) {
                              setState(() {
                                _arrivalTime = time;
                              });
                            },
                            onDepartureChanged: (time) {
                              setState(() {
                                _departureTime = time;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          RideDaySelector(
                            selectedDays: _selectedDays,
                            onChanged: (days) {
                              setState(() {
                                _selectedDays
                                  ..clear()
                                  ..addAll(days);
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          RideTextField(
                            label: 'Additional Description',
                            hint: 'Enter any additional details',
                            controller: _descriptionController,
                            icon: Icons.description_outlined,
                            includesAsterisk: false,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 28),

                          if (_rideRequestController.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _rideRequestController.errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: OutlinedButton.icon(
                                    onPressed: _rideRequestController.isLoading
                                        ? null
                                        : () {
                                            _resetForm();

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Form has been reset.')),
                                            );
                                          },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text(
                                      'Reset',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _rideRequestController.isLoading
                                        ? null
                                        : _submitRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _rideRequestController.isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Submit Ride Offer',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'GoBison • Ride with the herd. © OpenStreetMap contributors',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
