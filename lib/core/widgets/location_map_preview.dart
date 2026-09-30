import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../constants/app_colors.dart';

/// An embedded, pannable/zoomable map (OpenStreetMap tiles — no API key
/// required) with a pin dropped at the given coordinates.
class LocationMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;
  final double initialZoom;

  const LocationMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 180,
    this.initialZoom = 6.5,
  });

  @override
  Widget build(BuildContext context) {
    final point = latlong.LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.travel_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
