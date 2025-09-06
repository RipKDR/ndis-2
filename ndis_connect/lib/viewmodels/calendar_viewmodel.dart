import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class CalendarViewModel extends ChangeNotifier {
  final EventService _service;
  final FirebaseAuth _auth;
  final _conn = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<EventModel> _events = [];
  bool _loading = true;
  String? _error;

  CalendarViewModel(this._service, this._auth) {
    _sub = _conn.onConnectivityChanged.listen((_) => _onConnectivity());
    _bootstrap();
  }

  DateTime get currentMonth => _currentMonth;
  List<EventModel> get events => _events;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> _bootstrap() async {
    await refresh();
  }

  Future<void> refresh() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _events = await _service.fetchMonth(uid, _currentMonth.year, _currentMonth.month);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> goToMonth(DateTime month) async {
    _currentMonth = DateTime(month.year, month.month);
    await refresh();
  }

  Future<EventModel> addEvent(EventModel e) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    final created = await _service.create(uid, e);
    await refresh();
    return created;
  }

  Future<void> updateEvent(EventModel e) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _service.update(uid, e);
    await refresh();
  }

  Future<void> deleteEvent(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _service.delete(uid, id);
    await refresh();
  }

  Future<void> _onConnectivity() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _service.processQueue(uid);
    await refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
