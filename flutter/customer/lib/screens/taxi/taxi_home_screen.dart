import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../app/theme.dart';

/// Customer taxi booking screen.
/// Shows map, pickup/dropoff inputs, vehicle category selector,
/// fare estimate, promo code, and ride/parcel toggle.
class TaxiHomeScreen extends ConsumerStatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  ConsumerState<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends ConsumerState<TaxiHomeScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _promoController = TextEditingController();

  String _rideModule = 'ride'; // 'ride' or 'parcel'
  TaxiVehicleCategory? _selectedCategory;
  double? _pickupLat, _pickupLng;
  double? _dropoffLat, _dropoffLng;
  double? _estimatedFare;
  bool _isBooking = false;
  PromoValidationResult? _promoResult;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _onMapTap(double lat, double lng) {
    setState(() {
      if (_pickupLat == null) {
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupController.text = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      } else {
        _dropoffLat = lat;
        _dropoffLng = lng;
        _dropoffController.text = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        _calculateFare();
      }
    });
  }

  void _calculateFare() {
    if (_selectedCategory == null ||
        _pickupLat == null ||
        _dropoffLat == null) return;

    // Rough distance calculation (Haversine would be better)
    final distKm = _estimateDistance(
      _pickupLat!,
      _pickupLng!,
      _dropoffLat!,
      _dropoffLng!,
    );

    setState(() {
      _estimatedFare = calculateFare(
        baseFare: _selectedCategory!.baseFare,
        perKmRate: _selectedCategory!.perKmRate,
        distanceKm: distKm,
        discountType: _promoResult?.discountType,
        discountAmount: _promoResult?.discountAmount,
      );
    });
  }

  double _estimateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    // Simple Euclidean approximation in km (good enough for Sri Lanka)
    const kmPerDegree = 111.0;
    final dLat = (lat2 - lat1) * kmPerDegree;
    final dLng = (lng2 - lng1) * kmPerDegree * 0.9;
    return (dLat * dLat + dLng * dLng).abs();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final result = await validateTaxiPromo(code);
    setState(() => _promoResult = result);
    _calculateFare();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.valid ? 'Promo applied!' : (result.error ?? 'Invalid'),
          ),
          backgroundColor:
              result.valid ? PearlHubColors.success : PearlHubColors.error,
        ),
      );
    }
  }

  Future<void> _bookRide() async {
    final user = ref.read(currentUserProvider);
    if (user == null ||
        _pickupLat == null ||
        _dropoffLat == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set pickup, dropoff, and vehicle type'),
          backgroundColor: PearlHubColors.warning,
        ),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final ride = await bookTaxiRide(
        customerId: user.id,
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        pickupAddress: _pickupController.text,
        dropoffLat: _dropoffLat!,
        dropoffLng: _dropoffLng!,
        dropoffAddress: _dropoffController.text,
        vehicleCategoryId: _selectedCategory!.id,
        rideModule: _rideModule,
        promoId: _promoResult?.id,
      );

      if (mounted) {
        context.go('/taxi/ride/${ride.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: PearlHubColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(taxiCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PearlHub Taxi')),
      body: Column(
        children: [
          // Map area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                PearlHubMap(
                  initialLat: 6.9271,
                  initialLng: 79.8612,
                  initialZoom: 12,
                  onTap: _onMapTap,
                  myLocationEnabled: true,
                  markers: [
                    if (_pickupLat != null)
                      PearlMapMarker(
                        id: 'pickup',
                        lat: _pickupLat!,
                        lng: _pickupLng!,
                        title: 'Pickup',
                      ),
                    if (_dropoffLat != null)
                      PearlMapMarker(
                        id: 'dropoff',
                        lat: _dropoffLat!,
                        lng: _dropoffLng!,
                        title: 'Drop-off',
                      ),
                  ],
                ),
                // Ride/Parcel toggle
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _ModeChip(
                          label: 'Ride',
                          icon: Icons.person,
                          selected: _rideModule == 'ride',
                          onTap: () =>
                              setState(() => _rideModule = 'ride'),
                        ),
                        _ModeChip(
                          label: 'Parcel',
                          icon: Icons.inventory_2,
                          selected: _rideModule == 'parcel',
                          onTap: () =>
                              setState(() => _rideModule = 'parcel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Booking panel
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pickup
                  TextField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup location',
                      prefixIcon: Icon(Icons.my_location,
                          color: PearlHubColors.success),
                      hintText: 'Tap on map or enter address',
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),

                  // Dropoff
                  TextField(
                    controller: _dropoffController,
                    decoration: const InputDecoration(
                      labelText: 'Drop-off location',
                      prefixIcon: Icon(Icons.location_on,
                          color: PearlHubColors.error),
                      hintText: 'Tap on map or enter address',
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Vehicle categories
                  Text('Vehicle Type',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  categories.when(
                    data: (cats) => SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = cats[index];
                          final selected =
                              _selectedCategory?.id == cat.id;
                          return GestureDetector(
                            onTap: () {
                              setState(
                                  () => _selectedCategory = cat);
                              _calculateFare();
                            },
                            child: Container(
                              width: 90,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? PearlHubColors.primary
                                        .withOpacity(0.1)
                                    : Colors.white,
                                border: Border.all(
                                  color: selected
                                      ? PearlHubColors.primary
                                      : PearlHubColors.border,
                                  width: selected ? 2 : 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(cat.icon,
                                      style: const TextStyle(
                                          fontSize: 24)),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 12),

                  // Promo code
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          decoration: const InputDecoration(
                            labelText: 'Promo code',
                            prefixIcon: Icon(Icons.local_offer),
                            isDense: true,
                          ),
                          textCapitalization:
                              TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _applyPromo,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fare estimate
                  if (_estimatedFare != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PearlHubColors.taxiAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Fare',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'LKR ${_estimatedFare!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: PearlHubColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Book button
                  ElevatedButton.icon(
                    onPressed: _isBooking ? null : _bookRide,
                    icon: _isBooking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.local_taxi),
                    label: Text(
                      _rideModule == 'parcel'
                          ? 'Send Parcel'
                          : 'Book Ride',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PearlHubColors.taxiAccent,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PearlHubColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : PearlHubColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : PearlHubColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
