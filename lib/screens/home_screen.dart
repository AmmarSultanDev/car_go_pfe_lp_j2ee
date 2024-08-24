// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:car_go_pfe_lp_j2ee/global/global_var.dart';
import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/methods/firestore_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart';
import 'package:car_go_pfe_lp_j2ee/providers/address_provider.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/screens/authentication/signin_screen.dart';
import 'package:car_go_pfe_lp_j2ee/screens/blocked_screen.dart';
import 'package:car_go_pfe_lp_j2ee/screens/search_screen.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();

  GoogleMapController? controllerGoogleMap;

  Position? currentPositionOfUser;

  CommonMethods commonMethods = const CommonMethods();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  double searchContainerHeight = 276;

  LatLng? positionOfUserInLatLng;

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

    positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    await CommonMethods.convertGeoCodeToAddress(
        positionOfUserInLatLng!.latitude,
        positionOfUserInLatLng!.longitude,
        context);

    CameraPosition cameraPosition = CameraPosition(
      target: positionOfUserInLatLng!,
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

  checkBlockStatus() async {
    User? user = Provider.of<UserProvider>(context, listen: false).getUser;

    if (user != null) {
      bool blockStatus = await FirestoreMethods().checkBlockStatus(user.uid);
      if (blockStatus) {
        await signout();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BlockedScreen()));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkBlockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkBlockStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final User? user = Provider.of<UserProvider>(context).getUser;

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
                            user!.displayName,
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
                onTap: () {},
                child: ListTile(
                  leading: Icon(
                    Icons.info,
                    color: Theme.of(context).canvasColor,
                  ),
                  title: Text(
                    'About',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
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
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
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
                : const EdgeInsets.only(bottom: 100, right: 28, left: 16),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) async {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!, context);

              googleMapCompleterController.complete(controllerGoogleMap);

              getCurrentLiveLocationOfUser();
            },
          ),

          // drawer button
          Positioned(
            top: 50,
            left: 19,
            child: GestureDetector(
              onTap: () {
                scaffoldKey.currentState!.openDrawer();
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
                    Icons.menu,
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ),
            ),
          ),
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
                      var resultFromSearchDialog = await showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                // This is the blurry background
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: const SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                                // This is your SearchScreen widget
                                SizedBox(
                                  width: null,
                                  height: null,
                                  child: SearchScreen(),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (resultFromSearchDialog == 'place_selected') {
                        String dropOffLocation =
                            Provider.of<AddressProvider>(context, listen: false)
                                    .dropOffAddress!
                                    .placeName ??
                                '';

                        print('Drop off location: $dropOffLocation');
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
          )
        ],
      ),
    );
  }
}
