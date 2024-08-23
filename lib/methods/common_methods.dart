import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CommonMethods {
  const CommonMethods();

  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (!connectionResult.contains(ConnectivityResult.mobile) &&
        !connectionResult.contains(ConnectivityResult.wifi)) {
      if (context.mounted) {
        displaySnackBar('No internet connection!', context);
      }
    }
  }

  void displaySnackBar(String text, BuildContext context) {
    // Display a snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> askForPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status == PermissionStatus.denied) {
      await Permission.locationWhenInUse.request();
      return true;
    }
    return false;
  }
}
