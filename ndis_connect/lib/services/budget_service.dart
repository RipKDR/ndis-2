import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';

class BudgetService {
  final _db = FirebaseFirestore.instance;

  String _box(String uid, int year) => 'budget_${uid}_$year';

  Future<BudgetSummary?> fetch(String uid, int year) async {
    try {
      final doc = await _db.collection('plans').doc(uid).collection('years').doc('$year').get(const GetOptions(source: Source.server));
      if (!doc.exists) return null;
      final data = doc.data()!;
      final summary = BudgetSummary(
        uid: uid,
        year: year,
        core: (data['core'] as num).toDouble(),
        capacity: (data['capacity'] as num).toDouble(),
        capital: (data['capital'] as num).toDouble(),
        spentCore: (data['spentCore'] as num).toDouble(),
        spentCapacity: (data['spentCapacity'] as num).toDouble(),
        spentCapital: (data['spentCapital'] as num).toDouble(),
      );
      await _saveCache(summary);
      return summary;
    } catch (_) {
      return _readCache(uid, year);
    }
  }

  Future<void> _saveCache(BudgetSummary s) async {
    final box = await Hive.openBox<String>(_box(s.uid, s.year));
    await box.put('summary', jsonEncode(s.toMap()));
  }

  BudgetSummary? _readCache(String uid, int year) {
    final name = _box(uid, year);
    if (!Hive.isBoxOpen(name)) return null;
    final box = Hive.box<String>(name);
    final raw = box.get('summary');
    if (raw == null) return null;
    return BudgetSummary.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }
}

