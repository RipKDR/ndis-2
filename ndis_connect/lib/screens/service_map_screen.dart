import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/service_provider.dart';
import '../services/service_provider_service.dart';

class ServiceMapScreen extends StatefulWidget {
  static const route = '/map';
  const ServiceMapScreen({super.key});

  @override
  State<ServiceMapScreen> createState() => _ServiceMapScreenState();
}

class _ServiceMapScreenState extends State<ServiceMapScreen> {
  final _svc = ServiceProviderService();
  final _conn = Connectivity();
  List<ServiceProviderModel> _providers = [];
  bool _loading = true;
  bool _offline = false;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final res = await _conn.checkConnectivity();
    _offline = res.contains(ConnectivityResult.none);
    final list = await _svc.fetchAll();
    setState(() {
      _providers = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final canShowMap = !kIsWeb && (Platform.isAndroid || Platform.isIOS) && !_offline;
    return Scaffold(
      appBar: AppBar(title: Text(s.serviceMap)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : canShowMap
              ? _MapView(providers: _providers)
              : _ListView(providers: _providers),
    );
  }
}

class _MapView extends StatefulWidget {
  final List<ServiceProviderModel> providers;
  const _MapView({required this.providers});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  late Set<Marker> markers;

  @override
  void initState() {
    super.initState();
    markers = widget.providers
        .map((p) => Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.lat, p.lng),
              infoWindow: InfoWindow(title: p.name, snippet: p.category),
            ))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final start = markers.isNotEmpty ? markers.first.position : const LatLng(-33.8688, 151.2093); // Sydney fallback
    return GoogleMap(
      myLocationButtonEnabled: true,
      myLocationEnabled: false,
      initialCameraPosition: CameraPosition(target: start, zoom: 10),
      markers: markers,
    );
  }
}

class _ListView extends StatelessWidget {
  final List<ServiceProviderModel> providers;
  const _ListView({required this.providers});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: providers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = providers[i];
        return ListTile(
          leading: const Icon(Icons.place),
          title: Text(p.name),
          subtitle: Text(p.category),
        );
      },
    );
  }
}
