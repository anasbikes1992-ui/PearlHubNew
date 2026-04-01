import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/listings_service.dart';
import 'package:shared/models/listings.dart';

import '../../app/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PearlHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Text(
                  profile.valueOrNull?.fullName ?? 'Profile',
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Sign Out'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(staysProvider(null));
          ref.invalidate(vehiclesProvider(null));
          ref.invalidate(eventsProvider(null));
          ref.invalidate(propertiesProvider(null));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome banner
            _WelcomeBanner(
              name: profile.valueOrNull?.fullName,
            ),
            const SizedBox(height: 24),

            // Quick access verticals
            const _VerticalQuickAccess(),
            const SizedBox(height: 24),

            // Stays section
            _ListingSection<Stay>(
              title: 'Featured Stays',
              icon: Icons.hotel,
              accentColor: PearlHubColors.stayAccent,
              provider: staysProvider(null),
              itemBuilder: (stay) => _StayCard(stay: stay),
            ),
            const SizedBox(height: 24),

            // Vehicles section
            _ListingSection<Vehicle>(
              title: 'Rental Vehicles',
              icon: Icons.directions_car,
              accentColor: PearlHubColors.vehicleAccent,
              provider: vehiclesProvider(null),
              itemBuilder: (vehicle) => _VehicleCard(vehicle: vehicle),
            ),
            const SizedBox(height: 24),

            // Events section
            _ListingSection<PearlEvent>(
              title: 'Upcoming Events',
              icon: Icons.event,
              accentColor: PearlHubColors.eventAccent,
              provider: eventsProvider(null),
              itemBuilder: (event) => _EventCard(event: event),
            ),
            const SizedBox(height: 24),

            // Properties section
            _ListingSection<Property>(
              title: 'Properties',
              icon: Icons.home_work,
              accentColor: PearlHubColors.propertyAccent,
              provider: propertiesProvider(null),
              itemBuilder: (property) => _PropertyCard(property: property),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WELCOME BANNER
// ─────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String? name;
  const _WelcomeBanner({this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PearlHubColors.primary, PearlHubColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name != null ? 'Welcome, $name!' : 'Welcome to PearlHub!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover stays, vehicles, events & more across Sri Lanka',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VERTICAL QUICK ACCESS
// ─────────────────────────────────────────────

class _VerticalQuickAccess extends StatelessWidget {
  const _VerticalQuickAccess();

  @override
  Widget build(BuildContext context) {
    final verticals = [
      _VerticalItem('Stays', Icons.hotel, PearlHubColors.stayAccent),
      _VerticalItem('Vehicles', Icons.directions_car, PearlHubColors.vehicleAccent),
      _VerticalItem('Events', Icons.event, PearlHubColors.eventAccent),
      _VerticalItem('Properties', Icons.home_work, PearlHubColors.propertyAccent),
      _VerticalItem('Taxi', Icons.local_taxi, PearlHubColors.taxiAccent),
      _VerticalItem('SME', Icons.store, PearlHubColors.smeAccent),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: verticals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final v = verticals[index];
          return GestureDetector(
            onTap: () {
              // TODO: Navigate to vertical
            },
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: v.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(v.icon, color: v.color, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    v.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerticalItem {
  final String label;
  final IconData icon;
  final Color color;
  _VerticalItem(this.label, this.icon, this.color);
}

// ─────────────────────────────────────────────
// GENERIC LISTING SECTION
// ─────────────────────────────────────────────

class _ListingSection<T> extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final FutureProvider<List<T>> provider;
  final Widget Function(T item) itemBuilder;

  const _ListingSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.provider,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full list
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        listings.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No listings yet'),
                ),
              );
            }
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length > 10 ? 10 : items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => itemBuilder(items[index]),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading: $e',
                style: const TextStyle(color: PearlHubColors.error)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// LISTING CARDS
// ─────────────────────────────────────────────

class _StayCard extends StatelessWidget {
  final Stay stay;
  const _StayCard({required this.stay});

  @override
  Widget build(BuildContext context) {
    return _ListingCard(
      width: 200,
      imageUrl: stay.images.isNotEmpty ? stay.images.first : null,
      title: stay.name,
      subtitle: stay.location,
      price: 'LKR ${stay.pricePerNight.toStringAsFixed(0)}/night',
      rating: stay.rating,
      badge: stay.stayType,
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _ListingCard(
      width: 200,
      imageUrl: vehicle.images.isNotEmpty ? vehicle.images.first : null,
      title: vehicle.title,
      subtitle: '${vehicle.make} ${vehicle.model} · ${vehicle.location}',
      price: 'LKR ${vehicle.pricePerDay.toStringAsFixed(0)}/day',
      rating: vehicle.rating,
      badge: vehicle.withDriver ? 'With Driver' : null,
    );
  }
}

class _EventCard extends StatelessWidget {
  final PearlEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return _ListingCard(
      width: 200,
      imageUrl: event.image.isNotEmpty
          ? event.image
          : (event.images.isNotEmpty ? event.images.first : null),
      title: event.title,
      subtitle: '${event.venue} · ${event.date}',
      price: event.prices.isNotEmpty
          ? 'From LKR ${event.prices.values.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}'
          : 'Free',
      badge: event.category.name,
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Property property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return _ListingCard(
      width: 200,
      imageUrl: property.images.isNotEmpty ? property.images.first : null,
      title: property.title,
      subtitle: property.location,
      price: 'LKR ${property.price.toStringAsFixed(0)}',
      badge: property.listingType.name,
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE LISTING CARD
// ─────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final double width;
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String price;
  final double? rating;
  final String? badge;

  const _ListingCard({
    required this.width,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.price,
    this.rating,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: PearlHubColors.border,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: PearlHubColors.border,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: PearlHubColors.border,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PearlHubColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: PearlHubColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: PearlHubColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: PearlHubColors.primary,
                          ),
                        ),
                        const Spacer(),
                        if (rating != null && rating! > 0) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
