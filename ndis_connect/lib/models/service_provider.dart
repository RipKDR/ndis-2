class ServiceProviderModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String category;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'category': category,
      };

  factory ServiceProviderModel.fromMap(Map<String, dynamic> m) => ServiceProviderModel(
        id: m['id'] as String,
        name: m['name'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        category: m['category'] as String,
      );
}

