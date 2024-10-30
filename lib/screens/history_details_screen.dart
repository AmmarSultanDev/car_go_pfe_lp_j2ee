import 'dart:async';

import 'package:car_go_pfe_lp_j2ee/global/global_var.dart';
import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/map_theme_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/direction_details.dart';
import 'package:car_go_pfe_lp_j2ee/models/trip_details.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryDetailsScreen extends StatefulWidget {
  const HistoryDetailsScreen({super.key, required this.endedTripDetails});

  final TripDetails endedTripDetails;

  @override
  State<HistoryDetailsScreen> createState() => _HistoryDetailsScreenState();
}

class _HistoryDetailsScreenState extends State<HistoryDetailsScreen> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();

  GoogleMapController? googleMapController;

  PolylinePoints polylinePoints = PolylinePoints();

  List<LatLng> polylineCoordinates = [];

  Set<Marker> markerSet = {};

  Set<Polyline> polylineSet = {};

  Set<Circle> circleSet = {};

  String tripDistance = '';

  String tripDuration = '';

  String tripCost = '';

  DirectionDetails? tripDetailsInfo;

  setTripInfo() {
    setState(() {
      tripDistance = tripDetailsInfo?.distanceText ?? '';
      tripDuration = tripDetailsInfo?.durationText ?? '';

      tripCost = widget.endedTripDetails.fareAmount ?? '0';

      // Calculate the actual trip duration
      // if (widget.endedTripDetails.startedAt != null &&
      //     widget.endedTripDetails.endedAt != null) {
      //   Duration duration = widget.endedTripDetails.endedAt!
      //       .difference(widget.endedTripDetails.startedAt!);
      //   actualTripDuration = formatDuration(duration);
      //   if (kDebugMode) {
      //     print('Actual trip duration: $actualTripDuration');
      //   }
      // }
    });
  }

  drawRoute(LatLng start, LatLng end) async {
    showDialog(
      context: context,
      builder: (context) => const LoadingDialog(
        messageText: 'Please wait...',
      ),
    );

    tripDetailsInfo =
        await CommonMethods.getDirectionDetailsFromApi(start, end);

    if (mounted) Navigator.pop(context);

    setTripInfo();

    List<PointLatLng> latlngPoints =
        polylinePoints.decodePolyline(tripDetailsInfo!.encodedPoints!);

    polylineCoordinates.clear();

    if (latlngPoints.isNotEmpty) {
      for (var point in latlngPoints) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    // draw polyline
    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId('polylineId'),
        color: Colors.blue,
        points: polylineCoordinates,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });
    // fit polyline into the map
    LatLngBounds latLngBounds;

    if (start.latitude > end.latitude && start.longitude > end.longitude) {
      latLngBounds = LatLngBounds(southwest: end, northeast: start);
    } else if (start.longitude > end.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(start.latitude, end.longitude),
        northeast: LatLng(end.latitude, start.longitude),
      );
    } else if (start.latitude > end.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(end.latitude, start.longitude),
        northeast: LatLng(start.latitude, end.longitude),
      );
    } else {
      latLngBounds = LatLngBounds(southwest: start, northeast: end);
    }

    googleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    //add marker
    Marker startMarker = Marker(
      markerId: const MarkerId('startMarkerId'),
      position: start,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow:
          InfoWindow(title: widget.endedTripDetails.pickUpLocationAddress),
    );

    Marker endMarker = Marker(
      markerId: const MarkerId('endMarkerId'),
      position: end,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow:
          InfoWindow(title: widget.endedTripDetails.dropOffLocationAddress),
    );

    setState(() {
      markerSet.add(startMarker);
      markerSet.add(endMarker);
    });

    //add cicrle
    Circle startCircle = Circle(
      circleId: const CircleId('startCircleId'),
      radius: 12,
      center: start,
      strokeColor: Colors.green,
      fillColor: Colors.green,
    );

    Circle endCircle = Circle(
      circleId: const CircleId('endCircleId'),
      radius: 12,
      center: end,
      strokeColor: Colors.red,
      fillColor: Colors.red,
    );

    setState(() {
      circleSet.add(startCircle);
      circleSet.add(endCircle);
    });
  }

  Widget build(BuildContext context) {
    // in this screen the user can see the trip details
    // the trip details will include the trip date, the trip distance, the trip duration, the trip cost, and the trip path on the map
    // also the user can see the passenger details, his name and his phone number

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('History Details'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: const EdgeInsets.only(top: 100),
            initialCameraPosition: casablancaInitialPosition,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            markers: markerSet,
            circles: circleSet,
            polylines: polylineSet,
            onMapCreated: (GoogleMapController mapController) async {
              googleMapController = mapController;
              MapThemeMethods().updateMapTheme(googleMapController!, context);

              googleMapCompleterController.complete(googleMapController);

              await drawRoute(
                  widget.endedTripDetails.pickUpLocationCoordinates!,
                  widget.endedTripDetails.dropOffLocationCoordinates!);
            },
          ),
          Positioned(
            bottom: 30,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87.withOpacity(0.2)),
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Date: ${DateFormat('yyyy-MM-dd – kk:mm').format(widget.endedTripDetails.tripDate!)}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Trip Distance: $tripDistance',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  // Add more Text widgets for other trip details
                  Text(
                    'Estimated Duration: $tripDuration',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  Text(
                    'Trip Cost: \$$tripCost',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
