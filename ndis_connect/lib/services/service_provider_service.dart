import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderService {
  final _db = FirebaseFirestore.instance;
  final _conn = Connectivity();

  final String _cacheBoxName = 'service_providers_cache';

  // Fetch all service providers
  Future<List<ServiceProviderModel>> fetchAll() async {
    try {
      // Check connectivity
      final connectivity = await _conn.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline) {
        // Fetch from Firestore
        final snapshot = await _db.collection('providers').get();
        List<ServiceProviderModel> providers = snapshot.docs
            .map((doc) => ServiceProviderModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList();

        // Cache results
        await _cacheServiceProviders(providers);

        return providers;
      } else {
        // Offline: return cached data
        return await _getCachedServiceProviders();
      }
    } catch (e) {
      // Fallback to cache
      return await _getCachedServiceProviders();
    }
  }

  // Fetch service providers by category
  Future<List<ServiceProviderModel>> fetchByCategory(ServiceProviderCategory category) async {
    try {
      final connectivity = await _conn.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline) {
        final snapshot =
            await _db.collection('providers').where('category', isEqualTo: category.name).get();

        List<ServiceProviderModel> providers = snapshot.docs
            .map((doc) => ServiceProviderModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList();

        return providers;
      } else {
        // Offline: filter cached data
        final cached = await _getCachedServiceProviders();
        return cached.where((p) => p.category == category).toList();
      }
    } catch (e) {
      return [];
    }
  }

  // Search service providers
  Future<List<ServiceProviderModel>> searchProviders(String query) async {
    try {
      final connectivity = await _conn.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline) {
        // Use Firestore text search (limited functionality)
        final snapshot = await _db
            .collection('providers')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: '$query\uf8ff')
            .get();

        List<ServiceProviderModel> providers = snapshot.docs
            .map((doc) => ServiceProviderModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList();

        return providers;
      } else {
        // Offline: search cached data
        final cached = await _getCachedServiceProviders();
        final lowercaseQuery = query.toLowerCase();
        return cached.where((p) {
          return p.name.toLowerCase().contains(lowercaseQuery) ||
              p.description.toLowerCase().contains(lowercaseQuery) ||
              p.services.any((service) => service.toLowerCase().contains(lowercaseQuery));
        }).toList();
      }
    } catch (e) {
      return [];
    }
  }

  // Get service provider by ID
  Future<ServiceProviderModel?> getById(String id) async {
    try {
      final connectivity = await _conn.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline) {
        final doc = await _db.collection('providers').doc(id).get();
        if (doc.exists) {
          return ServiceProviderModel.fromMap({
            ...doc.data()!,
            'id': doc.id,
          });
        }
      } else {
        // Offline: search cached data
        final cached = await _getCachedServiceProviders();
        try {
          return cached.firstWhere((p) => p.id == id);
        } catch (e) {
          return null;
        }
      }
    } catch (e) {
      // Fallback to cache
      final cached = await _getCachedServiceProviders();
      try {
        return cached.firstWhere((p) => p.id == id);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Add new service provider (admin function)
  Future<void> addProvider(ServiceProviderModel provider) async {
    try {
      await _db.collection('providers').doc(provider.id).set(provider.toMap());
    } catch (e) {
      throw Exception('Failed to add service provider: $e');
    }
  }

  // Update service provider (admin function)
  Future<void> updateProvider(ServiceProviderModel provider) async {
    try {
      await _db.collection('providers').doc(provider.id).update(provider.toMap());
    } catch (e) {
      throw Exception('Failed to update service provider: $e');
    }
  }

  // Delete service provider (admin function)
  Future<void> deleteProvider(String id) async {
    try {
      await _db.collection('providers').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete service provider: $e');
    }
  }

  // Get nearby providers
  Future<List<ServiceProviderModel>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    ServiceProviderCategory? category,
  }) async {
    try {
      final providers = await fetchAll();

      // Calculate distances and filter by radius
      final nearbyProviders = providers.where((provider) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          provider.lat,
          provider.lng,
        );

        final withinRadius = distance <= radiusKm;
        final categoryMatch = category == null || provider.category == category;

        return withinRadius && categoryMatch;
      }).toList();

      // Sort by distance
      nearbyProviders.sort((a, b) {
        final distanceA = _calculateDistance(latitude, longitude, a.lat, a.lng);
        final distanceB = _calculateDistance(latitude, longitude, b.lat, b.lng);
        return distanceA.compareTo(distanceB);
      });

      return nearbyProviders;
    } catch (e) {
      return [];
    }
  }

  // Get providers with accessibility features
  Future<List<ServiceProviderModel>> getAccessibleProviders({
    List<String>? requiredFeatures,
  }) async {
    try {
      final providers = await fetchAll();

      if (requiredFeatures == null || requiredFeatures.isEmpty) {
        return providers.where((p) => p.accessibilityFeatures.isNotEmpty).toList();
      }

      return providers.where((provider) {
        return requiredFeatures
            .every((feature) => provider.accessibilityFeatures.contains(feature));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get verified providers only
  Future<List<ServiceProviderModel>> getVerifiedProviders() async {
    try {
      final providers = await fetchAll();
      return providers.where((p) => p.isVerified).toList();
    } catch (e) {
      return [];
    }
  }

  // Get available providers (not closed/disabled)
  Future<List<ServiceProviderModel>> getAvailableProviders() async {
    try {
      final providers = await fetchAll();
      return providers.where((p) => p.isAvailable).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache management
  Future<void> _cacheServiceProviders(List<ServiceProviderModel> providers) async {
    try {
      final box = await Hive.openBox<String>(_cacheBoxName);
      final cacheData = {
        'providers': providers.map((p) => p.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await box.put('cached_providers', jsonEncode(cacheData));
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<List<ServiceProviderModel>> _getCachedServiceProviders() async {
    try {
      final box = await Hive.openBox<String>(_cacheBoxName);
      final cached = box.get('cached_providers');
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);

        // Only use cached data if it's less than 24 hours old
        if (DateTime.now().difference(timestamp).inHours < 24) {
          final providers = (data['providers'] as List)
              .map((p) => ServiceProviderModel.fromMap(p as Map<String, dynamic>))
              .toList();
          return providers;
        }
      }
    } catch (e) {
      // Ignore cache errors
    }
    return [];
  }

  // Distance calculation using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Enhanced search with multiple criteria
  Future<List<ServiceProviderModel>> searchProvidersAdvanced({
    String? query,
    ServiceProviderCategory? category,
    double? latitude,
    double? longitude,
    double? radiusKm,
    List<String>? accessibilityFeatures,
    double? minRating,
    bool? verifiedOnly,
  }) async {
    try {
      List<ServiceProviderModel> providers = await fetchAll();

      // Apply filters
      providers = providers.where((provider) {
        // Text search
        if (query != null && query.isNotEmpty) {
          final lowercaseQuery = query.toLowerCase();
          final matchesText = provider.name.toLowerCase().contains(lowercaseQuery) ||
              provider.description.toLowerCase().contains(lowercaseQuery) ||
              provider.services.any((service) => service.toLowerCase().contains(lowercaseQuery));
          if (!matchesText) return false;
        }

        // Category filter
        if (category != null && provider.category != category) {
          return false;
        }

        // Distance filter
        if (latitude != null && longitude != null && radiusKm != null) {
          final distance = _calculateDistance(latitude, longitude, provider.lat, provider.lng);
          if (distance > radiusKm) return false;
        }

        // Accessibility features filter
        if (accessibilityFeatures != null && accessibilityFeatures.isNotEmpty) {
          final hasAllFeatures = accessibilityFeatures
              .every((feature) => provider.accessibilityFeatures.contains(feature));
          if (!hasAllFeatures) return false;
        }

        // Rating filter
        if (minRating != null && provider.rating < minRating) {
          return false;
        }

        // Verification filter
        if (verifiedOnly == true && !provider.isVerified) {
          return false;
        }

        return true;
      }).toList();

      // Sort by distance if location provided
      if (latitude != null && longitude != null) {
        providers.sort((a, b) {
          final distanceA = _calculateDistance(latitude, longitude, a.lat, a.lng);
          final distanceB = _calculateDistance(latitude, longitude, b.lat, b.lng);
          return distanceA.compareTo(distanceB);
        });
      }

      return providers;
    } catch (e) {
      return [];
    }
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox<String>(_cacheBoxName);
      await box.clear();
    } catch (e) {
      // Ignore cache clearing errors
    }
  }

  // Get cache info
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final box = await Hive.openBox<String>(_cacheBoxName);
      final cached = box.get('cached_providers');
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        final providers = (data['providers'] as List).length;

        return {
          'cached': true,
          'timestamp': timestamp,
          'providerCount': providers,
          'ageHours': DateTime.now().difference(timestamp).inHours,
        };
      }
    } catch (e) {
      // Ignore cache errors
    }
    return {
      'cached': false,
      'timestamp': null,
      'providerCount': 0,
      'ageHours': 0,
    };
  }
}
