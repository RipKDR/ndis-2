import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService;
  final fb.FirebaseAuth _auth;
  StreamSubscription<fb.User?>? _sub;

  UserProfile? _profile;
  bool _loading = true;

  UserViewModel(this._userService, this._auth) {
    _sub = _auth.authStateChanges().listen(_onAuth);
  }

  bool get loading => _loading;
  UserProfile? get profile => _profile;
  String get role => _profile?.role ?? '';

  Future<void> _onAuth(fb.User? user) async {
    if (user == null) {
      _profile = null;
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    // Try local first
    final local = await _userService.getLocal(user.uid);
    if (local != null) {
      _profile = local;
      _loading = false;
      notifyListeners();
    }
    try {
      final remote = await _userService.fetchRemote(user.uid);
      if (remote != null) {
        _profile = remote;
      } else {
        _profile = UserProfile(uid: user.uid, role: '', email: user.email, displayName: user.displayName);
      }
    } catch (_) {
      // keep whatever we have
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setRole(String role) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(role: role);
    notifyListeners();
    await _userService.upsertProfile(_profile!);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

