enum ServiceProviderCategory {
  therapy,
  supportWork,
  equipment,
  transport,
  accommodation,
  employment,
  education,
  recreation,
  health,
  other
}

class ServiceProviderModel {
  final String id;
  final String name;
  final String description;
  final double lat;
  final double lng;
  final String address;
  final String phone;
  final String email;
  final String website;
  final ServiceProviderCategory category;
  final List<String> services;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isAvailable;
  final Map<String, dynamic> operatingHours;
  final List<String> accessibilityFeatures;
  final double distanceFromUser; // in kilometers
  final DateTime lastUpdated;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.category,
    required this.services,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.isAvailable,
    required this.operatingHours,
    required this.accessibilityFeatures,
    this.distanceFromUser = 0.0,
    required this.lastUpdated,
  });

  ServiceProviderModel copyWith({
    String? id,
    String? name,
    String? description,
    double? lat,
    double? lng,
    String? address,
    String? phone,
    String? email,
    String? website,
    ServiceProviderCategory? category,
    List<String>? services,
    double? rating,
    int? reviewCount,
    bool? isVerified,
    bool? isAvailable,
    Map<String, dynamic>? operatingHours,
    List<String>? accessibilityFeatures,
    double? distanceFromUser,
    DateTime? lastUpdated,
  }) {
    return ServiceProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      category: category ?? this.category,
      services: services ?? this.services,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      operatingHours: operatingHours ?? this.operatingHours,
      accessibilityFeatures: accessibilityFeatures ?? this.accessibilityFeatures,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case ServiceProviderCategory.therapy:
        return 'Therapy';
      case ServiceProviderCategory.supportWork:
        return 'Support Work';
      case ServiceProviderCategory.equipment:
        return 'Equipment';
      case ServiceProviderCategory.transport:
        return 'Transport';
      case ServiceProviderCategory.accommodation:
        return 'Accommodation';
      case ServiceProviderCategory.employment:
        return 'Employment';
      case ServiceProviderCategory.education:
        return 'Education';
      case ServiceProviderCategory.recreation:
        return 'Recreation';
      case ServiceProviderCategory.health:
        return 'Health';
      case ServiceProviderCategory.other:
        return 'Other';
    }
  }

  String get ratingDisplay => rating > 0 ? '${rating.toStringAsFixed(1)} ($reviewCount reviews)' : 'No reviews';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'lat': lat,
        'lng': lng,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'category': category.name,
        'services': services,
        'rating': rating,
        'reviewCount': reviewCount,
        'isVerified': isVerified,
        'isAvailable': isAvailable,
        'operatingHours': operatingHours,
        'accessibilityFeatures': accessibilityFeatures,
        'distanceFromUser': distanceFromUser,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ServiceProviderModel.fromMap(Map<String, dynamic> m) => ServiceProviderModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String? ?? '',
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        address: m['address'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String? ?? '',
        website: m['website'] as String? ?? '',
        category: ServiceProviderCategory.values.firstWhere(
          (e) => e.name == m['category'],
          orElse: () => ServiceProviderCategory.other,
        ),
        services: List<String>.from(m['services'] ?? []),
        rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (m['reviewCount'] as num?)?.toInt() ?? 0,
        isVerified: (m['isVerified'] as bool?) ?? false,
        isAvailable: (m['isAvailable'] as bool?) ?? true,
        operatingHours: Map<String, dynamic>.from(m['operatingHours'] ?? {}),
        accessibilityFeatures: List<String>.from(m['accessibilityFeatures'] ?? []),
        distanceFromUser: (m['distanceFromUser'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: DateTime.parse(m['lastUpdated'] as String? ?? DateTime.now().toIso8601String()),
      );
}

