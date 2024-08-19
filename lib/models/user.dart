import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String uid;
  final String displayName;
  final String phoneNumber;
  final String email;
  bool isBlocked = false;

  User({
    required this.uid,
    required this.displayName,
    required this.phoneNumber,
    required this.email,
    this.isBlocked = false,
  });

  User.withoutUid({
    required this.displayName,
    required this.phoneNumber,
    required this.email,
  }) : uid = '';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'email': email,
        'isBlocked': isBlocked,
      };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'], // Add the 'uid' named parameter here
      displayName: snapshot['displayName'],
      phoneNumber: snapshot['phoneNumber'],
      email: snapshot['email'],
      isBlocked: snapshot['isBlocked'],
    );
  }
}
