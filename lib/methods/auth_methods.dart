import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> signupUser(model.User user) async {
    // Register user
    String res = 'Some error occured';

    try {
      if (user.username.isNotEmpty &&
          user.userphone.isNotEmpty &&
          user.email.isNotEmpty &&
          user.password.isNotEmpty) {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
                email: user.email, password: user.password);
        print(userCredential.user!.uid);
        if (userCredential.user != null) {
          // set the user uid to the user object
          user.uid = userCredential.user!.uid;
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
}
