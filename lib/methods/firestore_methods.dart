import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:car_go_pfe_lp_j2ee/models/driver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> makeTripRequest(
      Address pickUpAddress, Address dropOffAddress) async {
    model.User? currentUser = await AuthMethods().getUserDetails();
    Uuid uuid = const Uuid();
    String requestId = uuid.v4();

    // ignore: unnecessary_null_comparison
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
      'vehiculeModel': '',
      'vehiculeColor': '',
      'vehiculePlateNumber': '',
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

    Map driverLocation = {
      'latitude': '',
      'longitude': '',
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
        'driverLocation': driverLocation,
        'fareAmount': '',
      });
    } catch (e) {
      requestId = '';
      if (kDebugMode) {
        print(e);
      }
    }

    return requestId;
  }

  Future<void> cancelTripRequest(String requestId) async {
    try {
      await _firestore.collection('tripRequests').doc(requestId).delete();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<Driver?> getDriver(String driverUid) async {
    Driver? driver;
    try {
      DocumentSnapshot driverSnapshot =
          await _firestore.collection('drivers').doc(driverUid).get();

      if (driverSnapshot.exists) {
        driver = Driver.fromSnap(driverSnapshot);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return driver;
  }

  updateTripRequestStatus(String requestId, String status) async {
    try {
      await _firestore
          .collection('tripRequests')
          .doc(requestId)
          .update({'status': status});
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<String> getDriverDeviceToken(String driverUid) async {
    String deviceToken = '';

    try {
      await _firestore.collection('tokens').doc(driverUid).get().then((doc) {
        if (doc.exists) {
          deviceToken = doc.data()!['devices'][0]['token'];
        }
      });
    } on Error catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return deviceToken;
  }
}
