import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../app/theme.dart';

/// Active ride screen with real-time tracking.
/// This is the core fix: replaces web app's hardcoded mock coordinates
/// with actual Supabase Realtime channel subscriptions.
class TaxiActiveRideScreen extends ConsumerStatefulWidget {
  final String rideId;
  const TaxiActiveRideScreen({super.key, required this.rideId});

  @override
  ConsumerState<TaxiActiveRideScreen> createState() =>
      _TaxiActiveRideScreenState();
}

class _TaxiActiveRideScreenState extends ConsumerState<TaxiActiveRideScreen> {
  TaxiRide? _ride;
  TaxiProviderLocation? _driverLocation;
  StreamSubscription<TaxiRide>? _rideSub;
  StreamSubscription<TaxiProviderLocation>? _locationSub;
  final _chatController = TextEditingController();
  final List<TaxiChatMessage> _chatMessages = [];
  bool _showChat = false;

  @override
  void initState() {
    super.initState();
    _loadRide();
    _subscribeToUpdates();
  }

  Future<void> _loadRide() async {
    final data = await PearlHubSupabase.client
        .from('taxi_rides')
        .select()
        .eq('id', widget.rideId)
        .single();
    if (mounted) {
      setState(() => _ride = TaxiRide.fromJson(data));
      if (_ride?.providerId != null) {
        _subscribeToDriverLocation(_ride!.providerId!);
      }
    }
  }

  void _subscribeToUpdates() {
    final realtimeService = ref.read(taxiRealtimeServiceProvider);
    _rideSub = realtimeService.subscribeToRide(widget.rideId).listen((ride) {
      setState(() => _ride = ride);
      // Start tracking driver location once ride is accepted
      if (ride.providerId != null && _locationSub == null) {
        _subscribeToDriverLocation(ride.providerId!);
      }
    });
  }

  void _subscribeToDriverLocation(String providerId) {
    final realtimeService = ref.read(taxiRealtimeServiceProvider);
    _locationSub = realtimeService
        .subscribeToDriverLocation(providerId)
        .listen((location) {
      setState(() => _driverLocation = location);
    });
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    _locationSub?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _chatController.text.trim();
    if (content.isEmpty || _ride == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _chatController.clear();

    await PearlHubSupabase.client.from('taxi_chat_messages').insert({
      'ride_id': widget.rideId,
      'sender_id': user.id,
      'content': content,
    });
  }

  Future<void> _triggerSOS() async {
    await PearlHubSupabase.client
        .from('taxi_rides')
        .update({'is_emergency_sos': true}).eq('id', widget.rideId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS triggered! Emergency services notified.'),
          backgroundColor: PearlHubColors.error,
        ),
      );
    }
  }

  Color _statusColor(TaxiRideStatus status) {
    switch (status) {
      case TaxiRideStatus.searching:
        return PearlHubColors.warning;
      case TaxiRideStatus.accepted:
        return PearlHubColors.info;
      case TaxiRideStatus.arrived:
        return PearlHubColors.primary;
      case TaxiRideStatus.inTransit:
        return PearlHubColors.success;
      case TaxiRideStatus.completed:
        return PearlHubColors.success;
      case TaxiRideStatus.cancelled:
        return PearlHubColors.error;
    }
  }

  String _statusLabel(TaxiRideStatus status) {
    switch (status) {
      case TaxiRideStatus.searching:
        return 'Finding your driver...';
      case TaxiRideStatus.accepted:
        return 'Driver accepted! On the way.';
      case TaxiRideStatus.arrived:
        return 'Driver has arrived!';
      case TaxiRideStatus.inTransit:
        return 'On the way to destination';
      case TaxiRideStatus.completed:
        return 'Ride completed!';
      case TaxiRideStatus.cancelled:
        return 'Ride cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ride == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ride = _ride!;
    final isActive = ride.status != TaxiRideStatus.completed &&
        ride.status != TaxiRideStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/taxi'),
        ),
        actions: [
          if (isActive)
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () => setState(() => _showChat = !_showChat),
            ),
          if (isActive)
            IconButton(
              icon: const Icon(Icons.emergency, color: Colors.red),
              onPressed: () => _showSOSDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Map with real-time driver location
          Expanded(
            flex: 3,
            child: PearlHubMap(
              initialLat: ride.pickupLat,
              initialLng: ride.pickupLng,
              initialZoom: 14,
              markers: [
                PearlMapMarker(
                  id: 'pickup',
                  lat: ride.pickupLat,
                  lng: ride.pickupLng,
                  title: 'Pickup',
                ),
                PearlMapMarker(
                  id: 'dropoff',
                  lat: ride.dropoffLat,
                  lng: ride.dropoffLng,
                  title: 'Drop-off',
                ),
                if (_driverLocation != null)
                  PearlMapMarker(
                    id: 'driver',
                    lat: _driverLocation!.lat,
                    lng: _driverLocation!.lng,
                    title: 'Driver',
                  ),
              ],
            ),
          ),

          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _statusColor(ride.status),
            child: Row(
              children: [
                if (ride.status == TaxiRideStatus.searching)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                if (ride.status == TaxiRideStatus.searching)
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusLabel(ride.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status progression
          Padding(
            padding: const EdgeInsets.all(16),
            child: _StatusProgressBar(status: ride.status),
          ),

          // Ride details
          Expanded(
            flex: 2,
            child: _showChat ? _buildChat() : _buildRideDetails(ride),
          ),
        ],
      ),

      // Rating button when completed
      bottomNavigationBar: ride.status == TaxiRideStatus.completed
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(),
                  icon: const Icon(Icons.star),
                  label: const Text('Rate your ride'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildRideDetails(TaxiRide ride) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup & Dropoff
          Row(
            children: [
              const Icon(Icons.my_location, color: PearlHubColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.pickupAddress ?? 'Pickup location',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: PearlHubColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.dropoffAddress ?? 'Drop-off location',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Fare & Payment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fare', style: TextStyle(color: PearlHubColors.textSecondary)),
                  Text(
                    ride.fare != null
                        ? 'LKR ${ride.fare!.toStringAsFixed(0)}'
                        : 'Calculating...',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Payment', style: TextStyle(color: PearlHubColors.textSecondary)),
                  Text(
                    ride.paymentMethod.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isMe = msg.senderId == ref.read(currentUserProvider)?.id;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? PearlHubColors.primary
                        : PearlHubColors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Message driver...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: PearlHubColors.primary),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'This will alert emergency services and PearlHub support. '
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _triggerSOS();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Trigger SOS'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    double rating = 5;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate Your Ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () =>
                        setDialogState(() => rating = i + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user != null && _ride != null) {
                  await PearlHubSupabase.client
                      .from('taxi_ratings')
                      .insert({
                    'ride_id': widget.rideId,
                    'reviewer_id': user.id,
                    'target_id': _ride!.providerId,
                    'rating': rating,
                    'feedback': feedbackController.text,
                    'tip_amount': 0,
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) context.go('/taxi');
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATUS PROGRESS BAR
// Visual progression: searching → accepted → arrived → in_transit → completed
// ─────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  final TaxiRideStatus status;
  const _StatusProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      TaxiRideStatus.searching,
      TaxiRideStatus.accepted,
      TaxiRideStatus.arrived,
      TaxiRideStatus.inTransit,
      TaxiRideStatus.completed,
    ];

    final currentIndex = steps.indexOf(status);
    final labels = ['Searching', 'Accepted', 'Arrived', 'In Transit', 'Done'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              color: stepIndex < currentIndex
                  ? PearlHubColors.success
                  : PearlHubColors.border,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isActive = stepIndex <= currentIndex;
        final isCurrent = stepIndex == currentIndex;

        return Column(
          children: [
            Container(
              width: isCurrent ? 20 : 14,
              height: isCurrent ? 20 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? PearlHubColors.success : PearlHubColors.border,
                border: isCurrent
                    ? Border.all(color: PearlHubColors.success, width: 3)
                    : null,
              ),
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              labels[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? PearlHubColors.textPrimary
                    : PearlHubColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}
