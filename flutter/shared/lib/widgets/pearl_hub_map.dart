import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;

import '../services/supabase_client.dart';

// ─────────────────────────────────────────────
// MAP PROVIDER TYPE
// Admin can switch between Google Maps and OpenStreetMap
// via the platform_settings table.
// ─────────────────────────────────────────────

enum MapProviderType { googleMaps, openStreetMap }

/// Reads the map_provider setting from platform_settings table.
/// Defaults to OpenStreetMap if no setting found.
final mapProviderSettingProvider =
    FutureProvider<MapProviderType>((ref) async {
  try {
    final data = await PearlHubSupabase.client
        .from('platform_settings')
        .select('value')
        .eq('key', 'map_provider')
        .maybeSingle();

    if (data != null && data['value'] == 'google_maps') {
      return MapProviderType.googleMaps;
    }
  } catch (_) {
    // Table may not exist yet — default to OSM
  }
  return MapProviderType.openStreetMap;
});

// ─────────────────────────────────────────────
// UNIFIED MAP MARKER
// ─────────────────────────────────────────────

class PearlMapMarker {
  final double lat;
  final double lng;
  final String id;
  final String? title;
  final String? snippet;
  final VoidCallback? onTap;

  const PearlMapMarker({
    required this.lat,
    required this.lng,
    required this.id,
    this.title,
    this.snippet,
    this.onTap,
  });
}

// ─────────────────────────────────────────────
// UNIFIED MAP POLYLINE
// ─────────────────────────────────────────────

class PearlMapPolyline {
  final List<({double lat, double lng})> points;
  final Color color;
  final double width;

  const PearlMapPolyline({
    required this.points,
    this.color = Colors.blue,
    this.width = 4.0,
  });
}

// ─────────────────────────────────────────────
// PEARL HUB MAP WIDGET
// Renders Google Maps or OSM based on admin setting.
// Both share the same marker/polyline API.
// ─────────────────────────────────────────────

class PearlHubMap extends ConsumerWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final List<PearlMapMarker> markers;
  final List<PearlMapPolyline> polylines;
  final void Function(double lat, double lng)? onTap;
  final void Function(double lat, double lng)? onLongPress;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;

  const PearlHubMap({
    super.key,
    this.initialLat = 7.8731,
    this.initialLng = 80.7718,
    this.initialZoom = 8.0,
    this.markers = const [],
    this.polylines = const [],
    this.onTap,
    this.onLongPress,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapProvider = ref.watch(mapProviderSettingProvider);

    return mapProvider.when(
      data: (type) {
        switch (type) {
          case MapProviderType.googleMaps:
            return _buildGoogleMap();
          case MapProviderType.openStreetMap:
            return _buildOsmMap();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildOsmMap(), // Fallback to OSM on error
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(initialLat, initialLng),
        zoom: initialZoom,
      ),
      markers: markers.map((m) {
        return gmaps.Marker(
          markerId: gmaps.MarkerId(m.id),
          position: gmaps.LatLng(m.lat, m.lng),
          infoWindow: gmaps.InfoWindow(
            title: m.title ?? '',
            snippet: m.snippet ?? '',
          ),
          onTap: m.onTap,
        );
      }).toSet(),
      polylines: polylines.map((p) {
        return gmaps.Polyline(
          polylineId: gmaps.PolylineId('polyline_${polylines.indexOf(p)}'),
          points:
              p.points.map((pt) => gmaps.LatLng(pt.lat, pt.lng)).toList(),
          color: p.color,
          width: p.width.toInt(),
        );
      }).toSet(),
      onTap: onTap != null
          ? (latLng) => onTap!(latLng.latitude, latLng.longitude)
          : null,
      onLongPress: onLongPress != null
          ? (latLng) => onLongPress!(latLng.latitude, latLng.longitude)
          : null,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
    );
  }

  Widget _buildOsmMap() {
    return fmap.FlutterMap(
      options: fmap.MapOptions(
        initialCenter: ll.LatLng(initialLat, initialLng),
        initialZoom: initialZoom,
        onTap: onTap != null
            ? (_, latLng) => onTap!(latLng.latitude, latLng.longitude)
            : null,
        onLongPress: onLongPress != null
            ? (_, latLng) => onLongPress!(latLng.latitude, latLng.longitude)
            : null,
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pearlhub.app',
        ),
        if (markers.isNotEmpty)
          fmap.MarkerLayer(
            markers: markers.map((m) {
              return fmap.Marker(
                point: ll.LatLng(m.lat, m.lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: m.onTap,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        if (polylines.isNotEmpty)
          fmap.PolylineLayer(
            polylines: polylines.map((p) {
              return fmap.Polyline(
                points: p.points
                    .map((pt) => ll.LatLng(pt.lat, pt.lng))
                    .toList(),
                color: p.color,
                strokeWidth: p.width,
              );
            }).toList(),
          ),
      ],
    );
  }
}
