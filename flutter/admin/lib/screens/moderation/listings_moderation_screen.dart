import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:shared/models/user_profile.dart';

/// Listings moderation screen — tabbed view per vertical.
/// Admin can approve or reject listings with notes.
/// Mirrors the moderation flow from AdminDashboard.tsx.
class ListingsModerationScreen extends ConsumerStatefulWidget {
  const ListingsModerationScreen({super.key});

  @override
  ConsumerState<ListingsModerationScreen> createState() =>
      _ListingsModerationScreenState();
}

class _ListingsModerationScreenState
    extends ConsumerState<ListingsModerationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    _VerticalTab('Stays', 'stays_listings', Icons.hotel),
    _VerticalTab('Vehicles', 'vehicles_listings', Icons.directions_car),
    _VerticalTab('Events', 'events_listings', Icons.event),
    _VerticalTab('Properties', 'properties_listings', Icons.home_work),
    _VerticalTab('SME', 'sme_businesses', Icons.store),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Moderation'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs
              .map((t) => Tab(icon: Icon(t.icon, size: 18), text: t.label))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            _tabs.map((tab) => _ModerationList(tableName: tab.table)).toList(),
      ),
    );
  }
}

class _VerticalTab {
  final String label;
  final String table;
  final IconData icon;
  const _VerticalTab(this.label, this.table, this.icon);
}

// ─────────────────────────────────────────────
// MODERATION LIST
// ─────────────────────────────────────────────

class _ModerationList extends ConsumerStatefulWidget {
  final String tableName;
  const _ModerationList({required this.tableName});

  @override
  ConsumerState<_ModerationList> createState() => _ModerationListState();
}

class _ModerationListState extends ConsumerState<_ModerationList> {
  String _filterStatus = 'pending';
  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _loading = true);

    try {
      final data = await PearlHubSupabase.client
          .from(widget.tableName)
          .select()
          .eq('moderation_status', _filterStatus)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _listings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(
    String id,
    String newStatus,
    String? adminNote,
  ) async {
    await PearlHubSupabase.client.from(widget.tableName).update({
      'moderation_status': newStatus,
      if (adminNote != null) 'admin_note': adminNote,
    }).eq('id', id);

    // Log admin action
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await PearlHubSupabase.client.from('admin_actions').insert({
        'admin_id': user.id,
        'action': 'moderation_$newStatus',
        'target_table': widget.tableName,
        'target_id': id,
        'note': adminNote,
      });
    }

    _loadListings();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF22C55E);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFEAB308);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: ['pending', 'approved', 'rejected'].map((status) {
              final isSelected = _filterStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _filterStatus = status);
                    _loadListings();
                  },
                  selectedColor: _statusColor(status).withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
        ),

        // Listings
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _listings.isEmpty
                  ? Center(
                      child: Text(
                        'No $_filterStatus listings',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadListings(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _listings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final listing = _listings[index];
                          return _ModerationCard(
                            listing: listing,
                            statusColor: _statusColor(_filterStatus),
                            onApprove: () => _showActionDialog(
                              listing['id'],
                              'approved',
                            ),
                            onReject: () => _showActionDialog(
                              listing['id'],
                              'rejected',
                            ),
                            isPending: _filterStatus == 'pending',
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  void _showActionDialog(String listingId, String newStatus) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          newStatus == 'approved' ? 'Approve Listing' : 'Reject Listing',
        ),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: 'Admin note ${newStatus == 'rejected' ? '(reason)' : '(optional)'}',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(
                listingId,
                newStatus,
                noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'approved'
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
            ),
            child: Text(newStatus == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MODERATION CARD
// ─────────────────────────────────────────────

class _ModerationCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final Color statusColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isPending;

  const _ModerationCard({
    required this.listing,
    required this.statusColor,
    required this.onApprove,
    required this.onReject,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final title = listing['title'] ??
        listing['name'] ??
        listing['business_name'] ??
        'Untitled';
    final location = listing['location'] ?? '';
    final createdAt = listing['created_at'] ?? '';
    final adminNote = listing['admin_note'];
    final userId = listing['user_id'] ?? listing['owner_id'] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (listing['moderation_status'] ?? 'pending')
                        .toString()
                        .toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Location & date
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  location.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  createdAt.toString().length > 10
                      ? createdAt.toString().substring(0, 10)
                      : createdAt.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            // Provider ID
            Text(
              'Provider: ${userId.toString().length > 8 ? '${userId.toString().substring(0, 8)}...' : userId}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
            // Admin note
            if (adminNote != null && adminNote.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        adminNote.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Action buttons
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
