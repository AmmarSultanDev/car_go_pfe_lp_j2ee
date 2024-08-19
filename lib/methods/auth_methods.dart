import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot snap =
        await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(snap);
  }

  Future<String> signupUser({
    required String email,
    required String password,
    required String username,
    required String userphone,
  }) async {
    // Register user
    String res = 'Some error occured';

    try {
      if (username.isNotEmpty &&
          userphone.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        if (userCredential.user != null) {
          model.User user = model.User(
            uid: userCredential.user!.uid,
            displayName: username,
            phoneNumber: userphone,
            email: email,
          );
          // Save user data to Firestore
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(user.toJson());
        }
        res = 'Success';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        res = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        res = 'The account already exists for that email.';
      }
    } on Exception catch (e) {
      res = e.toString();
    }
    return res;
  }

  // signin user
  Future<String> signinUser({
    required String email,
    required String password,
  }) async {
    String res = 'Some error occured';
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        if (userCredential.user != null) {
          res = 'Success';
        }
      } else {
        res = 'Please fill all the fields';
      }
    } catch (err) {
      if (err is FirebaseAuthException) {
        print('FirebaseAuthException code: ${err.code}');
        if (err.code == 'invalid-credential') {
          res = 'Invalid credentials provided.';
        }
      } else {
        res = err.toString();
      }
    }
    return res;
  }

  // signout user
  Future<void> signoutUser() async {
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
  }
}
