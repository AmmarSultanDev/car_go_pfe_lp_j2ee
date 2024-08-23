import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

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
    }
    return status.isGranted;
  }

  static sendRequestToApi(String apiURL) async {
    print(apiURL);
    http.Response response = await http.get(Uri.parse(apiURL));

    try {
      if (response.statusCode == 200) {
        String dataFromApi = response.body;
        var dataDecoded = jsonDecode(dataFromApi);
        if (dataDecoded['status'] == 'REQUEST_DENIED') {
          return 'use_unrestricted';
        }
        return dataDecoded;
      } else {
        return 'error';
      }
    } catch (e) {
      return 'error';
    }
  }

  static Future<String> convertGeoCodeToAddress(double lat, double long) async {
    // Convert the lat and long to address
    String apiURLANDROID =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=${dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID']}';
    String apiURLIOS =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=${dotenv.env['GOOGLE_MAPS_API_KEY_IOS']}';

    var responseFromApi =
        await sendRequestToApi(Platform.isAndroid ? apiURLANDROID : apiURLIOS);

    if (responseFromApi != 'error') {
      if (responseFromApi == 'use_unrestricted') {
        String apiURLNORESTRICTION =
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$long&key=${dotenv.env['GOOGLE_MAPS_NO_RESTRICTION_API_KEY']}';
        responseFromApi = await sendRequestToApi(apiURLNORESTRICTION);
        print(responseFromApi.toString());
        return responseFromApi['results'][0]['address_components']
            ['formatted_address'];
      }
      print(responseFromApi.toString());
      return responseFromApi['results'][0]['formatted_address'];
    }
    return responseFromApi;
  }
}
