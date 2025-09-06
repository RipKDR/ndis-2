import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityViewModel extends ChangeNotifier {
  final _conn = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;
  bool get offline => _offline;

  ConnectivityViewModel() {
    _sub = _conn.onConnectivityChanged.listen((results) {
      final hasNetwork = !results.contains(ConnectivityResult.none);
      _offline = !hasNetwork;
      notifyListeners();
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final res = await _conn.checkConnectivity();
    final hasNetwork = !res.contains(ConnectivityResult.none);
    _offline = !hasNetwork;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
