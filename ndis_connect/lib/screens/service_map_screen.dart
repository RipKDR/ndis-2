import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/service_provider.dart';
import '../services/maps_service.dart';
import '../services/service_provider_service.dart';

class ServiceMapScreen extends StatefulWidget {
  static const route = '/map';
  const ServiceMapScreen({super.key});

  @override
  State<ServiceMapScreen> createState() => _ServiceMapScreenState();
}

class _ServiceMapScreenState extends State<ServiceMapScreen> {
  final _svc = ServiceProviderService();
  final _mapsService = MapsService();
  final _conn = Connectivity();
  List<ServiceProviderModel> _providers = [];
  List<ServiceProviderModel> _filteredProviders = [];
  bool _loading = true;
  bool _offline = false;
  Position? _userLocation;
  ServiceProviderCategory? _selectedCategory;
  String _searchQuery = '';
  double _searchRadius = 50.0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final res = await _conn.checkConnectivity();
    _offline = res.contains(ConnectivityResult.none);

    // Get user location
    _userLocation = await _mapsService.getCurrentLocation();

    // Fetch providers
    final list = await _svc.fetchAll();
    setState(() {
      _providers = list;
      _filteredProviders = list;
      _loading = false;
    });
  }

  void _filterProviders() {
    setState(() {
      _filteredProviders = _providers.where((provider) {
        // Category filter
        if (_selectedCategory != null && provider.category != _selectedCategory) {
          return false;
        }

        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!provider.name.toLowerCase().contains(query) &&
              !provider.description.toLowerCase().contains(query) &&
              !provider.services.any((service) => service.toLowerCase().contains(query))) {
            return false;
          }
        }

        // Distance filter
        if (_userLocation != null) {
          final distance = _mapsService.calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            provider.lat,
            provider.lng,
          );
          if (distance > _searchRadius) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final canShowMap = !kIsWeb && (Platform.isAndroid || Platform.isIOS) && !_offline;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.serviceMap),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _bootstrap(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => _showFilters(context),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: 'Search service providers...',
              leading: const Icon(Icons.search),
              trailing: _searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _filterProviders();
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ]
                  : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterProviders();
                });
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : canShowMap
              ? _MapView(
                  providers: _filteredProviders,
                  userLocation: _userLocation,
                )
              : _ListView(providers: _filteredProviders),
      floatingActionButton: _userLocation != null
          ? FloatingActionButton(
              onPressed: () => _centerOnUserLocation(),
              child: const Icon(Icons.my_location),
              tooltip: 'My Location',
            )
          : null,
    );
  }

  void _centerOnUserLocation() {
    // This would be implemented in the map view
    setState(() {});
  }

  Future<void> _showFilters(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        searchRadius: _searchRadius,
        onCategoryChanged: (category) {
          setState(() {
            _selectedCategory = category;
            _filterProviders();
          });
        },
        onRadiusChanged: (radius) {
          setState(() {
            _searchRadius = radius;
            _filterProviders();
          });
        },
      ),
    );
  }
}

class _MapView extends StatefulWidget {
  final List<ServiceProviderModel> providers;
  final Position? userLocation;
  const _MapView({required this.providers, this.userLocation});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  late Set<Marker> markers;
  late GoogleMapController _mapController;
  LatLng? _userLatLng;

  @override
  void initState() {
    super.initState();
    _updateMarkers();
    if (widget.userLocation != null) {
      _userLatLng = LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude);
    }
  }

  @override
  void didUpdateWidget(_MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.providers != oldWidget.providers) {
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    markers = widget.providers
        .map((p) => Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.lat, p.lng),
              infoWindow: InfoWindow(
                title: p.name,
                snippet: '${p.categoryDisplayName} • ${p.ratingDisplay}',
              ),
              icon: _getMarkerIcon(p.category),
            ))
        .toSet();

    // Add user location marker
    if (_userLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLatLng!,
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  BitmapDescriptor _getMarkerIcon(ServiceProviderCategory category) {
    switch (category) {
      case ServiceProviderCategory.therapy:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case ServiceProviderCategory.supportWork:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case ServiceProviderCategory.equipment:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ServiceProviderCategory.transport:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case ServiceProviderCategory.accommodation:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case ServiceProviderCategory.employment:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case ServiceProviderCategory.education:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case ServiceProviderCategory.recreation:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case ServiceProviderCategory.health:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case ServiceProviderCategory.other:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  void centerOnUserLocation() {
    if (_userLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_userLatLng!, 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _userLatLng ??
        (markers.isNotEmpty
            ? markers.first.position
            : const LatLng(-33.8688, 151.2093)); // Sydney fallback

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      myLocationButtonEnabled: false, // We'll use our own button
      myLocationEnabled: true,
      initialCameraPosition: CameraPosition(target: start, zoom: 12),
      markers: markers,
    );
  }
}

class _ListView extends StatelessWidget {
  final List<ServiceProviderModel> providers;
  const _ListView({required this.providers});

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No service providers found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: providers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = providers[i];
        return _ProviderCard(provider: p);
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ServiceProviderModel provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(provider.category),
          child: Icon(
            _getCategoryIcon(provider.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          provider.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.categoryDisplayName),
            if (provider.rating > 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(provider.ratingDisplay),
                ],
              ),
            ],
            if (provider.distanceFromUser > 0) ...[
              const SizedBox(height: 2),
              Text('${provider.distanceFromUser.toStringAsFixed(1)} km away'),
            ],
          ],
        ),
        trailing: provider.isVerified ? const Icon(Icons.verified, color: Colors.green) : null,
        onTap: () => _showProviderDetails(context),
      ),
    );
  }

  Color _getCategoryColor(ServiceProviderCategory category) {
    switch (category) {
      case ServiceProviderCategory.therapy:
        return Colors.green;
      case ServiceProviderCategory.supportWork:
        return Colors.orange;
      case ServiceProviderCategory.equipment:
        return Colors.red;
      case ServiceProviderCategory.transport:
        return Colors.blue;
      case ServiceProviderCategory.accommodation:
        return Colors.purple;
      case ServiceProviderCategory.employment:
        return Colors.yellow[700]!;
      case ServiceProviderCategory.education:
        return Colors.cyan;
      case ServiceProviderCategory.recreation:
        return Colors.pink;
      case ServiceProviderCategory.health:
        return Colors.teal;
      case ServiceProviderCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ServiceProviderCategory category) {
    switch (category) {
      case ServiceProviderCategory.therapy:
        return Icons.healing;
      case ServiceProviderCategory.supportWork:
        return Icons.support_agent;
      case ServiceProviderCategory.equipment:
        return Icons.medical_services;
      case ServiceProviderCategory.transport:
        return Icons.directions_car;
      case ServiceProviderCategory.accommodation:
        return Icons.home;
      case ServiceProviderCategory.employment:
        return Icons.work;
      case ServiceProviderCategory.education:
        return Icons.school;
      case ServiceProviderCategory.recreation:
        return Icons.sports;
      case ServiceProviderCategory.health:
        return Icons.local_hospital;
      case ServiceProviderCategory.other:
        return Icons.help;
    }
  }

  void _showProviderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProviderDetailsSheet(provider: provider),
    );
  }
}

class _ProviderDetailsSheet extends StatelessWidget {
  final ServiceProviderModel provider;
  const _ProviderDetailsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  provider.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.categoryDisplayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (provider.rating > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(provider.ratingDisplay),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (provider.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(provider.description),
                  const SizedBox(height: 16),
                ],
                if (provider.address.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: provider.address,
                  ),
                ],
                if (provider.phone.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: provider.phone,
                  ),
                ],
                if (provider.email.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: provider.email,
                  ),
                ],
                if (provider.website.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.web,
                    label: 'Website',
                    value: provider.website,
                  ),
                ],
                if (provider.services.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.services.map((service) {
                      return Chip(
                        label: Text(service),
                        backgroundColor: Colors.blue[50],
                      );
                    }).toList(),
                  ),
                ],
                if (provider.accessibilityFeatures.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Accessibility Features',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.accessibilityFeatures.map((feature) {
                      return Chip(
                        label: Text(feature),
                        backgroundColor: Colors.green[50],
                        avatar: const Icon(Icons.accessibility, size: 16),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Open in maps app
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          // Call provider
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ServiceProviderCategory? selectedCategory;
  final double searchRadius;
  final Function(ServiceProviderCategory?) onCategoryChanged;
  final Function(double) onRadiusChanged;

  const _FilterSheet({
    required this.selectedCategory,
    required this.searchRadius,
    required this.onCategoryChanged,
    required this.onRadiusChanged,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  ServiceProviderCategory? _selectedCategory;
  double _searchRadius = 50.0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _searchRadius = widget.searchRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = null;
                  });
                  widget.onCategoryChanged(null);
                },
              ),
              ...ServiceProviderCategory.values.map((category) {
                return FilterChip(
                  label: Text(category.name),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                    widget.onCategoryChanged(_selectedCategory);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Search Radius: ${_searchRadius.toStringAsFixed(0)} km',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _searchRadius,
            min: 5,
            max: 100,
            divisions: 19,
            onChanged: (value) {
              setState(() {
                _searchRadius = value;
              });
              widget.onRadiusChanged(value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _searchRadius = 50.0;
                    });
                    widget.onCategoryChanged(null);
                    widget.onRadiusChanged(50.0);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
