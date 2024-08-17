import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
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

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'userphone': userphone,
        'email': email,
      };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'],
      username: snapshot['username'],
      userphone: snapshot['userphone'],
      email: snapshot['email'],
      password: snapshot['password'],
    );
  }

  set uid(String value) {
    uid = value;
  }
}
