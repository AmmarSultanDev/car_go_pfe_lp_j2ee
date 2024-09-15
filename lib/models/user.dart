import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/servicecontrol/v2.dart';

class User {
  String uid;
  final String displayName;
  final String phoneNumber;
  final String email;
  bool isBlocked;

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
    this.isBlocked = false,
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

  updatePassword(String newPassword) async {
    // Update password
    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  updateEmail(String newEmail) async {
    // Update email
    try {
      await FirebaseAuth.instance.currentUser!
          .verifyBeforeUpdateEmail(newEmail);
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  updateProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    // Update profile
    try {
      if (displayName != null && phoneNumber != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'displayName': displayName,
          'phoneNumber': phoneNumber,
        });
      } else if (displayName != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'displayName': displayName,
        });
      } else if (phoneNumber != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'phoneNumber': phoneNumber,
        });
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
