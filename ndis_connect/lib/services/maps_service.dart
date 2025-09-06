import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/service_provider.dart';

class MapsService {
  final _db = FirebaseFirestore.instance;
  final _conn = Connectivity();
  // Geolocator instance
  
  final String _cacheBoxName = 'service_providers_cache';
  final String _userLocationBoxName = 'user_location_cache';
  
  // Google Maps API key - should be stored securely in production
  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  bool get isOfflineFallback => false;

  // Location services
  Future<Position?> getCurrentLocation() async {
    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Cache location
      await _cacheUserLocation(position);
      
      return position;
    } catch (e) {
      // Try to get cached location
      return await _getCachedUserLocation();
    }
  }

  Future<void> _cacheUserLocation(Position position) async {
    final box = await Hive.openBox<String>(_userLocationBoxName);
    await box.put('last_location', jsonEncode({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  Future<Position?> _getCachedUserLocation() async {
    try {
      final box = await Hive.openBox<String>(_userLocationBoxName);
      final cached = box.get('last_location');
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        
        // Only use cached location if it's less than 1 hour old
        if (DateTime.now().difference(timestamp).inHours < 1) {
          return Position(
            latitude: data['latitude'] as double,
            longitude: data['longitude'] as double,
            timestamp: timestamp,
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  // Service provider data
  Future<List<ServiceProviderModel>> fetchServiceProviders({
    double? userLat,
    double? userLng,
    double radiusKm = 50.0,
    ServiceProviderCategory? category,
    String? searchQuery,
  }) async {
    try {
      // Check connectivity
      final connectivity = await _conn.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline) {
        // Fetch from Firestore
        Query query = _db.collection('providers');
        
        if (category != null) {
          query = query.where('category', isEqualTo: category.name);
        }
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
                      .where('name', isLessThan: '$searchQuery\uf8ff');
        }

        final snapshot = await query.get();
        List<ServiceProviderModel> providers = snapshot.docs
            .map((doc) => ServiceProviderModel.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }))
            .toList();

        // Calculate distances if user location is provided
        if (userLat != null && userLng != null) {
          providers = providers.map((provider) {
            final distance = calculateDistance(
              userLat, userLng,
              provider.lat, provider.lng,
            );
            return provider.copyWith(distanceFromUser: distance);
          }).toList();

          // Filter by radius
          providers = providers.where((p) => p.distanceFromUser <= radiusKm).toList();
          
          // Sort by distance
          providers.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
        }

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
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Google Places API integration for additional data
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,formatted_phone_number,website,rating,reviews,opening_hours'
        '&key=$_googleMapsApiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['result'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // Ignore API errors
    }
    return null;
  }

  // Geocoding
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=$_googleMapsApiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final location = results[0]['geometry']['location'] as Map<String, dynamic>;
          return LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      // Ignore geocoding errors
    }
    return null;
  }

  // Reverse geocoding
  Future<String?> reverseGeocode(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&key=$_googleMapsApiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['formatted_address'] as String?;
        }
      }
    } catch (e) {
      // Ignore reverse geocoding errors
    }
    return null;
  }

  // Directions
  Future<Map<String, dynamic>?> getDirections(
    LatLng origin,
    LatLng destination,
    String travelMode,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$travelMode'
        '&key=$_googleMapsApiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }
    } catch (e) {
      // Ignore directions errors
    }
    return null;
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final providersBox = await Hive.openBox<String>(_cacheBoxName);
      final locationBox = await Hive.openBox<String>(_userLocationBoxName);
      
      await providersBox.clear();
      await locationBox.clear();
    } catch (e) {
      // Ignore cache clearing errors
    }
  }
}
