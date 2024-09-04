import 'dart:convert';
import 'dart:io';

import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:car_go_pfe_lp_j2ee/models/direction_details.dart';
import 'package:car_go_pfe_lp_j2ee/providers/address_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  askForLocationPermission() async {
    if (await Permission.locationWhenInUse.isDenied ||
        await Permission.locationWhenInUse.status.isGranted != true) {
      await Permission.location.request();
    }
  }

  askForNotificationPermission() async {
    if (await Permission.notification.isDenied ||
        await Permission.notification.status.isGranted != true) {
      await Permission.notification.request();
    }
  }

  static sendRequestToApi(String apiURL) async {
    if (kDebugMode) {
      print(apiURL);
    }
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

  static Future<String> convertGeoCodeToAddress(
      double lat, double long, BuildContext context) async {
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

        Address address = Address(
          humanReadableAddress: responseFromApi['results'][0]
              ['formatted_address'],
          latitude: lat,
          longitude: long,
        );

        // handle the address with the help of the provider

        if (context.mounted) {
          Provider.of<AddressProvider>(context, listen: false)
              .updatePickUpAddress(address);
        }

        return responseFromApi['results'][0]['formatted_address'];
      }
      return responseFromApi['results'][0]['formatted_address'];
    }
    return responseFromApi;
  }

  static Future<DirectionDetails?> getDirectionDetailsFromApi(
      LatLng source, LatLng destination) async {
    String? apiKey = Platform.isIOS
        ? dotenv.env['GOOGLE_MAPS_API_KEY_IOS']
        : dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'];
    String urlDirectionsApi =
        'https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$apiKey';

    var response = await sendRequestToApi(urlDirectionsApi);

    if (response != 'error') {
      if (response == 'use_unrestricted') {
        String urlDirectionsApiNoRestriction =
            'https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=${dotenv.env['GOOGLE_MAPS_NO_RESTRICTION_API_KEY']}';

        response = await sendRequestToApi(urlDirectionsApiNoRestriction);

        if (response['status'] == 'OK') {
          DirectionDetails directionDetails = DirectionDetails(
            distanceText: response['routes'][0]['legs'][0]['distance']['text'],
            distanceValue: response['routes'][0]['legs'][0]['distance']
                ['value'],
            durationText: response['routes'][0]['legs'][0]['duration']['text'],
            durationValue: response['routes'][0]['legs'][0]['duration']
                ['value'],
            encodedPoints: response['routes'][0]['overview_polyline']['points'],
          );

          return directionDetails;
        }
      }
    }

    return null;
  }

  calculateFareAmount(DirectionDetails directionDetails) {
    // Calculate the fare amount
    double timeTraveledFare = directionDetails.durationValue! / 60 * 0.08;
    double distanceTraveledFare = directionDetails.distanceValue! / 1000 * 0.08;
    double totalFareAmount = timeTraveledFare + distanceTraveledFare;

    // return the rounded fare amount

    totalFareAmount = double.parse(totalFareAmount.toStringAsFixed(2));

    return totalFareAmount;
  }

  makePhoneCall(String phoneNumber) async {
    String telScheme = 'tel:$phoneNumber';

    if (Platform.isAndroid) {
      if (await Permission.phone.isGranted) {
        if (await canLaunchUrl(Uri.parse(telScheme))) {
          await launchUrl(Uri.parse(telScheme));
        } else {
          throw 'Could not launch $telScheme';
        }
      } else {
        await Permission.phone.request();
        makePhoneCall(phoneNumber);
      }
    } else {
      if (await canLaunchUrl(Uri.parse(telScheme))) {
        await launchUrl(Uri.parse(telScheme));
      } else {
        throw 'Could not launch $telScheme';
      }
    }
  }
}
