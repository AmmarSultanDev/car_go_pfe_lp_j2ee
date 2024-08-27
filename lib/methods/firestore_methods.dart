import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  makeTripRequest(Address pickUpAddress, Address dropOffAddress) async {
    model.User? currentUser = await AuthMethods().getUserDetails();

    Map<String, dynamic> userInfo = currentUser == null
        ? {}
        : {
            'uid': currentUser.uid,
            'displayName': currentUser.displayName,
            'phoneNumber': currentUser.phoneNumber,
            'email': currentUser.email,
          };

    Map pickUpLocationCoordinates = {
      'latitude': pickUpAddress.latitude.toString(),
      'longitude': pickUpAddress.longitude.toString(),
    };

    Map dropOffLocationCoordinates = {
      'latitude': dropOffAddress.latitude.toString(),
      'longitude': dropOffAddress.longitude.toString(),
    };

    Uuid uuid = const Uuid();

    try {
      await _firestore.collection('trip_requests').doc(uuid.v4()).set({
        'passenger_info': userInfo,
        'pick_up_location_coordinates': pickUpLocationCoordinates,
        'drop_off_location_coordinates': dropOffLocationCoordinates,
        'pick_up_address': pickUpAddress.placeName,
        'drop_off_address': dropOffAddress.placeName,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(e);
    }
  }
}
