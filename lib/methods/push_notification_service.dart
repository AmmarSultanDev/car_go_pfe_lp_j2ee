import 'dart:convert';

import 'package:car_go_pfe_lp_j2ee/providers/address_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class PushNotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson =
        await rootBundle.loadString('service_account_key.json');

    List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging'
    ];

    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

    //get the access token
    final auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);

    client.close();

    return credentials.accessToken.data;
  }

  static sendNotificationToSelectedDriver(
      String deviceToken, String tripId, BuildContext context) async {
    String username =
        Provider.of<UserProvider>(context, listen: false).getUser!.displayName;

    String pickUpAddress = Provider.of<AddressProvider>(context, listen: false)
            .pickUpAddress!
            .placeName ??
        '';

    String dropOffAddress = Provider.of<AddressProvider>(context, listen: false)
            .dropOffAddress!
            .placeName ??
        '';

    final String accessToken = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        'https://fcm.googleapis.com/v1/projects/car-go-pfe-lp-j2ee/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {
          'title': 'New Trip Request from $username',
          'body': 'Pick up: $pickUpAddress, Drop off: $dropOffAddress',
        },
        'data': {
          'tripId': tripId,
        }
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Notification sent successfully');
      }
    } else {
      if (kDebugMode) {
        print('Failed to send notification. Error: ${response.body}');
      }
    }
  }
}
