import 'dart:io';

import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:car_go_pfe_lp_j2ee/models/prediction.dart';
import 'package:car_go_pfe_lp_j2ee/providers/address_provider.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class PredictionPlaceUi extends StatefulWidget {
  PredictionPlaceUi({super.key, this.prediction});

  Prediction? prediction;

  @override
  State<PredictionPlaceUi> createState() => _PredictionPlaceUiState();
}

class _PredictionPlaceUiState extends State<PredictionPlaceUi> {
  fetchClickedPlaceDetails(String placeId) async {
    //show dialog to indicate loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: LoadingDialog(messageText: 'Fetching place details ...'),
      ),
    );
    // Fetch the details of the clicked place
    String? apiKey = Platform.isIOS
        ? dotenv.env['GOOGLE_MAPS_API_KEY_IOS']
        : dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'];

    String urlPlaceDetailsApi =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    // Send request to the API
    var response = await CommonMethods.sendRequestToApi(urlPlaceDetailsApi);

    // Close the dialog
    if (mounted) Navigator.of(context).pop();

    if (response == 'error') {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        const CommonMethods().displaySnackBar('An error occured!', context);
      }
    } else if (response == 'use_unrestricted') {
      // resend the request with a different API key
      response = await CommonMethods.sendRequestToApi(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${dotenv.env['GOOGLE_MAPS_NO_RESTRICTION_API_KEY']}');
      if (response['status'] == 'OK') {
        // Do something with the response

        Address dropOffLocation = Address(
          latitude: response['result']['geometry']['location']['lat'],
          longitude: response['result']['geometry']['location']['lng'],
          placeId: placeId,
          placeName: response['result']['name'],
        );

        // handle the address with the help of the provider
        if (mounted) {
          Provider.of<AddressProvider>(context, listen: false)
              .updateDropOffAddress(dropOffLocation);
        }

        // Close the search screen
        if (mounted) Navigator.of(context).pop('place_selected');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await fetchClickedPlaceDetails(widget.prediction!.placeId!);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.share_location),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prediction!.mainText!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.prediction!.secondaryText!,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
