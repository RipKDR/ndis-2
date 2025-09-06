import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String _eventsBoxName(String uid) => 'events_cache_$uid';
  String _opsBoxName(String uid) => 'events_ops_$uid';

  Future<List<EventModel>> fetchMonth(String uid, int year, int month) async {
    // Time range for month
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    try {
      final q = await _db
          .collection('schedules')
          .doc(uid)
          .collection('events')
          .where('start', isLessThanOrEqualTo: end.toIso8601String())
          .where('end', isGreaterThanOrEqualTo: start.toIso8601String())
          .get(const GetOptions(source: Source.server));
      final events = q.docs.map((d) => EventModel.fromMap({
            ...d.data(),
            'id': d.id,
          })).toList();
      await _saveCache(uid, events);
      return events;
    } catch (_) {
      // Offline or failed: fall back to cache
      return _readCache(uid).where((e) =>
          (e.start.isBefore(end) || e.start.isAtSameMomentAs(end)) &&
          (e.end.isAfter(start) || e.end.isAtSameMomentAs(start))).toList();
    }
  }

  Future<EventModel> create(String uid, EventModel e, {bool enqueueIfOffline = true}) async {
    final id = e.id.isEmpty ? _uuid.v4() : e.id;
    final data = {
      ...e.toMap(),
      'id': id,
    };
    try {
      await _db.collection('schedules').doc(uid).collection('events').doc(id).set(data);
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {'op': 'create', 'data': data});
      } else {
        rethrow;
      }
    }
    await _upsertCache(uid, EventModel.fromMap(data));
    return EventModel.fromMap(data);
  }

  Future<void> update(String uid, EventModel e, {bool enqueueIfOffline = true}) async {
    try {
      await _db.collection('schedules').doc(uid).collection('events').doc(e.id).set(e.toMap(), SetOptions(merge: true));
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {'op': 'update', 'data': e.toMap()});
      } else {
        rethrow;
      }
    }
    await _upsertCache(uid, e);
  }

  Future<void> delete(String uid, String id, {bool enqueueIfOffline = true}) async {
    try {
      await _db.collection('schedules').doc(uid).collection('events').doc(id).delete();
    } catch (_) {
      if (enqueueIfOffline) {
        await _enqueue(uid, {'op': 'delete', 'id': id});
      } else {
        rethrow;
      }
    }
    await _deleteCache(uid, id);
  }

  Future<void> processQueue(String uid) async {
    final box = await Hive.openBox<String>(_opsBoxName(uid));
    final ops = (box.get('ops') != null)
        ? (jsonDecode(box.get('ops')!) as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    if (ops.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final op in ops) {
      try {
        switch (op['op']) {
          case 'create':
            await _db
                .collection('schedules')
                .doc(uid)
                .collection('events')
                .doc((op['data'] as Map)['id'] as String)
                .set(Map<String, dynamic>.from(op['data'] as Map));
            break;
          case 'update':
            await _db
                .collection('schedules')
                .doc(uid)
                .collection('events')
                .doc((op['data'] as Map)['id'] as String)
                .set(Map<String, dynamic>.from(op['data'] as Map), SetOptions(merge: true));
            break;
          case 'delete':
            await _db
                .collection('schedules')
                .doc(uid)
                .collection('events')
                .doc(op['id'] as String)
                .delete();
            break;
        }
      } catch (_) {
        remaining.add(op); // keep for next retry
      }
    }
    await box.put('ops', jsonEncode(remaining));
  }

  // Cache helpers
  Future<void> _saveCache(String uid, List<EventModel> events) async {
    final box = await Hive.openBox<String>(_eventsBoxName(uid));
    final map = {for (var e in events) e.id: jsonEncode(e.toMap())};
    await box.putAll(map);
  }

  Future<void> _upsertCache(String uid, EventModel e) async {
    final box = await Hive.openBox<String>(_eventsBoxName(uid));
    await box.put(e.id, jsonEncode(e.toMap()));
  }

  Future<void> _deleteCache(String uid, String id) async {
    final box = await Hive.openBox<String>(_eventsBoxName(uid));
    await box.delete(id);
  }

  List<EventModel> _readCache(String uid) {
    final box = Hive.isBoxOpen(_eventsBoxName(uid)) ? Hive.box<String>(_eventsBoxName(uid)) : null;
    if (box == null) return [];
    return box.values.map((s) => EventModel.fromMap(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> _enqueue(String uid, Map<String, dynamic> op) async {
    final box = await Hive.openBox<String>(_opsBoxName(uid));
    final current = box.get('ops');
    final list = current == null ? <Map<String, dynamic>>[] : (jsonDecode(current) as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    list.add(op);
    await box.put('ops', jsonEncode(list));
  }
}
