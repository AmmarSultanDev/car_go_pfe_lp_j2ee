// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:car_go_pfe_lp_j2ee/global/global_var.dart';
import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/screens/authentication/signin_screen.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  getCurrentLiveLocationOfUser() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    currentPositionOfUser = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition = CameraPosition(
      target: positionOfUserInLatLng,
      zoom: 14.4746,
    );

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  // signout
  signout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(messageText: 'Signing out ...'),
    );

    await AuthMethods().signoutUser();

    if (context.mounted) {
      Navigator.of(context).pop(); // Close the loading dialog

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SigninScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final User? user = Provider.of<UserProvider>(context).getUser;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              signout();
            },
          ),
        ],
      ),
      drawer: Container(
        width: 255,
        color: Theme.of(context).primaryColor,
        child: Drawer(
          backgroundColor: Theme.of(context).primaryColor,
          child: ListView(
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                height: 160,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 60,
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!, context);

              googleMapCompleterController.complete(controllerGoogleMap);

              getCurrentLiveLocationOfUser();
            },
          ),
        ],
      ),
    );
  }
}
