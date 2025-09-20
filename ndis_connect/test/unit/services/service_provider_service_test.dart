import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/models/service_provider.dart';
import 'package:ndis_connect/services/service_provider_service.dart';

import 'service_provider_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  Connectivity
])
void main() {
  group('ServiceProviderService', () {
    late ServiceProviderService serviceProviderService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockQuery = MockQuery();
      mockQuerySnapshot = MockQuerySnapshot();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockConnectivity = MockConnectivity();

      serviceProviderService = ServiceProviderService();
    });

    group('fetchAll', () {
      test('should return all service providers from Firestore', () async {
        // Arrange
        final mockProviderData = {
          'id': 'provider-1',
          'name': 'Test Provider',
          'description': 'Test Description',
          'lat': -33.8688,
          'lng': 151.2093,
          'address': '123 Test Street',
          'phone': '1234567890',
          'email': 'test@provider.com',
          'website': 'https://testprovider.com',
          'category': 'therapy',
          'services': ['Physical Therapy', 'Occupational Therapy'],
          'rating': 4.5,
          'reviewCount': 10,
          'isVerified': true,
          'isAvailable': true,
          'operatingHours': {'monday': '9:00-17:00'},
          'accessibilityFeatures': ['Wheelchair Access', 'Audio Description'],
          'distanceFromUser': 0.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        };

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Fix: Ensure the mockDocumentSnapshot is of the correct type for QueryDocumentSnapshot<Object?>
        when(mockQuerySnapshot.docs)
            .thenReturn([mockDocumentSnapshot as QueryDocumentSnapshot<Map<String, dynamic>>]);
        when(mockDocumentSnapshot.data()).thenReturn(mockProviderData);
        when(mockDocumentSnapshot.id).thenReturn('provider-1');
        final result = await serviceProviderService.fetchAll();

        // Assert
        expect(result, isA<List<ServiceProviderModel>>());
        expect(result.length, 1);
        expect(result.first.name, 'Test Provider');
        expect(result.first.category, ServiceProviderCategory.therapy);
      });
    });

    group('fetchByCategory', () {
      test('should return providers filtered by category', () async {
        // Arrange
        const category = ServiceProviderCategory.therapy;

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.where('category', isEqualTo: 'therapy')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await serviceProviderService.fetchByCategory(category);

        // Assert
        expect(result, isA<List<ServiceProviderModel>>());
        verify(mockCollection.where('category', isEqualTo: 'therapy')).called(1);
      });
    });

    group('searchProviders', () {
      test('should search providers by name', () async {
        // Arrange
        const query = 'therapy';

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.where('name', isGreaterThanOrEqualTo: 'therapy')).thenReturn(mockQuery);
        when(mockQuery.where('name', isLessThan: 'therapy\uf8ff')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await serviceProviderService.searchProviders(query);

        // Assert
        expect(result, isA<List<ServiceProviderModel>>());
        verify(mockCollection.where('name', isGreaterThanOrEqualTo: 'therapy')).called(1);
      });
    });

    group('getById', () {
      test('should return provider by ID', () async {
        // Arrange
        const providerId = 'provider-1';
        final mockProviderData = {
          'name': 'Test Provider',
          'description': 'Test Description',
          'lat': -33.8688,
          'lng': 151.2093,
          'address': '123 Test Street',
          'phone': '1234567890',
          'email': 'test@provider.com',
          'website': 'https://testprovider.com',
          'category': 'therapy',
          'services': ['Physical Therapy'],
          'rating': 4.5,
          'reviewCount': 10,
          'isVerified': true,
          'isAvailable': true,
          'operatingHours': {},
          'accessibilityFeatures': [],
          'distanceFromUser': 0.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        };

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.doc(providerId)).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(mockProviderData);
        when(mockDocumentSnapshot.id).thenReturn(providerId);

        // Act
        final result = await serviceProviderService.getById(providerId);

        // Assert
        expect(result, isA<ServiceProviderModel>());
        expect(result!.name, 'Test Provider');
        expect(result.id, providerId);
      });

      test('should return null when provider does not exist', () async {
        // Arrange
        const providerId = 'non-existent';

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.doc(providerId)).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await serviceProviderService.getById(providerId);

        // Assert
        expect(result, isNull);
      });
    });

    group('addProvider', () {
      test('should add a new provider', () async {
        // Arrange
        final provider = ServiceProviderModel(
          id: 'provider-1',
          name: 'New Provider',
          description: 'New Description',
          lat: -33.8688,
          lng: 151.2093,
          address: '123 New Street',
          phone: '1234567890',
          email: 'new@provider.com',
          website: 'https://newprovider.com',
          category: ServiceProviderCategory.therapy,
          services: ['Physical Therapy'],
          rating: 0.0,
          reviewCount: 0,
          isVerified: false,
          isAvailable: true,
          operatingHours: {},
          accessibilityFeatures: [],
          lastUpdated: DateTime.now(),
        );

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.doc('provider-1')).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenAnswer((_) async {});

        // Act
        await serviceProviderService.addProvider(provider);

        // Assert
        verify(mockDocument.set(any)).called(1);
      });
    });

    group('updateProvider', () {
      test('should update an existing provider', () async {
        // Arrange
        final provider = ServiceProviderModel(
          id: 'provider-1',
          name: 'Updated Provider',
          description: 'Updated Description',
          lat: -33.8688,
          lng: 151.2093,
          address: '123 Updated Street',
          phone: '1234567890',
          email: 'updated@provider.com',
          website: 'https://updatedprovider.com',
          category: ServiceProviderCategory.therapy,
          services: ['Physical Therapy'],
          rating: 4.0,
          reviewCount: 5,
          isVerified: true,
          isAvailable: true,
          operatingHours: {},
          accessibilityFeatures: [],
          lastUpdated: DateTime.now(),
        );

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.doc('provider-1')).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await serviceProviderService.updateProvider(provider);

        // Assert
        verify(mockDocument.update(any)).called(1);
      });
    });

    group('deleteProvider', () {
      test('should delete a provider', () async {
        // Arrange
        const providerId = 'provider-1';

        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.doc(providerId)).thenReturn(mockDocument);
        when(mockDocument.delete()).thenAnswer((_) async {});

        // Act
        await serviceProviderService.deleteProvider(providerId);

        // Assert
        verify(mockDocument.delete()).called(1);
      });
    });

    group('getNearbyProviders', () {
      test('should return providers within radius', () async {
        // Arrange
        const latitude = -33.8688;
        const longitude = 151.2093;
        const radiusKm = 10.0;

        // Mock fetchAll to return sample providers
        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        final mockProvidersData = [
          {
            'id': 'provider-1',
            'name': 'Nearby Provider',
            'description': 'Nearby Description',
            'lat': -33.8688,
            'lng': 151.2093,
            'address': '123 Nearby Street',
            'phone': '1234567890',
            'email': 'nearby@provider.com',
            'website': 'https://nearbyprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 4.5,
            'reviewCount': 10,
            'isVerified': true,
            'isAvailable': true,
            'operatingHours': {},
            'accessibilityFeatures': [],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
          {
            'id': 'provider-2',
            'name': 'Far Provider',
            'description': 'Far Description',
            'lat': -34.0, // Far away
            'lng': 152.0,
            'address': '456 Far Street',
            'phone': '0987654321',
            'email': 'far@provider.com',
            'website': 'https://farprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 3.0,
            'reviewCount': 5,
            'isVerified': false,
            'isAvailable': true,
            'operatingHours': {},
            'accessibilityFeatures': [],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        ];

        final mockDocs = mockProvidersData.map((data) {
          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.data()).thenReturn(data);
          when(mockDoc.id).thenReturn(data['id'] as String);
          return mockDoc;
        }).toList();

        when(mockQuerySnapshot.docs).thenReturn(mockDocs as List<QueryDocumentSnapshot<Object?>>);

        // Act
        final result = await serviceProviderService.getNearbyProviders(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        );

        // Assert
        expect(result, isA<List<ServiceProviderModel>>());
        expect(result.length, 1); // Only nearby provider should be returned
        expect(result.first.name, 'Nearby Provider');
      });
    });

    group('getAccessibleProviders', () {
      test('should return providers with accessibility features', () async {
        // Arrange
        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        final mockProvidersData = [
          {
            'id': 'provider-1',
            'name': 'Accessible Provider',
            'description': 'Accessible Description',
            'lat': -33.8688,
            'lng': 151.2093,
            'address': '123 Accessible Street',
            'phone': '1234567890',
            'email': 'accessible@provider.com',
            'website': 'https://accessibleprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 4.5,
            'reviewCount': 10,
            'isVerified': true,
            'isAvailable': true,
            'operatingHours': {},
            'accessibilityFeatures': ['Wheelchair Access', 'Audio Description'],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
          {
            'id': 'provider-2',
            'name': 'Non-Accessible Provider',
            'description': 'Non-Accessible Description',
            'lat': -33.8688,
            'lng': 151.2093,
            'address': '456 Non-Accessible Street',
            'phone': '0987654321',
            'email': 'nonaccessible@provider.com',
            'website': 'https://nonaccessibleprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 3.0,
            'reviewCount': 5,
            'isVerified': false,
            'isAvailable': true,
            'operatingHours': {},
            'accessibilityFeatures': [],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        ];

        final mockDocs = mockProvidersData.map((data) {
          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.data()).thenReturn(data);
          when(mockDoc.id).thenReturn(data['id'] as String);
          return mockDoc;
        }).toList();

        when(mockQuerySnapshot.docs).thenReturn(mockDocs as List<QueryDocumentSnapshot<Object?>>);

        // Act
        final result = await serviceProviderService.getAccessibleProviders();

        // Assert
        expect(result, isA<List<ServiceProviderModel>>());
        expect(result.length, 1); // Only accessible provider should be returned
        expect(result.first.name, 'Accessible Provider');
        expect(result.first.accessibilityFeatures, isNotEmpty);
      });
    });

    group('getVerifiedProviders', () {
      test('should return only verified providers', () async {
        // Arrange
        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        final mockProvidersData = [
          {
            'id': 'provider-1',
            'name': 'Verified Provider',
            'description': 'Verified Description',
            'lat': -33.8688,
            'lng': 151.2093,
            'address': '123 Verified Street',
            'phone': '1234567890',
            'email': 'verified@provider.com',
            'website': 'https://verifiedprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 4.5,
            'reviewCount': 10,
            'isVerified': true,
            'isAvailable': true,
            'operatingHours': {},
            'accessibilityFeatures': [],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
          {
            'id': 'provider-2',
            'name': 'Unverified Provider',
            'description': 'Unverified Description',
            'lat': -33.8688,
            'lng': 151.2093,
            'address': '456 Unverified Street',
            'phone': '0987654321',
            'email': 'unverified@provider.com',
            'website': 'https://unverifiedprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 3.0,
            'reviewCount': 5,
            'isVerified': false,
            'isAvailable': true,
            'operatingHours': {},
            'accessibilityFeatures': [],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        ];

        final mockDocs = mockProvidersData.map((data) {
          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.data()).thenReturn(data);
          when(mockDoc.id).thenReturn(data['id'] as String);
          return mockDoc;
        }).toList();

        when(mockQuerySnapshot.docs).thenReturn(mockDocs as List<QueryDocumentSnapshot<Object?>>);

        // Act
        final result = await serviceProviderService.getVerifiedProviders();

        // Assert
        expect(result, isA<List<ServiceProviderModel>>());
        expect(result.length, 1); // Only verified provider should be returned
        expect(result.first.name, 'Verified Provider');
        expect(result.first.isVerified, isTrue);
      });
    });

    group('getAvailableProviders', () {
      test('should return only available providers', () async {
        // Arrange
        when(mockFirestore.collection('providers'))
            .thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        final mockProvidersData = [
          {
            'id': 'provider-1',
            'name': 'Available Provider',
            'description': 'Available Description',
            'lat': -33.8688,
            'lng': 151.2093,
            'address': '123 Available Street',
            'phone': '1234567890',
            'email': 'available@provider.com',
            'website': 'https://availableprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 4.5,
            'reviewCount': 10,
            'isVerified': true,
            'isAvailable': true,
            'operatingHours': {},
            'accessibilityFeatures': [],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          } as Map<String, dynamic>,
          {
            'id': 'provider-2',
            'name': 'Unavailable Provider',
            'description': 'Unavailable Description',
            'lat': -33.8688,
            'lng': 151.2093,
            'address': '456 Unavailable Street',
            'phone': '0987654321',
            'email': 'unavailable@provider.com',
            'website': 'https://unavailableprovider.com',
            'category': 'therapy',
            'services': ['Physical Therapy'],
            'rating': 3.0,
            'reviewCount': 5,
            'isVerified': false,
            'isAvailable': false,
            'operatingHours': {},
            'accessibilityFeatures': [],
            'distanceFromUser': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          } as Map<String, dynamic>,
        ];

        final mockDocs = mockProvidersData.map((data) {
          final mockDoc = MockDocumentSnapshot();
          when(mockDoc.data()).thenReturn(data);
          when(mockDoc.id).thenReturn(data['id'] as String);
          return mockDoc;
        }).toList();

        when(mockQuerySnapshot.docs).thenReturn(mockDocs as List<QueryDocumentSnapshot<Object?>>);

        // Act
        final result = await serviceProviderService.getAvailableProviders();

        // Assert
        expect(result, isA<List<ServiceProviderModel>>());
        expect(result.length, 1); // Only available provider should be returned
        expect(result.first.name, 'Available Provider');
        expect(result.first.isAvailable, isTrue);
      });
    });
  });
}
