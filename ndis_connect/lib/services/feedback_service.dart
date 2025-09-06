import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  final _db = FirebaseFirestore.instance;

  Future<void> submitFeedback(String uid, String message, {int? rating}) async {
    await _db.collection('feedback').doc(uid).collection('items').add({
      'message': message,
      'rating': rating,
      'ts': FieldValue.serverTimestamp(),
    });
  }
}

