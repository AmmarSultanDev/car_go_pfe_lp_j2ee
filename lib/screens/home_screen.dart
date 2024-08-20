import 'dart:async';

import 'package:car_go_pfe_lp_j2ee/global/global_var.dart';
import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/screens/authentication/signin_screen.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
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
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;

              googleMapCompleterController.complete(controllerGoogleMap);
            },
          ),
        ],
      ),
    );
  }
}
