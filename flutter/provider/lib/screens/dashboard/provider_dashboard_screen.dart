import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/listings_service.dart';

/// Provider dashboard with REAL earnings chart.
/// This is a key data fix: the web app used hardcoded bar heights
/// [30, 45, 38, 52, 60, 58, 70, 85, 92, 88]. This queries the
/// actual earnings table from Supabase.
class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    final userId = user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.signOut(),
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(providerEarningsProvider(userId));
                ref.invalidate(providerStaysProvider(userId));
                ref.invalidate(providerVehiclesProvider(userId));
                ref.invalidate(providerEventsProvider(userId));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF0EA5E9),
                            child: Text(
                              (profile.valueOrNull?.fullName ?? 'P')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.valueOrNull?.fullName ?? 'Provider',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  profile.valueOrNull?.role ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  _StatsRow(userId: userId),
                  const SizedBox(height: 24),

                  // REAL Earnings Chart
                  const Text(
                    'Earnings (Last 30 Days)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RealEarningsChart(userId: userId),
                  const SizedBox(height: 24),

                  // Active Listings summary
                  const Text(
                    'Your Listings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ListingsSummary(userId: userId),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  final String userId;
  const _StatsRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(providerEarningsProvider(userId));

    return earnings.when(
      data: (data) {
        final totalRevenue =
            data.fold<double>(0, (sum, e) => sum + (e['amount'] as num));
        final totalBookings = data.length;

        return Row(
          children: [
            _StatCard(
              label: 'Revenue',
              value: 'LKR ${totalRevenue.toStringAsFixed(0)}',
              icon: Icons.monetization_on,
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Bookings',
              value: '$totalBookings',
              icon: Icons.receipt_long,
              color: const Color(0xFF3B82F6),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REAL EARNINGS CHART
// Queries the earnings table — NO hardcoded data.
// ─────────────────────────────────────────────

class _RealEarningsChart extends ConsumerWidget {
  final String userId;
  const _RealEarningsChart({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(providerEarningsProvider(userId));

    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: earnings.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(
                  child: Text(
                    'No earnings data yet.\nComplete bookings to see your revenue chart.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                );
              }

              // Group earnings by day
              final dailyEarnings = <String, double>{};
              for (final e in data) {
                final date =
                    (e['created_at'] as String).substring(0, 10);
                dailyEarnings[date] =
                    (dailyEarnings[date] ?? 0) + (e['amount'] as num);
              }

              final sortedDays = dailyEarnings.keys.toList()..sort();
              final spots = sortedDays.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  dailyEarnings[entry.value]!,
                );
              }).toList();

              return LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (sortedDays.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDays.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                sortedDays[index].substring(5),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF0EA5E9),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LISTINGS SUMMARY
// ─────────────────────────────────────────────

class _ListingsSummary extends ConsumerWidget {
  final String userId;
  const _ListingsSummary({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stays = ref.watch(providerStaysProvider(userId));
    final vehicles = ref.watch(providerVehiclesProvider(userId));
    final events = ref.watch(providerEventsProvider(userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _listingRow(
              'Stays',
              Icons.hotel,
              const Color(0xFF8B5CF6),
              stays.valueOrNull?.length ?? 0,
            ),
            const Divider(),
            _listingRow(
              'Vehicles',
              Icons.directions_car,
              const Color(0xFF06B6D4),
              vehicles.valueOrNull?.length ?? 0,
            ),
            const Divider(),
            _listingRow(
              'Events',
              Icons.event,
              const Color(0xFFEC4899),
              events.valueOrNull?.length ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _listingRow(String label, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
