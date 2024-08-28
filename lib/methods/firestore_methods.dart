import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> makeTripRequest(
      Address pickUpAddress, Address dropOffAddress) async {
    model.User? currentUser = await AuthMethods().getUserDetails();
    Uuid uuid = const Uuid();
    String requestId = uuid.v4();

    Map<String, dynamic> userInfo = currentUser == null
        ? {}
        : {
            'uid': currentUser.uid,
            'displayName': currentUser.displayName,
            'phoneNumber': currentUser.phoneNumber,
            'email': currentUser.email,
          };

    Map<String, dynamic> destinationDriverCoordinates = {
      'latitude': '',
      'longitude': '',
    };

    Map<String, dynamic> driverInfo = {
      'uid': '',
      'displayName': '',
      'phoneNumber': '',
      'photoUrl': '',
      'email': '',
      'carModel': '',
      'carColor': '',
      'carPlateNumber': '',
      'destinationCoordinates': destinationDriverCoordinates,
    };

    Map pickUpLocationCoordinates = {
      'latitude': pickUpAddress.latitude.toString(),
      'longitude': pickUpAddress.longitude.toString(),
    };

    Map dropOffLocationCoordinates = {
      'latitude': dropOffAddress.latitude.toString(),
      'longitude': dropOffAddress.longitude.toString(),
    };

    try {
      await _firestore.collection('tripRequests').doc(requestId).set({
        'passengerInfo': userInfo,
        'pickUpLocationCoordinates': pickUpLocationCoordinates,
        'dropOffLocationCoordinates': dropOffLocationCoordinates,
        'pickUpAddress': pickUpAddress.placeName ?? '',
        'dropOffAddress': dropOffAddress.placeName ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        // when trip request got accepted by a driver
        'driverInfo': driverInfo,
        'fareAmount': '',
      });
    } catch (e) {
      requestId = '';
      print(e);
    }

    return requestId;
  }

  Future<void> cancelTripRequest(String requestId) async {
    try {
      await _firestore.collection('tripRequests').doc(requestId).delete();
    } catch (e) {
      print(e);
    }
  }
}
