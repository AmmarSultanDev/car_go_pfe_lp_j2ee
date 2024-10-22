import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetails {
  String? tripId;
  LatLng? pickUpLocationCoordinates;
  LatLng? dropOffLocationCoordinates;

  String? pickUpLocationAddress;
  String? dropOffLocationAddress;

  Map<String, dynamic>? driverInfo;
  String? fareAmount;

  DateTime? tripDate;

  TripDetails({
    this.tripId,
    this.pickUpLocationCoordinates,
    this.dropOffLocationCoordinates,
    this.pickUpLocationAddress,
    this.dropOffLocationAddress,
    this.driverInfo,
    this.fareAmount,
    this.tripDate,
  });

  TripDetails.fromSnapShot(Map<String, dynamic> snapshot) {
    double dropOffLat = double.parse(
        snapshot['dropOffLocationCoordinates']['latitude'].toString());
    double dropOffLng = double.parse(
        snapshot['dropOffLocationCoordinates']['longitude'].toString());

    LatLng dropOffLocationCoordinatesLatLng = LatLng(dropOffLat, dropOffLng);

    dropOffLocationCoordinates = dropOffLocationCoordinatesLatLng;

    double pickUpLat = double.parse(
        snapshot['pickUpLocationCoordinates']['latitude'].toString());
    double pickUpLng = double.parse(
        snapshot['pickUpLocationCoordinates']['longitude'].toString());

    LatLng pickUpLocationCoordinatesLatLng = LatLng(pickUpLat, pickUpLng);

    pickUpLocationCoordinates = pickUpLocationCoordinatesLatLng;

    driverInfo = snapshot['driverInfo'];
    fareAmount = snapshot['fareAmount'];
    pickUpLocationAddress = snapshot['pickUpAddress'];
    dropOffLocationAddress = snapshot['dropOffAddress'];
    tripDate = snapshot['createdAt'].toDate();
  }
}
