import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PickupMapButton extends StatelessWidget {
  const PickupMapButton({
    super.key,
    required this.point,
    required this.onChanged,
    this.savedPoint,
  });

  final LatLng? point;
  final LatLng? savedPoint;
  final ValueChanged<LatLng?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.map_outlined),
          label: Text(point == null ? 'Pick on map' : 'Move pickup pin'),
          onPressed: change == null
              ? null
              : () async {
                  final result = await showDialog<LatLng>(
                    context: context,
                    builder: (_) => PickupMapDialog(initialPoint: point ?? savedPoint),
                  );
                  if (context.mounted && result != null) change(result);
                },
        ),
        if (point != null)
          TextButton(
            onPressed: change == null ? null : () => change(null),
            child: const Text('Use street address'),
          ),
      ],
    );
  }
}

class PickupMapDialog extends StatefulWidget {
  const PickupMapDialog({super.key, this.initialPoint});

  final LatLng? initialPoint;

  @override
  State<PickupMapDialog> createState() => _PickupMapDialogState();
}

class _PickupMapDialogState extends State<PickupMapDialog> {
  late LatLng? _point = widget.initialPoint;

  @override
  Widget build(BuildContext context) {
    final point = _point;
    return AlertDialog(
      title: const Text('Pick a pickup location'),
      content: SizedBox(
        width: 560,
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tap the map to place or move the pickup pin.'),
            const SizedBox(height: 12),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: widget.initialPoint ?? const LatLng(49.8951, -97.1384),
                  initialZoom: widget.initialPoint == null ? 11 : 16,
                  onTap: (_, location) => setState(() => _point = location),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'net.popicraft.gobison',
                  ),
                  if (point != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_on,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
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
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: point == null ? null : () => Navigator.pop(context, point),
          child: const Text('Use this location'),
        ),
      ],
    );
  }
}
