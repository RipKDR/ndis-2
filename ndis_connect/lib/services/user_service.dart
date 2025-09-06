import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class UserService {
  static const _boxName = 'user_profile_box';
  final _db = FirebaseFirestore.instance;

  Future<UserProfile?> getLocal(String uid) async {
    final box = await Hive.openBox<String>(_boxName);
    final raw = box.get(uid);
    if (raw == null) return null;
    return UserProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLocal(UserProfile profile) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(profile.uid, jsonEncode(profile.toMap()));
  }

  Future<UserProfile?> fetchRemote(String uid) async {
    final snap = await _db.collection('users').doc(uid).get(const GetOptions(source: Source.server));
    if (!snap.exists) return null;
    final data = snap.data()!;
    final profile = UserProfile(
      uid: uid,
      role: (data['role'] as String?) ?? '',
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      createdAt: DateTime.tryParse((data['createdAt'] as String?) ?? ''),
    );
    await saveLocal(profile);
    return profile;
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set({
      'displayName': profile.displayName,
      'email': profile.email,
      'role': profile.role,
      'createdAt': (profile.createdAt ?? DateTime.now()).toIso8601String(),
    }, SetOptions(merge: true));
    await saveLocal(profile);
    return profile;
  }
}

