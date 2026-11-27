import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/models/user.dart';
import '../../core/navigation/no_animation_page_route.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/avatar_color_option.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/presentation/login_page.dart';
import '../messages/messaging_controller.dart';
import '../messages/messaging_service.dart';
import '../messages/models/conversation.dart';
import '../messages/presentation/chat_page.dart';
import '../ride_offer/ride_offer_service.dart';
import '../ride_request/ride_request_service.dart';

import 'package:url_launcher/url_launcher.dart';

/// Location privacy mode.
/// true  = pins are replaced by circles whose center is shifted by a random
///         (but stable) offset, so the exact location is hidden.
/// false = exact pins are shown.
const bool kHideExactLocations = true;

typedef _MapLoadError = ({String source, String detail, bool sessionExpired});

enum _ListingView { all, requests, offers }

class CarpoolMultiSourceMapPage extends StatefulWidget {
  const CarpoolMultiSourceMapPage({super.key, required this.user});
  final User user;

  @override
  State<CarpoolMultiSourceMapPage> createState() =>
      _CarpoolMultiSourceMapPageState();
}

/// A ride request or offer prepared for display on the map
class MapRideItem {
  final LatLng point;
  final bool isOffer; // true = Offer (Orange), false = Request (Blue)
  final Map<String, dynamic> details;

  const MapRideItem({
    required this.point,
    required this.isOffer,
    required this.details,
  });
}

class _CarpoolMultiSourceMapPageState extends State<CarpoolMultiSourceMapPage> {
  late final RideOfferService _rideOfferService;
  late final RideRequestService _rideRequestService;
  final _messagingService = MessagingService();

  // Loaded rides; markers (single + grouped) are built from these on every
  // zoom change so grouping always matches what's on screen.
  final List<MapRideItem> _rideItems = [];
  double _currentZoom = 9.0;

  // Grouping: markers closer than this on screen are merged into one
  static const double _clusterRadiusPx = 48;

  // Privacy circles: radius covers the real point even after the offset
  static const double _privacyRadiusMeters = 500;
  static const double _minJitterMeters = 100;
  static const double _maxJitterMeters = 400;
  static const double _minCircleDiameterPx = 28;
  static const double _maxCircleDiameterPx = 400;

  final TextEditingController _cityController = TextEditingController();

  bool _isLoading = true;

  String? _errorMessage;
  bool _sessionExpired = false;
  bool _errorDialogOpen = false;
  int _loadGeneration = 0;

  // Active Filter States (null / empty = omitted from API request)
  String? _selectedCity;
  final List<String> _selectedDaysOfWeek = [];
  String? _selectedRideType;
  TimeOfDay? _selectedDepartureTime;
  TimeOfDay? _selectedArrivalTime;

  _ListingView _listingView = _ListingView.all;
  bool _onlyOffersLookingForDrivers = false;
  Timer? _cityFilterTimer;

  static const List<String> _daysOfWeekOptions = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  static const List<String> _rideTypeOptions = [
    'arriving',
    'departing',
    'roundTrip',
  ];

  LatLng _mapCenter = const LatLng(
    49.8951,
    -97.1384,
  ); // Default fallback (Winnipeg center)

  // Geographic bounding box for Manitoba (Southwest to Northeast corners)
  static final LatLngBounds _manitobaBounds = LatLngBounds(
    const LatLng(49.0, -102.0), // Southwest corner (US/SK border)
    const LatLng(60.0, -88.9), // Northeast corner (NU border / Hudson Bay)
  );

  @override
  void initState() {
    super.initState();
    _rideOfferService = RideOfferService();
    _rideRequestService = RideRequestService();
    _loadMapMarkers();
  }

  @override
  void dispose() {
    _cityFilterTimer?.cancel();
    _cityController.dispose();
    _messagingService.close();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      (_selectedCity != null && _selectedCity!.isNotEmpty) ||
      _selectedDaysOfWeek.isNotEmpty ||
      _selectedRideType != null ||
      _selectedDepartureTime != null ||
      _selectedArrivalTime != null ||
      _listingView != _ListingView.all ||
      _onlyOffersLookingForDrivers;

  /// Formats selected days in canonical calendar order (e.g., "MONDAY,TUESDAY,THURSDAY")
  String? get _formattedDaysOfWeekParam {
    if (_selectedDaysOfWeek.isEmpty) return null;
    final ordered = _daysOfWeekOptions
        .where((day) => _selectedDaysOfWeek.contains(day))
        .toList();
    return ordered.join(',');
  }

  void _clearAllFilters() {
    setState(() {
      _cityController.clear();
      _selectedCity = null;
      _selectedDaysOfWeek.clear();
      _selectedRideType = null;
      _selectedDepartureTime = null;
      _selectedArrivalTime = null;
      _listingView = _ListingView.all;
      _onlyOffersLookingForDrivers = false;
    });
    _loadMapMarkers();
  }

  /// Opens a multi-select dialog for picking multiple days of the week
  Future<void> _pickDaysOfWeek() async {
    final tempSelected = List<String>.from(_selectedDaysOfWeek);

    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Days of the Week'),
              content: SizedBox(
                width: 280,
                child: ListView(
                  shrinkWrap: true,
                  children: _daysOfWeekOptions.map((day) {
                    final isChecked = tempSelected.contains(day);
                    final displayLabel =
                        day[0] + day.substring(1).toLowerCase();
                    return CheckboxListTile(
                      dense: true,
                      title: Text(displayLabel),
                      value: isChecked,
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            tempSelected.add(day);
                          } else {
                            tempSelected.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() => tempSelected.clear());
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSelected),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDaysOfWeek
          ..clear()
          ..addAll(result);
      });
      _loadMapMarkers();
    }
  }

  /// Opens a TimePicker and formats the result as HH:mm (24-hour)
  Future<void> _pickTime({required bool isDeparture}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 30),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isDeparture) {
          _selectedDepartureTime = picked;
        } else {
          _selectedArrivalTime = picked;
        }
      });
      _loadMapMarkers();
    }
  }

  String? _apiFilterTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Calls the service to get data, then converts items into UI Markers
  Future<void> _loadMapMarkers() async {
    _cityFilterTimer?.cancel();
    if (_sessionExpired) return;
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _rideItems.clear();
      _errorMessage = null;
    });
    final errors = <_MapLoadError>[];

    try {
      final rideItems = await _fetchMapRides(errors);
      if (!mounted || _sessionExpired) return;
      final expired = errors.any((error) => error.sessionExpired);
      if (!expired && generation != _loadGeneration) return;

      for (final item in rideItems) {
        if (!item.isOffer) {
          _mapCenter = item.point;
        }
      }

      setState(() {
        _rideItems.addAll(rideItems);
        _isLoading = false;
        _sessionExpired = expired;
        if (errors.isNotEmpty && !_sessionExpired) {
          _errorMessage = errors.length > 1 &&
                  errors.every((error) => error.detail == errors.first.detail)
              ? errors.first.detail
              : errors
                  .map(
                    (error) => '${error.source} couldn’t load. ${error.detail}',
                  )
                  .join('\n\n');
        }
      });
    } catch (e) {
      if (!mounted || _sessionExpired) return;
      final error = _describeError(e, 'Rides');
      if (!error.sessionExpired && generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _sessionExpired = error.sessionExpired;
        _errorMessage = error.sessionExpired ? null : error.detail;
      });
    }
  }

  _MapLoadError _describeError(Object error, String source) {
    // The ride services include the status before the response body.
    final status = int.tryParse(
      RegExp(r'^Exception: Retrieving ride (?:requests|offers) failed \(([45]\d\d)\):')
              .firstMatch(error.toString())
              ?.group(1) ??
          '',
    );
    if (status == 401) return (source: source, detail: '', sessionExpired: true);

    final detail = switch (status) {
      400 => 'Check your filters and try again.',
      403 => 'You don’t have permission to view these rides.',
      final int code when code >= 500 =>
        'The server is having trouble. Please try again later.',
      _ when error is http.ClientException =>
        'Check your connection and try again.',
      _ => 'Please try again.',
    };
    return (source: source, detail: detail, sessionExpired: false);
  }

  bool get _hasLoadError => _sessionExpired || _errorMessage != null;

  void _scheduleErrorDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _errorDialogOpen ||
          !_hasLoadError ||
          !TickerMode.of(context) ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      _showErrorDialog();
    });
  }

  Future<void> _showErrorDialog() async {
    _errorDialogOpen = true;
    final generation = _loadGeneration;
    final expired = _sessionExpired;
    final message = expired
        ? 'Sign in again to continue using GoBison.'
        : _errorMessage!;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: !expired,
      builder: (dialogContext) => PopScope(
        canPop: !expired,
        child: AlertDialog(
          alignment: Alignment.center,
          constraints: const BoxConstraints(maxWidth: 400),
          scrollable: true,
          title: Text(expired ? 'Your session has ended' : 'Couldn’t load rides'),
          content: Text(
            message,
            style: Theme.of(dialogContext).textTheme.bodyLarge,
          ),
          actions: [
            if (!expired)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Dismiss'),
              ),
            FilledButton(
              onPressed: expired
                  ? _signIn
                  : () => Navigator.of(dialogContext).pop(true),
              child: Text(expired ? 'Sign in' : 'Retry'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _errorDialogOpen = false;
      if (generation == _loadGeneration) _errorMessage = null;
    });
    if (retry == true && generation == _loadGeneration) await _loadMapMarkers();
  }

  Future<void> _signIn() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      NoAnimationPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  /// Fetches ride requests and offers from the API and resolves all coordinates
  Future<List<MapRideItem>> _fetchMapRides(
    List<_MapLoadError> errors,
  ) async {
    final List<MapRideItem> items = [];
    final listingView = _listingView;
    final onlyOffersLookingForDrivers = _onlyOffersLookingForDrivers;

    // 1. Fetch Live Requests with active filters
    if (listingView != _ListingView.offers) {
      try {
        final requestsData = await _rideRequestService.retrieveRideRequests(
          city: _selectedCity?.trim(),
          daysOfWeek: _formattedDaysOfWeekParam,
          //rideType: _selectedRideType, ============================================================== FIX THIS
          departureTime: _apiFilterTime(_selectedDepartureTime),
          arrivalTime: _apiFilterTime(_selectedArrivalTime),
        );
        final requestsList =
            requestsData['requests'] ??
            requestsData['data'] ??
            (requestsData is List ? requestsData : []);

        for (var req in requestsList) {
          if (_selectedRideType != null && //============================================================== FIX THIS
              req['rideType'] != _selectedRideType) {
            continue;
          }

          final locationMap = req['location'];
          LatLng? coords;

          if (locationMap is Map<String, dynamic>) {
            final lat = locationMap['latitude'];
            final lng = locationMap['longitude'];

            if (lat != null && lng != null) {
              coords = LatLng((lat as num).toDouble(), (lng as num).toDouble());
            }
          }
          if (coords != null) {
            items.add(
              MapRideItem(
                point: coords,
                isOffer: false,
                details: Map<String, dynamic>.from(req),
              ),
            );
          }
        }
      } catch (e) {
        final error = _describeError(e, 'Ride requests');
        errors.add(error);
        if (error.sessionExpired) return items;
      }
    }

    // 2. Fetch Live Offers with active filters
    if (listingView != _ListingView.requests) {
      try {
        final offersData = await _rideOfferService.retrieveRideOffers(
          city: _selectedCity?.trim(),
          daysOfWeek: _formattedDaysOfWeekParam,
          //rideType: _selectedRideType,  ============================================================== FIX THIS
          departureTime: _apiFilterTime(_selectedDepartureTime),
          arrivalTime: _apiFilterTime(_selectedArrivalTime),
        );
        final offersList =
            offersData['offers'] ??
            offersData['data'] ??
            (offersData is List ? offersData : []);

        for (var off in offersList) {
          if (onlyOffersLookingForDrivers && off['askingForDrivers'] != true) {
            continue;
          }
          if (_selectedRideType != null && //============================================================== FIX THIS
              off['rideType'] != _selectedRideType) {
            continue;
          }

          final locationMap = off['location'];
          LatLng? coords;

          if (locationMap is Map<String, dynamic>) {
            final lat = locationMap['latitude'];
            final lng = locationMap['longitude'];

            if (lat != null && lng != null) {
              coords = LatLng((lat as num).toDouble(), (lng as num).toDouble());
            }
          }
          if (coords != null) {
            items.add(
              MapRideItem(
                point: coords,
                isOffer: true,
                details: Map<String, dynamic>.from(off),
              ),
            );
          }
        }
      } catch (e) {
        errors.add(_describeError(e, 'Ride offers'));
      }
    }

    return items;
  }

  /// Helper to format selected days cleanly on the filter button
  String _getDaysButtonLabel() {
    if (_selectedDaysOfWeek.isEmpty) return 'Days of Week';
    final ordered = _daysOfWeekOptions
        .where((day) => _selectedDaysOfWeek.contains(day))
        .map((day) => day.substring(0, 3)) // e.g., MON, TUE, THU
        .toList();
    return ordered.join(', ');
  }

  static const double _filterHeight = 44;
  static const _filterRadius = BorderRadius.all(Radius.circular(8));
  static const _filterPadding = EdgeInsets.symmetric(horizontal: 12);
  static const _filterTextStyle = TextStyle(fontSize: 14);

  Color get _filterSelectedFill => Theme.of(context).colorScheme.secondaryContainer;
  Color get _filterOutline => Theme.of(context).colorScheme.outline;

  InputDecoration _filterInput(String label, {bool selected = false}) {
    final border = OutlineInputBorder(
      borderRadius: _filterRadius,
      borderSide: BorderSide(color: _filterOutline),
    );
    const selectedBorder = OutlineInputBorder(
      borderRadius: _filterRadius,
      borderSide: BorderSide(color: AppColors.primary),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: _filterTextStyle,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: border,
      enabledBorder: selected ? selectedBorder : border,
      focusedBorder: selectedBorder,
      filled: selected,
      fillColor: _filterSelectedFill,
    );
  }

  Widget _buildFilterBar() {
    final bool hasDays = _selectedDaysOfWeek.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  height: _filterHeight,
                  child: SegmentedButton<_ListingView>(
                    segments: [
                      for (final (view, label) in const [
                        (_ListingView.all, 'All rides'),
                        (_ListingView.requests, 'Requests'),
                        (_ListingView.offers, 'Offers'),
                      ])
                        ButtonSegment(
                          value: view,
                          label: SizedBox(
                            height: _filterHeight,
                            child: Center(widthFactor: 1, child: Text(label)),
                          ),
                        ),
                    ],
                    selected: {_listingView},
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      shape: const WidgetStatePropertyAll(
                        RoundedRectangleBorder(borderRadius: _filterRadius),
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(color: _filterOutline),
                      ),
                      padding: const WidgetStatePropertyAll(_filterPadding),
                      textStyle: const WidgetStatePropertyAll(_filterTextStyle),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? _filterSelectedFill
                            : null,
                      ),
                    ),
                    onSelectionChanged: (selection) {
                      final view = selection.single;
                      if (view == _listingView) return;
                      setState(() {
                        _listingView = view;
                        if (view == _ListingView.requests) {
                          _onlyOffersLookingForDrivers = false;
                        }
                      });
                      _loadMapMarkers();
                    },
                  ),
                ),
                if (_listingView != _ListingView.requests) _buildDriverSwitch(),
              ],
            ),
          ),
          // 1. City Text Input
          SizedBox(
            width: 170,
            height: _filterHeight,
            child: TextField(
              controller: _cityController,
              style: _filterTextStyle,
              textAlignVertical: TextAlignVertical.center,
              decoration: _filterInput(
                'City',
                selected: _selectedCity?.isNotEmpty == true,
              ).copyWith(
                hintText: 'e.g. Winnipeg',
                suffixIconConstraints: const BoxConstraints(minWidth: 36),
                suffixIcon: (_selectedCity != null && _selectedCity!.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _cityController.clear();
                          setState(() => _selectedCity = null);
                          _loadMapMarkers();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                setState(() {
                  _selectedCity = value.trim().isEmpty ? null : value.trim();
                });
                _loadMapMarkers();
              },
              onChanged: (value) {
                setState(() {
                  _selectedCity = value.trim().isEmpty ? null : value.trim();
                });
                _cityFilterTimer?.cancel();
                _cityFilterTimer = Timer(
                  const Duration(milliseconds: 350),
                  _loadMapMarkers,
                );
              },
            ),
          ),

          _buildFilterPicker(
            label: _getDaysButtonLabel(),
            icon: Icons.calendar_today,
            selected: hasDays,
            onTap: _pickDaysOfWeek,
            onClear: () {
              setState(() => _selectedDaysOfWeek.clear());
              _loadMapMarkers();
            },
            showDropdownIndicator: true,
          ),

          // 3. Ride Type Dropdown (arriving, departing, roundTrip + null to clear)
          SizedBox(
            width: 155,
            height: _filterHeight,
            child: DropdownButtonFormField<String?>(
              // Key forces the field to reset when Clear Filters changes the value
              key: ValueKey('rideType-$_selectedRideType'),
              initialValue: _selectedRideType,
              isDense: true,
              isExpanded:
                  true, // fit items to the 155px width instead of overflowing
              decoration: _filterInput(
                'Ride Type',
                selected: _selectedRideType != null,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.merge(_filterTextStyle),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Any', overflow: TextOverflow.ellipsis),
                ),
                ..._rideTypeOptions.map(
                  (type) => DropdownMenuItem<String?>(
                    value: type, // raw value still sent to the API
                    child: Text(
                      _rideTypeLabel(type),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRideType = value;
                  if (value == 'arriving') _selectedDepartureTime = null;
                  if (value == 'departing') _selectedArrivalTime = null;
                });
                _loadMapMarkers();
              },
            ),
          ),

          // 4. Arrival Time Picker Button (HH:mm)
          if (_selectedRideType != 'departing')
            _buildTimeFilterChip(
              label: 'Arrive at campus by',
              value: _selectedArrivalTime,
              onTap: () => _pickTime(isDeparture: false),
              onClear: () {
                setState(() => _selectedArrivalTime = null);
                _loadMapMarkers();
              },
            ),

          // 5. Departure Time Picker Button (HH:mm)
          if (_selectedRideType != 'arriving')
            _buildTimeFilterChip(
              label: 'Leave campus at',
              value: _selectedDepartureTime,
              onTap: () => _pickTime(isDeparture: true),
              onClear: () {
                setState(() => _selectedDepartureTime = null);
                _loadMapMarkers();
              },
            ),

          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverSwitch() {
    void changeSelection(bool value) {
      setState(() => _onlyOffersLookingForDrivers = value);
      _loadMapMarkers();
    }

    return MergeSemantics(
      child: InkWell(
        excludeFromSemantics: true,
        onTap: () => changeSelection(!_onlyOffersLookingForDrivers),
        borderRadius: _filterRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            height: _filterHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text('Looking for other drivers', style: _filterTextStyle),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _onlyOffersLookingForDrivers,
                  onChanged: changeSelection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) => _buildFilterPicker(
    label: value != null ? '$label · ${value.format(context)}' : label,
    icon: Icons.access_time,
    selected: value != null,
    onTap: onTap,
    onClear: onClear,
  );

  Widget _buildFilterPicker({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool showDropdownIndicator = false,
  }) {
    final color = selected
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: _filterRadius,
      child: Container(
        height: _filterHeight,
        padding: _filterPadding,
        decoration: BoxDecoration(
          color: selected ? _filterSelectedFill : null,
          border: Border.all(color: selected ? AppColors.primary : _filterOutline),
          borderRadius: _filterRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _filterTextStyle,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: color),
              ),
            ] else if (showDropdownIndicator)
              Icon(Icons.arrow_drop_down, size: 20, color: color),
          ],
        ),
      ),
    );
  }

  /// Displays a bottom sheet popup showing all fields from the selected ride item
  Future<void> _showRideDetailsModal(
    String title,
    Color headerColor,
    Map<String, dynamic> details, {
    required bool isOffer,
  }) async {
    final passengerCount = details['passengerNum'];
    final offerBadges = [
      if (isOffer && passengerCount is int && passengerCount > 0)
        Chip(
          avatar: const Icon(Icons.people_outline),
          label: Text(
            'Up to $passengerCount passenger${passengerCount == 1 ? '' : 's'}',
          ),
        ),
      if (isOffer && details['askingForDrivers'] == true)
        const Chip(
          avatar: Icon(Icons.directions_car_outlined),
          label: Text('Looking for other drivers'),
        ),
    ];
    final poster = details['poster'];
    final firstName = poster is Map && poster['firstName'] is String
        ? (poster['firstName'] as String).trim()
        : '';
    final lastName = poster is Map && poster['lastName'] is String
        ? (poster['lastName'] as String).trim()
        : '';
    final avatarColor = poster is Map && poster['avatarColor'] is String
        ? poster['avatarColor'] as String
        : null;
    final notes = _formatDetailValue(details['description']).trim();
    final savedDays = details['daysOfWeek'];
    final days = savedDays is List
        ? savedDays.whereType<String>().toSet()
        : <String>{};

    final ownerId = details['userId'];
    final recipientId = ownerId is String ? ownerId.trim() : '';
    final canMessage =
        recipientId.isNotEmpty &&
        recipientId.toLowerCase() != widget.user.id.toLowerCase();
    var isOpeningChat = false;
    String? chatError;

    final conversation = await showModalBottomSheet<Conversation>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> openChat() async {
            if (isOpeningChat) return;
            setSheetState(() {
              isOpeningChat = true;
              chatError = null;
            });
            try {
              final chat = await _messagingService.startConversation(
                recipientId,
              );
              if (sheetContext.mounted &&
                  ModalRoute.of(sheetContext)?.isCurrent == true) {
                Navigator.of(sheetContext).pop(chat);
              }
            } catch (_) {
              if (!sheetContext.mounted ||
                  ModalRoute.of(sheetContext)?.isCurrent != true) {
                return;
              }
              setSheetState(() {
                isOpeningChat = false;
                chatError = 'Could not open the chat. Try again.';
              });
            }
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_pin, color: headerColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: headerColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          _buildRideSchedule(
                            sheetContext,
                            details,
                            isOffer: isOffer,
                          ),
                          if (days.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Days',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            _buildDayBubbles(sheetContext, days),
                            const SizedBox(height: 6),
                          ],
                          if (offerBadges.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: offerBadges,
                              ),
                            ),
                          if (notes.isNotEmpty) ...[
                            const Divider(height: 24),
                            const Text(
                              'Ride notes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(notes),
                          ],
                          if (firstName.isNotEmpty) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                UserAvatar(
                                  firstName: firstName,
                                  lastName: lastName,
                                  radius: 18,
                                  backgroundColor: AvatarColorOption.getBackgroundColor(avatarColor),
                                  textColor: AvatarColorOption.getTextColor(avatarColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Posted by'),
                                      Text(
                                        '$firstName $lastName'.trim(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (chatError != null) Text(chatError!),
                    if (canMessage) ...[
                      const Divider(height: 24),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        overflowAlignment: OverflowBarAlignment.end,
                        spacing: 12,
                        overflowSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: isOpeningChat ? null : openChat,
                            child: Text(
                              isOpeningChat ? 'Opening chat…' : 'Message',
                            ),
                          ),
                          FilledButton(
                            onPressed: () {},
                            child: Text(
                              isOffer ? 'Ask to Join Ride' : 'Offer to Drive',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || conversation == null) return;

    final controller = MessagingController(messagingService: _messagingService);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatPage(
            conversation: conversation,
            currentUserId: widget.user.id,
            controller: controller,
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  /// Helper to build a hover-reactive Marker
  Marker _buildPinMarker({
    required LatLng point,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: point,
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: _HoverableMapPin(color: color, onTap: onTap),
    );
  }

  // ===================== Privacy + grouping helpers =====================

  Widget _buildRideSchedule(
    BuildContext context,
    Map<String, dynamic> details, {
    required bool isOffer,
  }) {
    final rideType = details['rideType'];
    final direction = _rideIntentLabel(isOffer, rideType);
    final theme = Theme.of(context);
    final times = [
      if (rideType != 'departing')
        ('Arrive at campus by', _formatRideTime(context, details['arrivalTime'])),
      if (rideType != 'arriving')
        ('Leave campus at', _formatRideTime(context, details['departureTime'])),
    ].where((entry) => entry.$2.trim().isNotEmpty).toList();
    final directionStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    if (times.isEmpty) {
      if (direction.isEmpty) return const SizedBox.shrink();
      return Text(direction, style: directionStyle);
    }
    final entries = [
      for (final (label, time) in times)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label:', style: theme.textTheme.labelLarge),
              Text(
                time,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (direction.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Text(direction, style: directionStyle),
            ),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 340
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final entry in entries) Expanded(child: entry),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries,
                  ),
          ),
        ],
      ),
    );
  }

  String _rideTypeLabel(dynamic rideType) {
    return switch (rideType) {
      'arriving' => 'To campus',
      'departing' => 'From campus',
      'roundTrip' => 'Round trip',
      _ => _formatDetailValue(rideType),
    };
  }

  Widget _buildDayBubbles(
    BuildContext context,
    Set<String> activeDays, {
    double scale = 1,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final size = (compact ? 28.0 : 32.0) * scale;
    final spacing = (compact ? 5.0 : 7.0) * scale;
    final days = [
      ('MONDAY', 'M'),
      ('TUESDAY', 'T'),
      ('WEDNESDAY', 'W'),
      ('THURSDAY', 'T'),
      ('FRIDAY', 'F'),
      if (activeDays.contains('SATURDAY')) ('SATURDAY', 'Sa'),
      if (activeDays.contains('SUNDAY')) ('SUNDAY', 'Su'),
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final (day, letter) in days)
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeDays.contains(day) ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: activeDays.contains(day) ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: math.max(9.0, (compact ? 12.0 : 13.0) * scale),
                fontWeight: FontWeight.w600,
                color: activeDays.contains(day) ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  String _formatRideTime(BuildContext context, Object? value) {
    if (value is! String) return '';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || hour < 0 || hour > 23 ||
        minute == null || minute < 0 || minute > 59) {
      return value;
    }
    return TimeOfDay(hour: hour, minute: minute).format(context);
  }

  /// null/missing -> '', lists -> "MONDAY, FRIDAY", booleans -> Yes/No
  String _formatDetailValue(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.join(', ');
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  MaterialColor _colorFor(MapRideItem item) =>
      item.isOffer ? Colors.orange : Colors.blue;

  String _rideIntentLabel(bool isOffer, dynamic rideType) {
    final action = isOffer ? 'Offering' : 'Seeking';
    final ride = switch (rideType) {
      'arriving' => 'a ride to campus',
      'departing' => 'a ride from campus',
      'roundTrip' => 'a round-trip ride',
      _ => 'a ride',
    };
    return '$action $ride';
  }

  void _openDetails(MapRideItem item) {
    _showRideDetailsModal(
      item.isOffer ? 'Ride offer' : 'Ride request',
      _colorFor(item),
      item.details,
      isOffer: item.isOffer,
    );
  }

  /// Small string hash that gives the same value on every run and platform
  static int _stableHash(String s) {
    int h = 17;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return h;
  }

  /// Where the marker is drawn. In privacy mode it's shifted 100–400 m in a
  /// random direction. The offset is seeded by the ride's ID so it stays the
  /// same between reloads (otherwise averaging reloads would reveal the spot).
  LatLng _displayPointFor(MapRideItem item) {
    if (!kHideExactLocations) return item.point;

    final id =
        (item.details['requestId'] ??
                item.details['offerId'] ??
                '${item.point.latitude},${item.point.longitude}')
            .toString();
    final rng = math.Random(_stableHash('${item.isOffer}:$id'));

    final distance =
        _minJitterMeters +
        rng.nextDouble() * (_maxJitterMeters - _minJitterMeters);
    final angle = rng.nextDouble() * 2 * math.pi;

    const metersPerDegreeLat = 111320.0;
    final dLat = distance * math.cos(angle) / metersPerDegreeLat;
    final dLng =
        distance *
        math.sin(angle) /
        (metersPerDegreeLat * math.cos(item.point.latitude * math.pi / 180));

    return LatLng(item.point.latitude + dLat, item.point.longitude + dLng);
  }

  /// Circle size on screen for the privacy radius at the current zoom
  double _circleDiameterPx(LatLng at) {
    final metersPerPixel =
        156543.03392 *
        math.cos(at.latitude * math.pi / 180) /
        math.pow(2, _currentZoom);
    return (2 * _privacyRadiusMeters / metersPerPixel)
        .clamp(_minCircleDiameterPx, _maxCircleDiameterPx)
        .toDouble();
  }

  /// Web Mercator projection to screen pixels at a given zoom
  static math.Point<double> _project(LatLng p, double zoom) {
    final scale = 256.0 * math.pow(2, zoom);
    final x = (p.longitude + 180.0) / 360.0 * scale;
    final latRad = p.latitude * math.pi / 180.0;
    final y =
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        scale;
    return math.Point(x, y);
  }

  /// Groups markers that would overlap on screen at the current zoom
  List<_RideCluster> _clusterItems() {
    final clusters = <_RideCluster>[];

    for (final item in _rideItems) {
      final point = _displayPointFor(item);
      final px = _project(point, _currentZoom);
      final threshold = kHideExactLocations
          ? math.max(_clusterRadiusPx, _circleDiameterPx(point) * 0.75)
          : _clusterRadiusPx;

      _RideCluster? target;
      for (final c in clusters) {
        if (c.pixelCenter.distanceTo(px) <= threshold) {
          target = c;
          break;
        }
      }

      if (target == null) {
        clusters.add(_RideCluster(item, point, px));
      } else {
        target.add(item, point, px);
      }
    }
    return clusters;
  }

  /// Builds every marker on the map: single pins/circles or grouped ones
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    for (final cluster in _clusterItems()) {
      if (cluster.items.length == 1) {
        final item = cluster.items.first;
        final color = _colorFor(item);
        if (kHideExactLocations) {
          final d = _circleDiameterPx(cluster.center);
          markers.add(
            Marker(
              point: cluster.center,
              width: d,
              height: d,
              alignment: Alignment.center,
              child: _HoverableMapCircle(
                color: color,
                diameter: d,
                onTap: () => _openDetails(item),
              ),
            ),
          );
        } else {
          markers.add(
            _buildPinMarker(
              point: cluster.center,
              color: color,
              onTap: () => _openDetails(item),
            ),
          );
        }
      } else {
        markers.add(_buildClusterMarker(cluster));
      }
    }
    return markers;
  }

  Marker _buildClusterMarker(_RideCluster cluster) {
    // Orange = all offers, blue = all requests, purple = a mix
    final MaterialColor color = cluster.allOffers
        ? Colors.orange
        : cluster.allRequests
        ? Colors.blue
        : Colors.purple;

    final double bodySize = kHideExactLocations
        ? math.max(_circleDiameterPx(cluster.center), 40)
        : 56;
    const double badgeSpace = _ClusterMarker.badgeHeight + 2;

    return Marker(
      point: cluster.center,
      width: math.max(bodySize, 60),
      // Room for the count badge above, mirrored below so the body stays centered
      height: bodySize + badgeSpace * 2,
      alignment: Alignment.center,
      child: _ClusterMarker(
        color: color,
        count: cluster.items.length,
        isCircle: kHideExactLocations,
        bodySize: bodySize,
        onTap: () => _showClusterPicker(cluster),
      ),
    );
  }

  /// Menu listing every ride inside a grouped marker
  void _showClusterPicker(_RideCluster cluster) {
    final requests = cluster.items.where((item) => !item.isOffer).toList();
    final offers = cluster.items.where((item) => item.isOffer).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.layers),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rides in this area',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${offers.length} offer${offers.length == 1 ? '' : 's'} · '
                    '${requests.length} request${requests.length == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    children: [
                      for (final (label, subtitle, items) in [
                        (
                          'Ride requests',
                          'Riders in this section are seeking rides.',
                          requests,
                        ),
                        (
                          'Ride offers',
                          'Riders in this section are offering rides.',
                          offers,
                        ),
                      ])
                        if (items.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$label (${items.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          for (final item in items) ...[
                            _clusterRideRow(sheetContext, item),
                            const Divider(height: 1),
                          ],
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _clusterRideRow(BuildContext sheetContext, MapRideItem item) {
    final details = item.details;
    final rideType = details['rideType'];
    final city = _formatDetailValue(details['city']).trim();
    final arrival = _formatRideTime(sheetContext, details['arrivalTime']).trim();
    final departure = _formatRideTime(sheetContext, details['departureTime']).trim();
    final times = [
      if (rideType != 'departing' && arrival.isNotEmpty) 'Arrive by $arrival',
      if (rideType != 'arriving' && departure.isNotEmpty) 'Leave at $departure',
    ];
    final direction = _rideTypeLabel(rideType);
    final savedDays = details['daysOfWeek'];
    final days = savedDays is List
        ? savedDays.whereType<String>().toSet()
        : <String>{};
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 540;
        final bubbles = days.isEmpty
            ? null
            : _buildDayBubbles(context, days, scale: 0.8);
        final textTheme = Theme.of(context).textTheme;
        return Semantics(
          button: true,
          child: InkWell(
            onTap: () {
              Navigator.pop(sheetContext);
              _openDetails(item);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.location_pin, color: _colorFor(item)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.isEmpty ? 'Location unavailable' : city,
                          style: textTheme.bodyLarge,
                        ),
                        if (direction.isNotEmpty)
                          Text(direction, style: textTheme.bodyMedium),
                        if (!wide && bubbles != null) ...[
                          const SizedBox(height: 6),
                          bubbles,
                        ],
                      ],
                    ),
                  ),
                  if (wide && bubbles != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: bubbles,
                      ),
                    ),
                  ],
                  if (times.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.min(176, constraints.maxWidth * 0.42),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final time in times)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(time),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (TickerMode.of(context) &&
        ModalRoute.isCurrentOf(context) != false &&
        _hasLoadError &&
        !_errorDialogOpen) {
      _scheduleErrorDialog();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildFilterBar(),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3.0),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.0),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: _mapCenter,
                            initialZoom: 9.0,
                            minZoom: 5.0,
                            // Privacy mode caps zoom so circles stay a sensible size
                            maxZoom: kHideExactLocations ? 14.0 : 18.0,
                            // Re-group markers whenever the zoom changes
                            // The map can report position changes while it is
                            // still laying out (e.g. when the camera constraint
                            // corrects the zoom), so defer setState to after
                            // the current frame instead of calling it mid-build.
                            onPositionChanged: (camera, hasGesture) {
                              final newZoom = camera.zoom;
                              if ((newZoom - _currentZoom).abs() <= 0.05) {
                                return;
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                if ((newZoom - _currentZoom).abs() > 0.05) {
                                  setState(() => _currentZoom = newZoom);
                                }
                              });
                            },
                            // containCenter keeps the view centered inside
                            // Manitoba at any zoom. contain() can't be satisfied
                            // once the view is wider than Manitoba itself.
                            cameraConstraint: CameraConstraint.containCenter(
                              bounds: _manitobaBounds,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'net.popicraft.gobison',
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SimpleAttributionWidget(
                                  source: const Text('OpenStreetMap contributors'),
                                  onTap: () => launchUrl(
                                    Uri.parse('https://openstreetmap.org/copyright'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator()),
                        if (!_isLoading &&
                            _rideItems.isEmpty &&
                            !_hasLoadError)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No rides match the selected filters.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive map pin that enlarges and boldens when hovered
class _HoverableMapPin extends StatefulWidget {
  final MaterialColor color;
  final VoidCallback onTap;

  const _HoverableMapPin({required this.color, required this.onTap});

  @override
  State<_HoverableMapPin> createState() => _HoverableMapPinState();
}

class _HoverableMapPinState extends State<_HoverableMapPin> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.25 : 1.0,
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isHovered ? Colors.white : Colors.transparent,
              border: _isHovered
                  ? Border.all(color: widget.color.shade800, width: 2.5)
                  : null,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.location_pin,
              color: _isHovered ? widget.color.shade800 : widget.color,
              size: 38,
              shadows: _isHovered
                  ? [
                      Shadow(
                        color: widget.color.shade900.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// A group of rides that are too close together to show separately
class _RideCluster {
  _RideCluster(MapRideItem item, LatLng point, math.Point<double> px) {
    add(item, point, px);
  }

  final List<MapRideItem> items = [];
  double _latSum = 0, _lngSum = 0, _xSum = 0, _ySum = 0;

  void add(MapRideItem item, LatLng point, math.Point<double> px) {
    items.add(item);
    _latSum += point.latitude;
    _lngSum += point.longitude;
    _xSum += px.x;
    _ySum += px.y;
  }

  /// Average of the members' displayed positions
  LatLng get center => LatLng(_latSum / items.length, _lngSum / items.length);
  math.Point<double> get pixelCenter =>
      math.Point(_xSum / items.length, _ySum / items.length);

  bool get allOffers => items.every((i) => i.isOffer);
  bool get allRequests => items.every((i) => !i.isOffer);
}

/// Privacy-mode marker: a translucent circle instead of a pin
class _HoverableMapCircle extends StatefulWidget {
  const _HoverableMapCircle({
    required this.color,
    required this.diameter,
    required this.onTap,
  });

  final MaterialColor color;
  final double diameter;
  final VoidCallback onTap;

  @override
  State<_HoverableMapCircle> createState() => _HoverableMapCircleState();
}

class _HoverableMapCircleState extends State<_HoverableMapCircle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: widget.diameter,
            height: widget.diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: _isHovered ? 0.45 : 0.3),
              border: Border.all(
                color: widget.color.shade700,
                width: _isHovered ? 3 : 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grouped ("super") marker: stacked pin or double-ring circle with a count
class _ClusterMarker extends StatefulWidget {
  const _ClusterMarker({
    required this.color,
    required this.count,
    required this.isCircle,
    required this.bodySize,
    required this.onTap,
  });

  static const double badgeHeight = 22;

  final MaterialColor color;
  final int count;
  final bool isCircle;
  final double bodySize;
  final VoidCallback onTap;

  @override
  State<_ClusterMarker> createState() => _ClusterMarkerState();
}

class _ClusterMarkerState extends State<_ClusterMarker> {
  bool _isHovered = false;

  Widget _buildCircleBody() {
    // Double ring: dark outer ring, white gap, filled inner circle
    return Container(
      width: widget.bodySize,
      height: widget.bodySize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.color.shade800, width: 3),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _isHovered ? 0.6 : 0.45),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildPinBody() {
    // Two overlapping pins so it reads as "several rides"
    return SizedBox(
      width: widget.bodySize,
      height: widget.bodySize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(7, -4),
            child: Icon(
              Icons.location_pin,
              size: 40,
              color: widget.color.shade200,
            ),
          ),
          Icon(
            Icons.location_pin,
            size: 46,
            color: widget.color.shade800,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fill the whole marker so the badge sits above the body
              const SizedBox.expand(),
              widget.isCircle ? _buildCircleBody() : _buildPinBody(),
              // Count badge above the body
              Positioned(
                top: 0,
                child: Container(
                  height: _ClusterMarker.badgeHeight,
                  constraints: const BoxConstraints(
                    minWidth: _ClusterMarker.badgeHeight,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
