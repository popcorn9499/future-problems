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
  
  TimeOfDay? _arrivalTime;
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

    if (_arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an arrival time.'),
        ),
      );
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
    
    final String arrivalString =
        '${_arrivalTime!.hour.toString().padLeft(2, '0')}:'
        '${_arrivalTime!.minute.toString().padLeft(2, '0')}';

    await _rideOfferController.createRideOffer(
      userId: widget.userId,
      city: _cityController.text.trim(),
      streetAddress: _streetAddressController.text.trim(),
      arrivalTime: arrivalString,
      daysOfWeek: _selectedDays,
      passengerNum: _passengerNum!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (_rideOfferController.createdRideOffer != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride offer created successfully!'),
        ),
      );

      Navigator.pop(context);
    }
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

  Future<void> _selectArrivalTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _arrivalTime ?? const TimeOfDay(hour: 7, minute: 15),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (newTime != null) {
      setState(() {
        _arrivalTime = newTime;
      });
    }
  }

  Widget _buildArrivalTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desired campus arrival time *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectArrivalTime,
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
                Text(
                  _arrivalTime == null
                      ? 'Select arrival time'
                      : _arrivalTime!.format(context),
                  style: TextStyle(
                    color: _arrivalTime == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
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

        DropdownButtonFormField<int>(
          initialValue: _passengerNum,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select number of available seats',
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
          items: List.generate(9, (index) {
            final number = index + 1;

            return DropdownMenuItem<int>(
              value: number,
              child: Text('$number'),
            );
          }),
          validator: (value) {
            if (value == null) {
              return 'Please select the number of available seats';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _passengerNum = value;
            });
          },
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
      appBar: AppBar(
        title: const Text(
          'Create Ride Offer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
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
                          // Heading
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

                          // City and Street Address
                          _buildPair(
                            _buildTextField(
                              label: 'City',
                              hint: 'Enter your city',
                              controller: _cityController,
                              icon: Icons.location_city_outlined,
                            ),
                            _buildTextField(
                              label: 'Street Address',
                              hint: 'Enter your starting address',
                              controller: _streetAddressController,
                              icon: Icons.location_on_outlined,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildArrivalTimeSelector(),

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

                          SizedBox(
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
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