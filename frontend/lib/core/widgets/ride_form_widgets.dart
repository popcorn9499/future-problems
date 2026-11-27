import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RideTextField extends StatelessWidget {
  const RideTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.includesAsterisk = true,
    this.maxLines = 1,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool includesAsterisk;
  final int maxLines;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
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
            suffixIcon: suffixIcon,
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
}

class RideTypeSelector extends StatelessWidget {
  const RideTypeSelector({
    super.key,
    required this.rideType,
    required this.onChanged,
  });

  final String rideType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
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
              value: rideType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'arriving',
                  child: Text('To campus'),
                ),
                DropdownMenuItem(
                  value: 'departing',
                  child: Text('From campus'),
                ),
                DropdownMenuItem(
                  value: 'roundTrip',
                  child: Text('Round trip'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class RideDaySelector extends StatelessWidget {
  const RideDaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  final List<String> selectedDays;
  final ValueChanged<List<String>> onChanged;

  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  Widget build(BuildContext context) {
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
          children: days.map((day) {
            final dayValue = day.toUpperCase();
            final isSelected = selectedDays.contains(dayValue);

            return FilterChip(
              label: Text(day.substring(0, 3)),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (selected) {
                final updatedDays = List<String>.from(selectedDays);

                if (selected) {
                  updatedDays.add(dayValue);
                } else {
                  updatedDays.remove(dayValue);
                }

                onChanged(updatedDays);
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
}

class RideTimeSelector extends StatelessWidget {
  const RideTimeSelector({
    super.key,
    required this.label,
    required this.isArrival,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  final String label;
  final bool isArrival;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ??
          (isArrival
              ? const TimeOfDay(hour: 7, minute: 15)
              : const TimeOfDay(hour: 17, minute: 0)),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (time != null) {
      onTimeSelected(time);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: () => _selectTime(context),
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
                        : selectedTime!.format(context),
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
}

class RideTimeSelectors extends StatelessWidget {
  const RideTimeSelectors({
    super.key,
    required this.rideType,
    required this.arrivalTime,
    required this.departureTime,
    required this.onArrivalChanged,
    required this.onDepartureChanged,
  });

  final String rideType;
  final TimeOfDay? arrivalTime;
  final TimeOfDay? departureTime;
  final ValueChanged<TimeOfDay> onArrivalChanged;
  final ValueChanged<TimeOfDay> onDepartureChanged;

  @override
  Widget build(BuildContext context) {
    if (rideType == 'arriving') {
      return RideTimeSelector(
        label: 'Arrive at campus by',
        isArrival: true,
        selectedTime: arrivalTime,
        onTimeSelected: onArrivalChanged,
      );
    }

    if (rideType == 'departing') {
      return RideTimeSelector(
        label: 'Leave campus at',
        isArrival: false,
        selectedTime: departureTime,
        onTimeSelected: onDepartureChanged,
      );
    }

    if (rideType == 'roundTrip') {
      return RideFormPair(
        first: RideTimeSelector(
          label: 'Arrive at campus by',
          isArrival: true,
          selectedTime: arrivalTime,
          onTimeSelected: onArrivalChanged,
        ),
        second: RideTimeSelector(
          label: 'Leave campus at',
          isArrival: false,
          selectedTime: departureTime,
          onTimeSelected: onDepartureChanged,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class RideFormPair extends StatelessWidget {
  const RideFormPair({
    super.key,
    required this.first,
    required this.second,
  });

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
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
}
