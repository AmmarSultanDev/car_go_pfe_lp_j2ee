import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkBlockStatus(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      return userDoc['isBlocked'] as bool;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
