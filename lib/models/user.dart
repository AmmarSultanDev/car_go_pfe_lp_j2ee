import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String uid;
  final String username;
  final String userphone;
  final String email;
  bool isBlocked = false;

  User({
    required this.uid,
    required this.username,
    required this.userphone,
    required this.email,
    this.isBlocked = false,
  });

  User.withoutUid({
    required this.username,
    required this.userphone,
    required this.email,
  }) : uid = '';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'userphone': userphone,
        'email': email,
        'isBlocked': isBlocked,
      };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'], // Add the 'uid' named parameter here
      username: snapshot['username'],
      userphone: snapshot['userphone'],
      email: snapshot['email'],
      isBlocked: snapshot['isBlocked'],
    );
  }
}
