import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String uid;
  final String username;
  final String userphone;
  final String email;
  final String password;

  User({
    required this.uid,
    required this.username,
    required this.userphone,
    required this.email,
    required this.password,
  });

  User.withoutUid({
    required this.username,
    required this.userphone,
    required this.email,
    required this.password,
  }) : uid = '';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'userphone': userphone,
        'email': email,
      };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'], // Add the 'uid' named parameter here
      username: snapshot['username'],
      userphone: snapshot['userphone'],
      email: snapshot['email'],
      password: snapshot['password'],
    );
  }
}
