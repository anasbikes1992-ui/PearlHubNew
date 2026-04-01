import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// Driver home screen — online/offline toggle + incoming ride requests.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isOnline = false;
  TaxiRide? _currentRide;
  StreamSubscription<TaxiRide>? _rideSub;

  Future<void> _toggleOnline() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newStatus = !_isOnline;
    setState(() => _isOnline = newStatus);

    // Upsert driver location with online status
    await PearlHubSupabase.client.from('taxi_provider_locations').upsert({
      'provider_id': user.id,
      'is_online': newStatus,
      'lat': 6.9271, // TODO: Get real GPS location
      'lng': 79.8612,
    });

    if (newStatus) {
      _listenForRides(user.id);
    }
  }

  void _listenForRides(String providerId) {
    // Listen for rides assigned to this provider via Realtime
    PearlHubSupabase.client
        .channel('driver-rides-$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'taxi_rides',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) {
              setState(() => _currentRide = TaxiRide.fromJson(data));
            }
          },
        )
        .subscribe();
  }

  Future<void> _acceptRide(String rideId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await PearlHubSupabase.client.from('taxi_rides').update({
      'provider_id': user.id,
      'status': 'accepted',
    }).eq('id', rideId);
  }

  Future<void> _updateRideStatus(String rideId, String status) async {
    await PearlHubSupabase.client
        .from('taxi_rides')
        .update({'status': status}).eq('id', rideId);

    if (status == 'completed') {
      setState(() => _currentRide = null);
    }
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final providerRides = user != null
        ? ref.watch(taxiProviderRidesProvider(user.id))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Mode'),
        actions: [
          // Online/Offline toggle
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline ? Colors.greenAccent : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isOnline,
                  onChanged: (_) => _toggleOnline(),
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map showing driver's area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                PearlHubMap(
                  initialLat: 6.9271,
                  initialLng: 79.8612,
                  initialZoom: 13,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: [
                    if (_currentRide != null) ...[
                      PearlMapMarker(
                        id: 'pickup',
                        lat: _currentRide!.pickupLat,
                        lng: _currentRide!.pickupLng,
                        title: 'Pickup',
                      ),
                      PearlMapMarker(
                        id: 'dropoff',
                        lat: _currentRide!.dropoffLat,
                        lng: _currentRide!.dropoffLng,
                        title: 'Drop-off',
                      ),
                    ],
                  ],
                ),
                // Status indicator
                if (!_isOnline)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, size: 48, color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'You are offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Go online to receive ride requests',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Current ride or recent rides
          Expanded(
            flex: 2,
            child: _currentRide != null
                ? _ActiveRidePanel(
                    ride: _currentRide!,
                    onAccept: () => _acceptRide(_currentRide!.id),
                    onArrive: () =>
                        _updateRideStatus(_currentRide!.id, 'arrived'),
                    onStart: () =>
                        _updateRideStatus(_currentRide!.id, 'in_transit'),
                    onComplete: () =>
                        _updateRideStatus(_currentRide!.id, 'completed'),
                  )
                : _RecentRides(rides: providerRides),
          ),
        ],
      ),
    );
  }
}

class _ActiveRidePanel extends StatelessWidget {
  final TaxiRide ride;
  final VoidCallback onAccept;
  final VoidCallback onArrive;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _ActiveRidePanel({
    required this.ride,
    required this.onAccept,
    required this.onArrive,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.pickupAddress ?? 'Pickup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.dropoffAddress ?? 'Drop-off',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (ride.fare != null)
            Text(
              'Fare: LKR ${ride.fare!.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (ride.status) {
      case TaxiRideStatus.searching:
        return ElevatedButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check),
          label: const Text('Accept Ride'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        );
      case TaxiRideStatus.accepted:
        return ElevatedButton.icon(
          onPressed: onArrive,
          icon: const Icon(Icons.place),
          label: const Text('I Have Arrived'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        );
      case TaxiRideStatus.arrived:
        return ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Trip'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        );
      case TaxiRideStatus.inTransit:
        return ElevatedButton.icon(
          onPressed: onComplete,
          icon: const Icon(Icons.flag),
          label: const Text('Complete Ride'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

class _RecentRides extends StatelessWidget {
  final AsyncValue<List<TaxiRide>>? rides;
  const _RecentRides({this.rides});

  @override
  Widget build(BuildContext context) {
    if (rides == null) {
      return const Center(child: Text('Sign in to see your rides'));
    }

    return rides!.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('No rides yet. Go online to receive requests!'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length > 5 ? 5 : list.length,
          itemBuilder: (context, index) {
            final ride = list[index];
            return ListTile(
              leading: Icon(
                ride.status == TaxiRideStatus.completed
                    ? Icons.check_circle
                    : Icons.local_taxi,
                color: ride.status == TaxiRideStatus.completed
                    ? Colors.green
                    : Colors.orange,
              ),
              title: Text(ride.dropoffAddress ?? 'Ride ${ride.id.substring(0, 8)}'),
              subtitle: Text(ride.status.name),
              trailing: ride.fare != null
                  ? Text(
                      'LKR ${ride.fare!.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
