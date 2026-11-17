import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ride_form_widgets.dart';
import '../ride_offer_controller.dart';
import '../ride_offer_service.dart';

class RideOfferPage extends StatefulWidget {

  const RideOfferPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<RideOfferPage> createState() =>
      _RideOfferPageState();
}

class _RideOfferPageState extends State<RideOfferPage> {
  final _formKey = GlobalKey<FormState>();

  late final RideOfferService _rideOfferService;
  late final RideOfferController _rideOfferController;

  final _cityController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _showPassengerError = false;
  bool _askingForDrivers = false;
  
  String _rideType = 'arriving';

  TimeOfDay? _arrivalTime;
  TimeOfDay? _departureTime;

  int? _passengerNum;
  final List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();

    _rideOfferService = RideOfferService();
    _rideOfferController =
        RideOfferController(_rideOfferService);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _streetAddressController.dispose();
    _descriptionController.dispose();
    _rideOfferController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if ((_rideType == 'arriving' || _rideType == 'roundTrip') &&
        _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an arrival time.'),
        ),
      );
      return;
    }

    if ((_rideType == 'departing' || _rideType == 'roundTrip') &&
        _departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a departure time.'),
        ),
      );
      return;
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
              'Departure time must be after arrival time.',
            ),
          ),
        );
        return;
      }
    }

    if (_passengerNum == null) {
      setState(() {
        _showPassengerError = true;
      });
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day.'),
        ),
      );
      return;
    }
        
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;

      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }


    await _rideOfferController.createRideOffer(
      userId: widget.userId,
      rideType: _rideType,
      city: _cityController.text.trim(),
      streetAddress: _streetAddressController.text.trim(),
      arrivalTime: formatTime(_arrivalTime),
      departureTime: formatTime(_departureTime),
      daysOfWeek: _selectedDays,
      passengerNum: _passengerNum!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      askingForDrivers: _askingForDrivers,
    );

    if (!mounted) return;

    if (_rideOfferController.createdRideOffer != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride offer created successfully!'),
        ),
      );

      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _cityController.clear();
      _streetAddressController.clear();
      _descriptionController.clear();

      _arrivalTime = null;
      _departureTime = null;

      _passengerNum = null;
      _selectedDays.clear();

      _showPassengerError = false;
      _askingForDrivers = false;
      _rideType = 'arriving';
    });

    _formKey.currentState?.reset();
  }

  Widget _buildAskingForDriversCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Carpool',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: AppColors.background,
              child: CheckboxListTile(
                value: _askingForDrivers,
                onChanged: (value) {
                  setState(() {
                    _askingForDrivers = value ?? false;
                  });
                },
                title: const Text(
                  'I am looking for other drivers to rideshare with.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerNumSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Available Passenger Seats *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _passengerNum,
              hint: const Text(
                'Select number of available seats',
              ),
              isExpanded: true,
              items: List.generate(9, (index) {
                final number = index + 1;

                return DropdownMenuItem<int>(
                  value: number,
                  child: Text('$number'),
                  );
              }),
              onChanged: (value) {
                setState(() {
                  _passengerNum = value;
                  _showPassengerError = false;
                });
              },
            ),
          ),
        ),

        if (_showPassengerError && _passengerNum == null)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Please select the number of available seats',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
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
                listenable: _rideOfferController,
                builder: (context, child) {
                  return Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFEAE6DF),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Offer a Ride',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Let fellow Bisons know when and where you have room for a ride.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
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
                              label: 'Street Address',
                              hint: 'Enter your address',
                              controller: _streetAddressController,
                              icon: Icons.location_on_outlined,
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

                          _buildAskingForDriversCheckbox(),

                          const SizedBox(height: 24),

                          _buildPassengerNumSelector(),

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

                          if (_rideOfferController.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _rideOfferController.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
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
                                    onPressed: _rideOfferController.isLoading
                                        ? null
                                        : () {
                                            _resetForm();

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Form has been reset.'),
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text(
                                      'Reset',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
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
                                    onPressed: _rideOfferController.isLoading
                                        ? null
                                        : _submitOffer,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _rideOfferController.isLoading
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
                            'GoBison • Ride with the herd.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
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