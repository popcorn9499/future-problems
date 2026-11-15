import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

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

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool includesAsterisk = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (includesAsterisk ? ' *' : ''),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: label == 'Additional Description' ? 300 : null,
          validator: includesAsterisk
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter $label';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            errorMaxLines: 2,
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ride Type *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _rideType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'arriving',
                  child: Text('Arriving at Campus'),
                ),
                DropdownMenuItem(
                  value: 'departing',
                  child: Text('Departing from Campus'),
                ),
                DropdownMenuItem(
                  value: 'roundTrip',
                  child: Text('Round Trip'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _rideType = value;

                  // Clear times that are no longer relevant.
                  if (value == 'arriving') {
                    _departureTime = null;
                  } else if (value == 'departing') {
                    _arrivalTime = null;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days of the week *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _days.map((day) {
            final isSelected = _selectedDays.contains(
              day.toUpperCase(),
            );

            return FilterChip(
              label: Text(day.substring(0, 3)),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day.toUpperCase());
                  } else {
                    _selectedDays.remove(day.toUpperCase());
                  }
                });
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectTime({required bool isArrival}) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: isArrival
          ? _arrivalTime ?? const TimeOfDay(hour: 7, minute: 15)
          : _departureTime ?? const TimeOfDay(hour: 17, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (selectedTime != null) {
      setState(() {
        if (isArrival) {
          _arrivalTime = selectedTime;
        } else {
          _departureTime = selectedTime;
        }
      });
    }
  }

  Widget _buildTimeSelector({
    required String label,
    required bool isArrival,
  }) {
    final selectedTime = isArrival ? _arrivalTime : _departureTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        InkWell(
          onTap: () => _selectTime(isArrival: isArrival),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTime == null
                        ? 'Select time'
                        : selectedTime.format(context),
                    style: TextStyle(
                      color: selectedTime == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideTimeSelectors() {
    switch (_rideType) {
      case 'arriving':
        return _buildTimeSelector(
          label: 'Desired campus arrival time',
          isArrival: true,
        );

      case 'departing':
        return _buildTimeSelector(
          label: 'Desired campus departure time',
          isArrival: false,
        );

      case 'roundTrip':
        return _buildPair(
          _buildTimeSelector(
            label: 'Campus arrival time',
            isArrival: true,
          ),
          _buildTimeSelector(
            label: 'Campus departure time',
            isArrival: false,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
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

  Widget _buildPair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            children: [
              first,
              const SizedBox(height: 18),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
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

                          _buildPair(
                            _buildTextField(
                              label: 'City',
                              hint: 'Enter your city',
                              controller: _cityController,
                              icon: Icons.location_city_outlined,
                            ),
                            _buildTextField(
                              label: 'Street Address',
                              hint: 'Enter your address',
                              controller: _streetAddressController,
                              icon: Icons.location_on_outlined,
                            ),
                          ),

                         const SizedBox(height: 24),

                          _buildRideTypeSelector(),

                          const SizedBox(height: 24),

                          _buildRideTimeSelectors(),

                          const SizedBox(height: 24),

                          _buildAskingForDriversCheckbox(),

                          const SizedBox(height: 24),

                          _buildPassengerNumSelector(),

                          const SizedBox(height: 24),
                          
                          _buildDaySelector(),
                  
                          const SizedBox(height: 24),

                          _buildTextField(
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