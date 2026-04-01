import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/supabase_client.dart';
import 'package:shared/models/user_profile.dart';

/// Role-aware listing creation screen.
/// Shows different form fields based on the provider's role:
/// - stay_provider → Stay form
/// - vehicle_provider → Vehicle form
/// - event_provider → Event form
/// - owner/broker → Property form
/// - sme → SME Business form
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedListingType;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _getListingTable(UserRole role) {
    switch (role) {
      case UserRole.stayProvider:
        return 'stays_listings';
      case UserRole.vehicleProvider:
        return 'vehicles_listings';
      case UserRole.eventProvider:
        return 'events_listings';
      case UserRole.owner:
      case UserRole.broker:
        return 'properties_listings';
      case UserRole.sme:
        return 'sme_businesses';
      default:
        return 'stays_listings';
    }
  }

  String _getListingLabel(UserRole role) {
    switch (role) {
      case UserRole.stayProvider:
        return 'Stay';
      case UserRole.vehicleProvider:
        return 'Vehicle';
      case UserRole.eventProvider:
        return 'Event';
      case UserRole.owner:
      case UserRole.broker:
        return 'Property';
      case UserRole.sme:
        return 'SME Business';
      default:
        return 'Listing';
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final role = ref.read(userRoleProvider);
    if (user == null || role == null) return;

    setState(() => _isSubmitting = true);

    try {
      final table = _getListingTable(role);
      final baseData = <String, dynamic>{
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'moderation_status': 'pending', // All new listings start as pending
        'active': true,
      };

      // Add role-specific fields
      switch (role) {
        case UserRole.stayProvider:
          baseData['name'] = _titleController.text.trim();
          baseData['price_per_night'] =
              double.tryParse(_priceController.text) ?? 0;
          baseData['stay_type'] = _selectedListingType ?? 'hotel';
          break;
        case UserRole.vehicleProvider:
          baseData['price_per_day'] =
              double.tryParse(_priceController.text) ?? 0;
          baseData['vehicle_type'] = _selectedListingType ?? 'car';
          break;
        case UserRole.eventProvider:
          baseData['category'] = _selectedListingType ?? 'cultural';
          baseData['venue'] = _locationController.text.trim();
          baseData['event_date'] = DateTime.now().toIso8601String();
          break;
        case UserRole.owner:
        case UserRole.broker:
          baseData['price'] = double.tryParse(_priceController.text) ?? 0;
          baseData['type'] = _selectedListingType ?? 'house';
          baseData['owner_id'] = user.id;
          break;
        case UserRole.sme:
          baseData['business_name'] = _titleController.text.trim();
          baseData['owner_id'] = user.id;
          baseData['category'] = _selectedListingType ?? 'retail';
          baseData['phone'] = '';
          baseData['email'] = user.email ?? '';
          break;
        default:
          break;
      }

      await PearlHubSupabase.client.from(table).insert(baseData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted for review!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _priceController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<String> _getTypeOptions(UserRole role) {
    switch (role) {
      case UserRole.stayProvider:
        return ['hotel', 'villa', 'guest_house', 'hostel', 'resort', 'airbnb'];
      case UserRole.vehicleProvider:
        return [
          'car',
          'van',
          'bus',
          'tuk_tuk',
          'motorcycle',
          'suv',
          'jeep',
          'minibus'
        ];
      case UserRole.eventProvider:
        return [
          'cultural',
          'music',
          'food',
          'sports',
          'business',
          'adventure',
          'religious',
          'art'
        ];
      case UserRole.owner:
      case UserRole.broker:
        return ['house', 'apartment', 'land', 'commercial', 'villa', 'office'];
      case UserRole.sme:
        return [
          'retail',
          'food',
          'services',
          'crafts',
          'technology',
          'tourism'
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final listingLabel = _getListingLabel(role);
    final typeOptions = _getTypeOptions(role);

    return Scaffold(
      appBar: AppBar(title: Text('Create $listingLabel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              if (typeOptions.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedListingType,
                  decoration: InputDecoration(
                    labelText: '$listingLabel Type',
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: typeOptions
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedListingType = v),
                  validator: (v) =>
                      v == null ? 'Please select a type' : null,
                ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '$listingLabel Name/Title',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Price (not for SME)
              if (role != UserRole.sme)
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: role == UserRole.stayProvider
                        ? 'Price per night (LKR)'
                        : role == UserRole.vehicleProvider
                            ? 'Price per day (LKR)'
                            : 'Price (LKR)',
                    prefixIcon: const Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Image upload placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_upload, size: 36, color: Color(0xFF94A3B8)),
                      SizedBox(height: 8),
                      Text(
                        'Tap to upload images',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Images will be uploaded to Supabase Storage. Max 5MB per image.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),

              // Info about moderation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All listings are reviewed by PearlHub admin before going live.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitListing,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Submit $listingLabel for Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
