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

  @override
  Widget build(BuildContext context) {
    // in this screen the user can see the trip details
    // the trip details will include the trip date, the trip distance, the trip duration, the trip cost, and the trip path on the map
    // also the user can see the passenger details, his name and his phone number

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
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
              top: 5,
              left: 5,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            //trip date
            Positioned(
              top: 5,
              left: 50,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Trip Date: ${DateFormat('EEE, d/M/y').format(widget.endedTripDetails.tripDate!)}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 5,
              left: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Column(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                            widget.endedTripDetails.driverInfo!['photoUrl']),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.endedTripDetails.driverInfo!['displayName'],
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ]),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        Image.asset('assets/images/pin_map_start_position.png',
                            width: 40, height: 40),
                        const SizedBox(height: 10),
                        // line between the two pins
                        Container(
                          height: 50,
                          width: 2,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                        ),
                        const SizedBox(height: 10),
                        Image.asset(
                          'assets/images/pin_map_destination.png',
                          width: 40,
                          height: 40,
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // source address
                          Text(
                            widget.endedTripDetails.pickUpLocationAddress!,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // duration and fare amount
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1),
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_rounded),
                                    const SizedBox(width: 5),
                                    Text(
                                      tripDuration,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.attach_money),
                                    const SizedBox(width: 5),
                                    Text(
                                      tripCost,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // destination address
                          Text(
                            widget.endedTripDetails.dropOffLocationAddress!,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
