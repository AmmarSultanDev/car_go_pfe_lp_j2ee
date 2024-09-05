// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:car_go_pfe_lp_j2ee/global/global_var.dart';
import 'package:car_go_pfe_lp_j2ee/global/trip_var.dart';
import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/firestore_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/manage_drivers_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/push_notification_service.dart';
import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:car_go_pfe_lp_j2ee/models/direction_details.dart';
import 'package:car_go_pfe_lp_j2ee/models/online_nearby_driver.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart';
import 'package:car_go_pfe_lp_j2ee/providers/address_provider.dart';
import 'package:car_go_pfe_lp_j2ee/providers/location_provider.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/screens/about_screen.dart';
import 'package:car_go_pfe_lp_j2ee/screens/search_screen.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/info_dialog.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/payment_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();

  GoogleMapController? controllerGoogleMap;

  Position? currentPositionOfUser;

  CommonMethods commonMethods = const CommonMethods();

  FirestoreMethods firestoreMethods = FirestoreMethods();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  double searchContainerHeight = 276;

  double onTripContainerHeight = 0;

  double bottomMapPadding = 100;

  double rideDetailsContainerHeight = 0;

  double requestRideContainerHeight = 0;

  LatLng? positionOfUserInLatLng;

  DirectionDetails? tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];

  Set<Polyline> polyLineSet = {};

  Set<Marker> allMarkersSet = {};

  Set<Marker> pinMarkersSet = {};
  Set<Marker> driverMarkersSet = {};

  Set<Circle> circleSet = {};

  bool onDirections = false;

  String stateOfApp = 'normal';

  bool nearbyOnlineDriversAvailable = false;

  BitmapDescriptor? nearbyOnlineDriverIcon;

  String requestId = '';

  Address? pickUpLocation;
  Address? dropOffLocation;

  DocumentReference? tripRequestRef;

  Timer? timer;

  List<OnlineNearbyDriver>? availableNearbyOnlineDriversList;

  bool requestAlreadyAccepted = false;

  bool driverAlreadyArrived = false;

  bool tripStarted = false;

  bool tripEnded = false;

  bool tripCanceled = false;

  String durationText = '';

  LatLng driverCurrentLocation = const LatLng(0, 0);

  LatLngBounds? latLngBounds;

  makeDriverIcon() {
    if (nearbyOnlineDriverIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(38, 38));
      BitmapDescriptor.asset(
              imageConfiguration, 'assets/images/pin_map_tracking.png')
          .then((value) {
        nearbyOnlineDriverIcon = value;
      });
    }
  }

  void updateMapTheme(GoogleMapController controller, BuildContext context) {
    String mapStylePath = Theme.of(context).brightness == Brightness.dark
        ? 'themes/night_style.json'
        : 'themes/standard_style.json';
    getJsonFileFromThemes(mapStylePath)
        .then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    // ignore: deprecated_member_use
    controller.setMapStyle(googleMapStyle);
  }

  getCurrentLiveLocationOfUser(BuildContext context) async {
    // Check if location permissions are granted
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // Handle the case where permission is not granted
        return;
      }
    }

    // Get the current position of the user initially
    Position initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    // Update the LocationProvider with the initial position
    Provider.of<LocationProvider>(context, listen: false)
        .setCurrentPosition(initialPosition);

    // Retrieve the current position as LatLng
    LatLng initialPositionLatLng = LatLng(
      initialPosition.latitude,
      initialPosition.longitude,
    );

    // Optional: Convert geo-coordinates to an address for the initial position
    if (mounted) {
      await CommonMethods.convertGeoCodeToAddress(
        initialPositionLatLng.latitude,
        initialPositionLatLng.longitude,
        context,
      );
    }

    // Update the map's camera position to the user's initial location
    CameraPosition cameraPosition = CameraPosition(
      target: initialPositionLatLng,
      zoom: 14.4746,
    );

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    // // Start listening to the position stream for continuous updates
    // currentPositionStream = Geolocator.getPositionStream(
    //   locationSettings: const LocationSettings(
    //     accuracy: LocationAccuracy.bestForNavigation,
    //     distanceFilter: 10, // Minimum distance (in meters) before an update
    //   ),
    // ).listen((Position position) {
    //   // Update the LocationProvider with the new position
    //   Provider.of<LocationProvider>(context, listen: false)
    //       .setCurrentPosition(position);

    //   // Update the map's camera position to the user's current location
    //   LatLng positionOfUserInLatLng =
    //       LatLng(position.latitude, position.longitude);
    //   CameraPosition cameraPosition = CameraPosition(
    //     target: positionOfUserInLatLng,
    //     zoom: 14.4746,
    //   );

    //   controllerGoogleMap!
    //       .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    //   // Optional: Convert geo-coordinates to an address for each new position
    //   CommonMethods.convertGeoCodeToAddress(
    //     position.latitude,
    //     position.longitude,
    //     context,
    //   );
    // });

    // Initialize any GeoFire listeners, if needed
    await initializeGeoFireListener();
  }

  // signout
  signout() async {
    await AuthMethods().signoutUser();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    currentPositionStream?.cancel();
    super.dispose();
  }

  retrieveDirectionDetails() async {
    var pickUpLocation =
        Provider.of<AddressProvider>(context, listen: false).pickUpAddress;
    var dropOffLocation =
        Provider.of<AddressProvider>(context, listen: false).dropOffAddress;

    var pickUpGeographicCoordinates =
        LatLng(pickUpLocation!.latitude!, pickUpLocation.longitude!);
    var dropOffGeographicCoordinates =
        LatLng(dropOffLocation!.latitude!, dropOffLocation.longitude!);

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) =>
            const LoadingDialog(messageText: 'Getting direction ...'));

    // send request to Directions API
    var detailsFromDirectionApi =
        await CommonMethods.getDirectionDetailsFromApi(
      pickUpGeographicCoordinates,
      dropOffGeographicCoordinates,
    );

    if (mounted) Navigator.of(context).pop();

    setState(() {
      tripDirectionDetails = detailsFromDirectionApi;
    });

    // draw route between the pick up and drop off locations
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination =
        polylinePoints.decodePolyline(tripDirectionDetails!.encodedPoints!);

    pLineCoordinates.clear();

    if (latLngPointsFromPickUpToDestination.isNotEmpty) {
      for (var latLngPoint in latLngPointsFromPickUpToDestination) {
        pLineCoordinates
            .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
      }
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
          polylineId: const PolylineId('PolyLineId'),
          color: Theme.of(context).primaryColor,
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

      polyLineSet.add(polyline);
    });

    // fit the route into the map
    LatLngBounds latLngBounds;
    if (pickUpGeographicCoordinates.latitude >
            dropOffGeographicCoordinates.latitude &&
        pickUpGeographicCoordinates.longitude >
            dropOffGeographicCoordinates.longitude) {
      latLngBounds = LatLngBounds(
        southwest: dropOffGeographicCoordinates,
        northeast: pickUpGeographicCoordinates,
      );
    } else if (pickUpGeographicCoordinates.longitude >
        dropOffGeographicCoordinates.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(
          pickUpGeographicCoordinates.latitude,
          dropOffGeographicCoordinates.longitude,
        ),
        northeast: LatLng(
          dropOffGeographicCoordinates.latitude,
          pickUpGeographicCoordinates.longitude,
        ),
      );
    } else if (pickUpGeographicCoordinates.latitude >
        dropOffGeographicCoordinates.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(
          dropOffGeographicCoordinates.latitude,
          pickUpGeographicCoordinates.longitude,
        ),
        northeast: LatLng(
          pickUpGeographicCoordinates.latitude,
          dropOffGeographicCoordinates.longitude,
        ),
      );
    } else {
      latLngBounds = LatLngBounds(
        southwest: pickUpGeographicCoordinates,
        northeast: dropOffGeographicCoordinates,
      );
    }

    controllerGoogleMap!.animateCamera(
      CameraUpdate.newLatLngBounds(latLngBounds, 70),
    );

    // add pick up and drop off markers

    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId('pickUpPointMarkerId'),
      position: pickUpGeographicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: pickUpLocation.placeName,
        snippet: 'My Location',
      ),
    );

    Marker dropOffPointMarker = Marker(
      markerId: const MarkerId('dropOffPointMarkerId'),
      position: dropOffGeographicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: dropOffLocation.placeName,
        snippet: 'DropOff Location',
      ),
    );

    setState(() {
      pinMarkersSet.add(pickUpPointMarker);
      pinMarkersSet.add(dropOffPointMarker);
    });

    // add pick up and drop off circles

    Circle pickUpPointCircle = Circle(
      circleId: const CircleId('pickUpPointCircleId'),
      strokeColor: Colors.green,
      strokeWidth: 4,
      radius: 2,
      center: pickUpGeographicCoordinates,
      fillColor: Colors.green,
    );

    Circle dropOffPointCircle = Circle(
      circleId: const CircleId('dropOffPointCircleId'),
      strokeColor: Colors.red,
      strokeWidth: 4,
      radius: 2,
      center: dropOffGeographicCoordinates,
      fillColor: Colors.red,
    );

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffPointCircle);
      allMarkersSet = {}
        ..addAll(pinMarkersSet)
        ..addAll(driverMarkersSet);
    });
  }

  displayRideDetailsContainer() async {
    await retrieveDirectionDetails();
    // draw route between the two locations
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 280;
      bottomMapPadding = 290;
      onDirections = true;
    });

    pickUpLocation =
        Provider.of<AddressProvider>(context, listen: false).pickUpAddress;
    dropOffLocation =
        Provider.of<AddressProvider>(context, listen: false).dropOffAddress;
  }

  void clearTheMap() {
    setState(() {
      searchContainerHeight = 276;
      onTripContainerHeight = 0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomMapPadding = 100;
      onDirections = false;
      polyLineSet.clear();
      pinMarkersSet.clear();
      circleSet.clear();
      pLineCoordinates.clear();
      allMarkersSet.clear();

      status = '';
      nameDriver = '';
      photoDriver = '';
      phoneNumberDriver = null;
      carDetailsDriver = '';
      tripStatusDisplay = 'Driver is Arriving';
    });
  }

  cancelRideRequest() async {
    await firestoreMethods.cancelTripRequest(requestId);

    setState(() {
      stateOfApp = 'normal';
      requestId = '';
    });
  }

  displayRequestingRideContainer() async {
    fareAmount = commonMethods.calculateFareAmount(tripDirectionDetails!);
    // start new tripRequest
    requestId = await firestoreMethods.makeTripRequest(
        pickUpLocation!, dropOffLocation!, fareAmount.toString());

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 200;
      bottomMapPadding = 200;
      onDirections = false;
    });
  }

  updateAvailableNearbyOnlineDriversOnMap() {
    if (mounted) {
      setState(() {
        driverMarkersSet.clear();
      });
    }

    for (OnlineNearbyDriver eachOnlineNearbyDriver
        in ManageDriversMethods.nearbyOnlineDriversList) {
      LatLng driverCurrentPosition = LatLng(
          eachOnlineNearbyDriver.latitude!, eachOnlineNearbyDriver.longitude!);

      Marker driverMarker = Marker(
        markerId: MarkerId(eachOnlineNearbyDriver.uidDriver!),
        position: driverCurrentPosition,
        icon: nearbyOnlineDriverIcon!,
      );
      driverMarkersSet.add(driverMarker);
    }
    if (mounted) {
      setState(() {
        allMarkersSet = {}
          ..addAll(pinMarkersSet)
          ..addAll(driverMarkersSet);
      });
    }
  }

  initializeGeoFireListener() {
    Geofire.initialize('onlineDrivers');
    currentPositionOfUser =
        Provider.of<LocationProvider>(context, listen: false).currentPosition;
    Geofire.queryAtLocation(currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude, 22)!
        .listen((driverEvent) {
      if (driverEvent != null) {
        var onlineDriverChild = driverEvent['callBack'];

        switch (onlineDriverChild) {
          case Geofire.onKeyEntered:
            OnlineNearbyDriver onlineNearbyDriver = OnlineNearbyDriver();

            onlineNearbyDriver.uidDriver = driverEvent['key'];
            onlineNearbyDriver.latitude = driverEvent['latitude'];
            onlineNearbyDriver.longitude = driverEvent['longitude'];

            ManageDriversMethods.updateDriverLocation(onlineNearbyDriver);

            if (nearbyOnlineDriversAvailable) {
              // update drivers on google map
              updateAvailableNearbyOnlineDriversOnMap();
            }

            break;
          case Geofire.onKeyExited:
            ManageDriversMethods.removeDriverFromList(driverEvent['key']);
            // update drivers on google map

            updateAvailableNearbyOnlineDriversOnMap();

            break;
          case Geofire.onKeyMoved:
            // update nearest online drivers
            OnlineNearbyDriver onlineNearbyDriver = OnlineNearbyDriver();

            onlineNearbyDriver.uidDriver = driverEvent['key'];
            onlineNearbyDriver.latitude = driverEvent['latitude'];
            onlineNearbyDriver.longitude = driverEvent['longitude'];

            ManageDriversMethods.updateDriverLocation(onlineNearbyDriver);

            // update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;
          case Geofire.onGeoQueryReady:
            nearbyOnlineDriversAvailable = true;
            // update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();
            break;
        }
      }
    });
  }

  noDriverAvailable() async {
    await showDialog(
        context: context,
        builder: (context) => const InfoDialog(
            title: 'No Driver Available',
            content:
                'No driver found in the nearby location. Please try again shortly.'));
  }

  sendNotificationToDriver(String currentDriver) async {
    // get driver device token

    String driverDeviceToken =
        await firestoreMethods.getDriverDeviceToken(currentDriver);

    // send push notification to the driver
    PushNotificationService.sendNotificationToSelectedDriver(
        driverDeviceToken, requestId, context);

    const oneTickPerSec = Duration(seconds: 1);

    tripRequestRef =
        FirebaseFirestore.instance.collection('tripRequests').doc(requestId);

    StreamSubscription listener;

    Timer.periodic(oneTickPerSec, (timer) async {
      requestTimeoutDriver--;
      // if not requesting
      if (stateOfApp != 'requesting') {
        // the trip has been canceled

        await firestoreMethods.cancelTripRequest(requestId);
        requestTimeoutDriver = 40;
        // cancel the timer
        timer.cancel();
        return;
      }

      listener =
          tripRequestRef!.snapshots().listen((DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          // The document data will be in snapshot.data()
          tripData = snapshot.data() as Map<String, dynamic>;

          if (tripData['driverLocation'] != null) {
            print(tripData['driverLocation']['latitude'].toString());
            print(tripData['driverLocation']['longitude'].toString());
            double driverLatitude =
                double.parse(tripData['driverLocation']['latitude'].toString());
            double driverLongitude = double.parse(
                tripData['driverLocation']['longitude'].toString());

            driverCurrentLocation = LatLng(driverLatitude, driverLongitude);
          }

          if (tripData['status'] == 'accepted') {
            // driver has accepted the trip request

            // get driver current location

            // the code that should be executed only once

            if (!requestAlreadyAccepted) {
              // driver is coming
              if (mounted) {
                setState(
                  () {
                    stateOfApp = 'accepted';
                    requestRideContainerHeight = 0;
                    onTripContainerHeight = 291;
                    bottomMapPadding = 291;
                    tripStatusDisplay = 'Driver is Arriving';
                  },
                );
              }

              whenRequestAccepted();

              // get driver info
              if (tripData['driverInfo'] != null) {
                nameDriver = tripData['driverInfo']['displayName'];
                photoDriver = tripData['driverInfo']['photoUrl'];
                phoneNumberDriver = tripData['driverInfo']['phoneNumber'];
                carDetailsDriver =
                    '${tripData['driverInfo']['vehiculeColor']} ${tripData['driverInfo']['vehiculeModel']} ${tripData['driverInfo']['vehiculePlateNumber']}';
              }

              // reset the request timeout
              requestTimeoutDriver = 40;

              // stop the geofire listener
              try {
                Geofire.stopListener();
              } on Exception catch (e) {
                print(e);
              }

              if (kDebugMode) {
                print('Driver has accepted the trip request');
              }
              timer.cancel();
            }

            // remove all drivers markers
            driverMarkersSet.clear();

            // add the driver marker
            Marker driverMarker = Marker(
              markerId: const MarkerId('driverMarkerId'),
              position: driverCurrentLocation,
              icon: nearbyOnlineDriverIcon!,
            );

            driverMarkersSet.add(driverMarker);

            setState(() {
              allMarkersSet = {}
                ..addAll(pinMarkersSet)
                ..addAll(driverMarkersSet);
            });

            updateFromDriverCurrentLocationToPickUp(driverCurrentLocation);
            updateTripDetailsInformations(driverCurrentLocation);

            requestAlreadyAccepted = true;
          } else if (tripData['status'] == 'arrived') {
            // driver has arrived
            if (mounted) {
              setState(() {
                stateOfApp = 'driver_arrived';
                tripStatusDisplay = 'Driver has Arrived';
              });
            }

            if (!driverAlreadyArrived) {
              whenDriverArrived();
            }

            updateFromDriverCurrentLocationToDropOffDestination(
                driverCurrentLocation);
            updateTripDetailsInformations(driverCurrentLocation);

            driverAlreadyArrived = true;

            if (kDebugMode) {
              print('Driver has arrived');
            }
            timer.cancel();
          } else if (tripData['status'] == 'canceled_by_driver') {
            // driver has canceled the trip request
            if (mounted) {
              setState(() {
                stateOfApp = 'canceled_by_driver';
              });
            }

            if (!tripCanceled) {
              whenDriverCancelTheTrip();
            }

            tripCanceled = true;

            if (kDebugMode) {
              print('Driver has canceled the trip request');
            }
            timer.cancel();
          } else if (tripData['status'] == 'onTrip') {
            // driver has started the trip
            if (mounted) {
              setState(() {
                stateOfApp = 'on_trip';
                tripStatusDisplay = 'On Trip';
              });
            }

            if (!tripStarted) {
              whenTripStarted();
              updateFromDriverCurrentLocationToDropOffDestination(
                  driverCurrentLocation);
              animateCameraOnTripStarted(latLngBounds!);

              Timer(const Duration(seconds: 3), () {
                // Your callback code here
              });
            }

            updateFromDriverCurrentLocationToDropOffDestination(
                driverCurrentLocation);

            animateCameraOnTrip(driverCurrentLocation);

            updateTripDetailsInformations(driverCurrentLocation);

            tripStarted = true;

            if (kDebugMode) {
              print('Driver has started the trip');
            }
            timer.cancel();
          } else if (tripData['status'] == 'ended') {
            // trip has ended
            if (mounted) {
              setState(() {
                stateOfApp = 'ended';
              });
            }

            if (!tripEnded) {
              whenTripEnded();
            }

            tripEnded = true;

            if (kDebugMode) {
              print('Trip has ended');
            }
            timer.cancel();
          }
        } else {
          // The trip request document doesn't exist anymore
          if (kDebugMode) {
            print('tripRequest not found!');
          }
          requestTimeoutDriver = 40;
          timer.cancel();
          return;
        }
      });

      // if 40 seconds passed
      if (requestTimeoutDriver == 0) {
        timer.cancel();
        requestTimeoutDriver = 40;
        listener.cancel();

        availableNearbyOnlineDriversList!.removeAt(0);

        //send notification to the next driver
        if (availableNearbyOnlineDriversList!.isNotEmpty) {
          await searchDriver();
        } else {
          availableNearbyOnlineDriversList =
              ManageDriversMethods.nearbyOnlineDriversList;
          await firestoreMethods.cancelTripRequest(requestId);
          await noDriverAvailable();
          requestAlreadyAccepted = false;
          clearTheMap();
        }
      }
    });
  }

  whenRequestAccepted() {
    if (stateOfApp == 'accepted') {
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => InfoDialog(
                title: 'Driver is Arriving',
                content:
                    'Your driver ${tripData['driverInfo']['displayName']} on a ${tripData['driverInfo']['vehiculeColor']} ${tripData['driverInfo']['vehiculeModel']} is on his/her way to pick you up. \n Please wait for the driver to arrive.'));
      }
    }
  }

  whenDriverArrived() {
    if (stateOfApp == 'driver_arrived') {
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => InfoDialog(
                title: 'Driver has Arrived',
                content:
                    'Your driver ${tripData['driverInfo']['displayName']} has arrived at your location. \n Please get in the car.'));
      }
    }
  }

  whenTripStarted() {
    if (stateOfApp == 'on_trip') {
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => const InfoDialog(
                title: 'Trip Started',
                content:
                    'Your trip has started. \n You are now on your way to your destination.'));
      }
    }
  }

  whenTripEnded() {
    if (stateOfApp == 'ended') {
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => PaymentDialog(
                  tripId: requestId,
                ));
      }
    }
    setState(() {
      stateOfApp = 'normal';
    });
    clearTheMap();
  }

  whenDriverCancelTheTrip() {
    if (stateOfApp == 'canceled_by_driver') {
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => const InfoDialog(
                title: 'Driver Canceled the Trip',
                content:
                    'The driver has canceled the trip. \n Please try again shortly.'));
      }
    }

    clearTheMap();

    setState(() {
      stateOfApp = 'normal';
    });
  }

  updateFromDriverCurrentLocationToPickUp(LatLng driverCurrentLocation) async {
    // Log the driver's current location
    print(driverCurrentLocation.toJson());

    // Retrieve pickup location coordinates
    var pickUpLocation =
        Provider.of<AddressProvider>(context, listen: false).pickUpAddress;
    double pickUpLatitude = pickUpLocation!.latitude!;
    double pickUpLongitude = pickUpLocation.longitude!;

    LatLng pickUpLatLng = LatLng(pickUpLatitude, pickUpLongitude);

    // Display a loading dialog
    // showDialog(
    //     barrierDismissible: false,
    //     context: context,
    //     builder: (BuildContext context) =>
    //         const LoadingDialog(messageText: 'Updating route...'));

    // Calculate route details between the driver's current location and the pickup location
    var detailsFromDirectionApi =
        await CommonMethods.getDirectionDetailsFromApi(
      driverCurrentLocation,
      pickUpLatLng,
    );

    // if (mounted) Navigator.of(context).pop();

    // Decode and draw the polyline route
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> latLngPointsFromDriverToPickUp =
        polylinePoints.decodePolyline(detailsFromDirectionApi!.encodedPoints!);

    pLineCoordinates.clear();

    if (latLngPointsFromDriverToPickUp.isNotEmpty) {
      for (var latLngPoint in latLngPointsFromDriverToPickUp) {
        pLineCoordinates
            .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
      }
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId('DriverToPickUp'),
        color: Theme.of(context).primaryColor,
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

    // Fit the route into the map view
    LatLngBounds latLngBounds;
    if (driverCurrentLocation.latitude > pickUpLatLng.latitude &&
        driverCurrentLocation.longitude > pickUpLatLng.longitude) {
      latLngBounds = LatLngBounds(
        southwest: pickUpLatLng,
        northeast: driverCurrentLocation,
      );
    } else if (driverCurrentLocation.longitude > pickUpLatLng.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(
          driverCurrentLocation.latitude,
          pickUpLatLng.longitude,
        ),
        northeast: LatLng(
          pickUpLatLng.latitude,
          driverCurrentLocation.longitude,
        ),
      );
    } else if (driverCurrentLocation.latitude > pickUpLatLng.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(
          pickUpLatLng.latitude,
          driverCurrentLocation.longitude,
        ),
        northeast: LatLng(
          driverCurrentLocation.latitude,
          pickUpLatLng.longitude,
        ),
      );
    } else {
      latLngBounds = LatLngBounds(
        southwest: driverCurrentLocation,
        northeast: pickUpLatLng,
      );
    }

    controllerGoogleMap!.animateCamera(
      CameraUpdate.newLatLngBounds(latLngBounds, 70),
    );

    // Add/update the driver marker on the map
    Marker driverMarker = Marker(
      markerId: const MarkerId('driverMarkerId'),
      position: driverCurrentLocation,
      icon: nearbyOnlineDriverIcon!,
    );

    driverMarkersSet.clear();

    setState(() {
      driverMarkersSet.add(driverMarker);
      allMarkersSet = {}
        ..addAll(pinMarkersSet)
        ..addAll(driverMarkersSet);
    });
  }

  updateFromDriverCurrentLocationToDropOffDestination(
      LatLng driverCurrentLocation) async {
    // Retrieve the user's current location
    // var positionOfUserInLatLng =
    //     Provider.of<LocationProvider>(context, listen: false)
    //         .currentPositionLatLng;
    var dropOffLocation =
        Provider.of<AddressProvider>(context, listen: false).dropOffAddress;

    // Extract drop-off location coordinates
    double dropOffLatitude = dropOffLocation!.latitude!;
    double dropOffLongitude = dropOffLocation.longitude!;
    LatLng dropOffLatLng = LatLng(dropOffLatitude, dropOffLongitude);

    // Show a loading dialog
    // showDialog(
    //     barrierDismissible: false,
    //     context: context,
    //     builder: (BuildContext context) =>
    //         const LoadingDialog(messageText: 'Updating route...'));

    // Call Directions API to get route details from current location to drop-off destination
    var detailsFromDirectionApi =
        await CommonMethods.getDirectionDetailsFromApi(
      driverCurrentLocation,
      dropOffLatLng,
    );

    // if (mounted) Navigator.of(context).pop();

    // Decode and draw the polyline route
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> latLngPointsFromCurrentToDropOff =
        polylinePoints.decodePolyline(detailsFromDirectionApi!.encodedPoints!);

    pLineCoordinates.clear();

    if (latLngPointsFromCurrentToDropOff.isNotEmpty) {
      for (var latLngPoint in latLngPointsFromCurrentToDropOff) {
        pLineCoordinates
            .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
      }
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId('CurrentLocationToDropOff'),
        color: Theme.of(context).primaryColor,
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

    // Fit the route into the map view

    if (driverCurrentLocation.latitude > dropOffLatLng.latitude &&
        driverCurrentLocation.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
        southwest: dropOffLatLng,
        northeast: driverCurrentLocation,
      );
    } else if (driverCurrentLocation.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(
          driverCurrentLocation.latitude,
          dropOffLatLng.longitude,
        ),
        northeast: LatLng(
          dropOffLatLng.latitude,
          driverCurrentLocation.longitude,
        ),
      );
    } else if (driverCurrentLocation.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(
          dropOffLatLng.latitude,
          driverCurrentLocation.longitude,
        ),
        northeast: LatLng(
          driverCurrentLocation.latitude,
          dropOffLatLng.longitude,
        ),
      );
    } else {
      latLngBounds = LatLngBounds(
        southwest: driverCurrentLocation,
        northeast: dropOffLatLng,
      );
    }

    // controllerGoogleMap!.animateCamera(
    //   CameraUpdate.newLatLngBounds(latLngBounds, 70),
    // );
  }

  animateCameraOnTripStarted(LatLngBounds latLngBounds) {
    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(
      latLngBounds,
      70,
    ));
  }

  animateCameraOnTrip(LatLng driverCurrentLocation) {
    // Add/update the driver marker on the map
    Marker driverMarker = Marker(
      markerId: const MarkerId('driverMarkerId'),
      position: driverCurrentLocation,
      icon: nearbyOnlineDriverIcon!,
    );

    driverMarkersSet.clear();

    setState(() {
      driverMarkersSet.add(driverMarker);
      allMarkersSet = {}
        ..addAll(pinMarkersSet)
        ..addAll(driverMarkersSet);
    });
    CameraPosition cameraPosition = CameraPosition(
      target: driverCurrentLocation,
      zoom: 14.4746,
    );

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  searchDriver() async {
    if (availableNearbyOnlineDriversList!.isEmpty) {
      await cancelRideRequest();
      await noDriverAvailable();
      clearTheMap();
      return;
    }

    String? driverUid = availableNearbyOnlineDriversList!.first.uidDriver;

    // send notification to the driver
    await sendNotificationToDriver(driverUid!);
  }

  updateTripDetailsInformations(LatLng driverCurrentPositionInLatLng) async {
    var currentPositionOfPassenger =
        Provider.of<LocationProvider>(context, listen: false).currentPosition;

    if (currentPositionOfPassenger == null) {
      return;
    }

    LatLng currentPositionLatLng = LatLng(
      currentPositionOfPassenger.latitude,
      currentPositionOfPassenger.longitude,
    );

    LatLng startLocationLatLng;

    LatLng endLocationLatLng;

    if (stateOfApp == 'accepted') {
      startLocationLatLng = driverCurrentPositionInLatLng;
      endLocationLatLng = currentPositionLatLng;
    } else {
      startLocationLatLng = driverCurrentPositionInLatLng;

      dropOffLocation =
          Provider.of<AddressProvider>(context, listen: false).dropOffAddress;

      double dropOffLatitude = dropOffLocation!.latitude!;
      double dropOffLongitude = dropOffLocation!.longitude!;

      endLocationLatLng = LatLng(dropOffLatitude, dropOffLongitude);
    }

    var driverToDestinationDirectionDetails =
        await CommonMethods.getDirectionDetailsFromApi(
            startLocationLatLng, endLocationLatLng);

    if (driverToDestinationDirectionDetails != null) {
      setState(() {
        durationText = driverToDestinationDirectionDetails.durationText!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    makeDriverIcon();

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final User? user = userProvider.getUser;

        // If the user is null, show a loading spinner
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Scaffold(
          key: scaffoldKey,
          drawer: Container(
            width: 300,
            color: Theme.of(context).primaryColor,
            child: Drawer(
              backgroundColor: Theme.of(context).primaryColor,
              child: ListView(
                children: [
                  // Drawer Header
                  Container(
                    color: Theme.of(context).primaryColor,
                    height: 160,
                    child: DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 60,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Flexible(
                                child: Text(
                                  user.email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(fontSize: 18),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  // Drawer Body
                  Divider(
                    height: 1,
                    color: Theme.of(context).primaryColor,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const AboutScreen()));
                      }
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.info,
                        color: Theme.of(context).canvasColor,
                      ),
                      title: Text(
                        'About',
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  fontSize: 18,
                                  color: Theme.of(context).canvasColor,
                                ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      signout();
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.logout_outlined,
                        color: Theme.of(context).canvasColor,
                      ),
                      title: Text(
                        'Sign Out',
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  fontSize: 18,
                                  color: Theme.of(context).canvasColor,
                                ),
                      ),
                    ),
                  ),

                  // Drawer Footer
                  Divider(
                    height: 1,
                    color: Theme.of(context).primaryColor,
                  ),
                  SvgPicture.asset(
                    'assets/images/logo-cigma-scroll.svg',
                    height: 200,
                    width: 200,
                  ),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              GoogleMap(
                compassEnabled: false,
                zoomControlsEnabled: false,
                padding: Platform.isAndroid
                    ? const EdgeInsets.only(top: 40, right: 10)
                    : EdgeInsets.only(
                        bottom: bottomMapPadding, right: 28, left: 16),
                mapType: MapType.normal,
                myLocationEnabled: true,
                polylines: polyLineSet,
                markers: allMarkersSet,
                circles: circleSet,
                initialCameraPosition: casablancaInitialPosition,
                onMapCreated: (GoogleMapController mapController) async {
                  controllerGoogleMap = mapController;
                  updateMapTheme(controllerGoogleMap!, context);

                  googleMapCompleterController.complete(controllerGoogleMap);

                  getCurrentLiveLocationOfUser(context);
                },
              ),

              // drawer button
              Positioned(
                top: 50,
                left: 19,
                child: GestureDetector(
                  onTap: () {
                    if (!onDirections) {
                      scaffoldKey.currentState!.openDrawer();
                    } else {
                      clearTheMap();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7),
                          )
                        ]),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 20,
                      child: Icon(
                        onDirections ? Icons.close : Icons.menu,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ),
                ),
              ),
              // search container
              Positioned(
                left: 0,
                right: 0,
                bottom: -80,
                child: SizedBox(
                  height: searchContainerHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            searchContainerHeight = 0;
                          });
                          var resultFromSearchDialog = await showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    //This is the blurry background
                                    LayoutBuilder(
                                      builder: (BuildContext context,
                                          BoxConstraints constraints) {
                                        return InkWell(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () {
                                            if (mounted) {
                                              Navigator.of(context).pop();
                                            }
                                            setState(() {
                                              searchContainerHeight = 276;
                                            });
                                          },
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 5, sigmaY: 5),
                                            child: SizedBox(
                                              width: constraints.maxWidth,
                                              height: constraints.maxHeight,
                                              child: Container(
                                                color: Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // This is your SearchScreen widget
                                    const SearchScreen(),
                                  ],
                                ),
                              );
                            },
                          );
                          if (resultFromSearchDialog == 'place_selected') {
                            displayRideDetailsContainer();
                          } else {
                            setState(() {
                              searchContainerHeight = 276;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(
                          Icons.search,
                          size: 25,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(
                          Icons.home,
                          size: 25,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(
                          Icons.work,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ride details container
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: rideDetailsContainerHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15.0,
                        spreadRadius: 0.5,
                        color: Theme.of(context).canvasColor.withOpacity(0.5),
                        offset: const Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                          ),
                          child: SizedBox(
                            height: 200,
                            child: Card(
                              elevation: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                width: MediaQuery.of(context).size.width * .70,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          (tripDirectionDetails != null)
                                              ? tripDirectionDetails!
                                                  .distanceText!
                                              : '0 Km',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium!
                                              .copyWith(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (tripDirectionDetails != null)
                                              ? tripDirectionDetails!
                                                  .durationText!
                                              : '0 min',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall!
                                              .copyWith(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () async {
                                            // ignore: avoid_print
                                            print('Ride details tapped');

                                            setState(() {
                                              stateOfApp = 'requesting';
                                            });

                                            await displayRequestingRideContainer();

                                            // get nearest available online drivers
                                            availableNearbyOnlineDriversList =
                                                ManageDriversMethods
                                                    .nearbyOnlineDriversList;
                                            // reset the bool values to false
                                            requestAlreadyAccepted = false;
                                            driverAlreadyArrived = false;
                                            tripStarted = false;
                                            tripEnded = false;
                                            tripCanceled = false;

                                            // search driver
                                            await searchDriver();
                                          },
                                          child: Image.asset(
                                              'assets/images/electric_car.png',
                                              height: 80,
                                              width: 180),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (tripDirectionDetails != null)
                                              ? '\$${commonMethods.calculateFareAmount(tripDirectionDetails!)}'
                                              : '\$0',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // on trip container
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: onTripContainerHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onPrimary,
                        blurRadius: 15.0,
                        spreadRadius: 0.5,
                        offset: const Offset(
                          0.7,
                          0.7,
                        ),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$tripStatusDisplay - ',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              durationText,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(
                                    fontSize: 16,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                          thickness: 1,
                        ),

                        const SizedBox(height: 20),

                        // driver photoUrl and driver displayName
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: photoDriver.isEmpty
                                  ? Image.asset(
                                      'assets/images/avatar_man.png',
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      photoDriver,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nameDriver,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium!
                                      .copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  carDetailsDriver,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                          thickness: 1,
                        ),

                        const SizedBox(height: 20),

                        // call driver and cancel trip buttons

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () async {
                                try {
                                  await commonMethods
                                      .makePhoneCall(phoneNumberDriver!);
                                } on Exception {
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Error'),
                                        content: const Text(
                                            'An error occurred while trying to make a phone call.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.call,
                                color: Theme.of(context).primaryColor,
                                size: 30,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Cancel Trip',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              )),
                                      content: const Text(
                                          'Are you sure you want to cancel this trip?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await FirestoreMethods()
                                                .updateTripRequestStatus(
                                                    requestId, 'canceled');
                                            clearTheMap();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).primaryColor,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // // old code
              // Positioned(
              //   left: 0,
              //   right: 0,
              //   bottom: 0,
              //   child: Container(
              //     height: onTripContainerHeight,
              //     decoration: BoxDecoration(
              //       color: Theme.of(context).canvasColor.withOpacity(0.5),
              //       borderRadius: const BorderRadius.only(
              //         topLeft: Radius.circular(16),
              //         topRight: Radius.circular(16),
              //       ),
              //       boxShadow: [
              //         BoxShadow(
              //           color: Theme.of(context).colorScheme.onPrimary,
              //           blurRadius: 15.0,
              //           spreadRadius: 0.5,
              //           offset: const Offset(
              //             0.7,
              //             0.7,
              //           ),
              //         )
              //       ],
              //     ),
              //     child: Padding(
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 24,
              //         vertical: 18,
              //       ),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.center,
              //         children: [
              //           const SizedBox(
              //             height: 12,
              //           ),
              //           Text(
              //             tripStatusDisplay,
              //             style: Theme.of(context)
              //                 .textTheme
              //                 .headlineMedium!
              //                 .copyWith(
              //                   fontSize: 22,
              //                   fontWeight: FontWeight.bold,
              //                 ),
              //           ),
              //           const SizedBox(
              //             height: 20,
              //           ),
              //           GestureDetector(
              //             onTap: () {
              //               showDialog(
              //                 context: context,
              //                 builder: (context) {
              //                   return AlertDialog(
              //                     title: Text('Cancel Trip',
              //                         style: Theme.of(context)
              //                             .textTheme
              //                             .labelMedium!
              //                             .copyWith(
              //                               fontWeight: FontWeight.bold,
              //                               fontSize: 18,
              //                               color: Theme.of(context)
              //                                   .colorScheme
              //                                   .onSurface,
              //                             )),
              //                     content: const Text(
              //                         'Are you sure you want to cancel this trip?'),
              //                     actions: [
              //                       TextButton(
              //                         onPressed: () {
              //                           Navigator.pop(context);
              //                         },
              //                         child: const Text('No'),
              //                       ),
              //                       TextButton(
              //                         onPressed: () async {
              //                           await FirestoreMethods()
              //                               .updateTripRequestStatus(
              //                                   requestId, 'canceled');
              //                           clearTheMap();
              //                           Navigator.pop(context);
              //                         },
              //                         child: const Text('Yes'),
              //                       ),
              //                     ],
              //                   );
              //                 },
              //               );
              //             },
              //             child: Container(
              //               height: 50,
              //               width: 50,
              //               decoration: BoxDecoration(
              //                 color: Theme.of(context)
              //                     .colorScheme
              //                     .onPrimaryContainer,
              //                 borderRadius: BorderRadius.circular(25),
              //                 border: Border.all(
              //                   width: 1.5,
              //                   color: Colors.grey,
              //                 ),
              //               ),
              //               child: Icon(
              //                 Icons.close,
              //                 color: Theme.of(context).primaryColor,
              //                 size: 25,
              //               ),
              //             ),
              //           )
              //         ],
              //       ),
              //     ),
              //   ),
              // ),

              // request ride container
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: requestRideContainerHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onPrimary,
                        blurRadius: 15.0,
                        spreadRadius: 0.5,
                        offset: const Offset(
                          0.7,
                          0.7,
                        ),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: 200,
                          child: LoadingAnimationWidget.flickr(
                            leftDotColor: Theme.of(context).colorScheme.primary,
                            rightDotColor:
                                Theme.of(context).colorScheme.secondary,
                            size: 50,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () async {
                            clearTheMap();
                            await cancelRideRequest();
                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                width: 1.5,
                                color: Colors.grey,
                              ),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).primaryColor,
                              size: 25,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
