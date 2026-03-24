import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/taxi_service.dart';

/// Admin overview — live platform stats.
/// Queries across all tables with counts.
class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformStats = ref.watch(_platformStatsProvider);
    final taxiStats = ref.watch(taxiAdminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PearlHub Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(_platformStatsProvider);
              ref.invalidate(taxiAdminStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_platformStatsProvider);
          ref.invalidate(taxiAdminStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Platform title
            const Text(
              'Platform Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Live statistics from all verticals',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Platform stats
            platformStats.when(
              data: (stats) => _buildStatsGrid(stats),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading stats: $e'),
            ),
            const SizedBox(height: 24),

            // Taxi stats
            const Text(
              'Taxi Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            taxiStats.when(
              data: (stats) => _buildTaxiStats(stats),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // Map provider setting
            _MapProviderSetting(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(_PlatformStats stats) {
    final items = [
      _StatItem('Users', '${stats.totalUsers}', Icons.people, const Color(0xFF3B82F6)),
      _StatItem('Stays', '${stats.stays}', Icons.hotel, const Color(0xFF8B5CF6)),
      _StatItem('Vehicles', '${stats.vehicles}', Icons.directions_car, const Color(0xFF06B6D4)),
      _StatItem('Events', '${stats.events}', Icons.event, const Color(0xFFEC4899)),
      _StatItem('Properties', '${stats.properties}', Icons.home_work, const Color(0xFF10B981)),
      _StatItem('SME', '${stats.sme}', Icons.store, const Color(0xFF6366F1)),
      _StatItem('Pending', '${stats.pending}', Icons.pending_actions, const Color(0xFFEAB308)),
      _StatItem('Bookings', '${stats.bookings}', Icons.receipt, const Color(0xFFF97316)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(item.icon, color: item.color, size: 22),
                    const Spacer(),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaxiStats(TaxiAdminStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _miniStat('Revenue', 'LKR ${stats.revenue.toStringAsFixed(0)}'),
                _miniStat('Rides', '${stats.rides}'),
                _miniStat('Online', '${stats.driversOnline}'),
                _miniStat('KYC', '${stats.pendingKyc}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PLATFORM STATS PROVIDER
// ─────────────────────────────────────────────

class _PlatformStats {
  final int totalUsers;
  final int stays;
  final int vehicles;
  final int events;
  final int properties;
  final int sme;
  final int pending;
  final int bookings;

  _PlatformStats({
    required this.totalUsers,
    required this.stays,
    required this.vehicles,
    required this.events,
    required this.properties,
    required this.sme,
    required this.pending,
    required this.bookings,
  });
}

final _platformStatsProvider = FutureProvider<_PlatformStats>((ref) async {
  final client = PearlHubSupabase.client;

  final results = await Future.wait([
    client.from('profiles').select('id', const FetchOptions(count: CountOption.exact, head: true)),
    client.from('stays_listings').select('id', const FetchOptions(count: CountOption.exact, head: true)),
    client.from('vehicles_listings').select('id', const FetchOptions(count: CountOption.exact, head: true)),
    client.from('events_listings').select('id', const FetchOptions(count: CountOption.exact, head: true)),
    client.from('properties_listings').select('id', const FetchOptions(count: CountOption.exact, head: true)),
    client.from('sme_businesses').select('id', const FetchOptions(count: CountOption.exact, head: true)),
    client.from('stays_listings').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('moderation_status', 'pending'),
    client.from('bookings').select('id', const FetchOptions(count: CountOption.exact, head: true)),
  ]);

  return _PlatformStats(
    totalUsers: (results[0] as PostgrestResponse).count ?? 0,
    stays: (results[1] as PostgrestResponse).count ?? 0,
    vehicles: (results[2] as PostgrestResponse).count ?? 0,
    events: (results[3] as PostgrestResponse).count ?? 0,
    properties: (results[4] as PostgrestResponse).count ?? 0,
    sme: (results[5] as PostgrestResponse).count ?? 0,
    pending: (results[6] as PostgrestResponse).count ?? 0,
    bookings: (results[7] as PostgrestResponse).count ?? 0,
  );
});

// ─────────────────────────────────────────────
// MAP PROVIDER SETTING
// Admin can switch between Google Maps and OSM.
// ─────────────────────────────────────────────

class _MapProviderSetting extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MapProviderSetting> createState() =>
      _MapProviderSettingState();
}

class _MapProviderSettingState extends ConsumerState<_MapProviderSetting> {
  String _current = 'openstreetmap';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await PearlHubSupabase.client
        .from('platform_settings')
        .select('value')
        .eq('key', 'map_provider')
        .maybeSingle();
    if (data != null && mounted) {
      setState(() => _current = data['value'] as String);
    }
  }

  Future<void> _save(String value) async {
    setState(() => _saving = true);
    await PearlHubSupabase.client.from('platform_settings').upsert({
      'key': 'map_provider',
      'value': value,
    });
    setState(() {
      _current = value;
      _saving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Map provider set to ${value == 'google_maps' ? 'Google Maps' : 'OpenStreetMap'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Provider',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Switch between Google Maps and OpenStreetMap for all apps.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _saving
                      ? const Center(child: CircularProgressIndicator())
                      : SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'openstreetmap',
                              label: Text('OSM'),
                              icon: Icon(Icons.map),
                            ),
                            ButtonSegment(
                              value: 'google_maps',
                              label: Text('Google'),
                              icon: Icon(Icons.travel_explore),
                            ),
                          ],
                          selected: {_current},
                          onSelectionChanged: (v) => _save(v.first),
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

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}
