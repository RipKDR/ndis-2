import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderService {
  final _db = FirebaseFirestore.instance;
  static const _box = 'providers_cache';

  Future<List<ServiceProviderModel>> fetchAll() async {
    try {
      final snap = await _db.collection('providers').limit(200).get(const GetOptions(source: Source.server));
      final list = snap.docs
          .map((d) => ServiceProviderModel.fromMap({...d.data(), 'id': d.id}))
          .toList();
      await _save(list);
      return list;
    } catch (_) {
      return _read();
    }
  }

  Future<void> _save(List<ServiceProviderModel> list) async {
    final box = await Hive.openBox<String>(_box);
    await box.put('all', jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  List<ServiceProviderModel> _read() {
    if (!Hive.isBoxOpen(_box)) return [];
    final box = Hive.box<String>(_box);
    final raw = box.get('all');
    if (raw == null) return [];
    final arr = (jsonDecode(raw) as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return arr.map(ServiceProviderModel.fromMap).toList();
  }
}

