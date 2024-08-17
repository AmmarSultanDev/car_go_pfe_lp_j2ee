import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class CommonMethods {
  const CommonMethods(this.context);

  final BuildContext context;

  checkConnectivity() async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (!connectionResult.contains(ConnectivityResult.mobile) &&
        !connectionResult.contains(ConnectivityResult.wifi)) {
      displaySnackBar('No internet connection!', context);
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
}
