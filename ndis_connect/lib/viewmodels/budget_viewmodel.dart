import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetService _svc;
  final FirebaseAuth _auth;
  BudgetViewModel(this._svc, this._auth);

  BudgetSummary? summary;
  bool loading = true;
  String? error;

  Future<void> load({int? year}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final y = year ?? DateTime.now().year;
      summary = await _svc.fetch(uid, y);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

