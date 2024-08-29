import 'dart:io';

import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/prediction.dart';
import 'package:car_go_pfe_lp_j2ee/providers/address_provider.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/prediction_place_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _pickUpController = TextEditingController();
  final TextEditingController _dropOffController = TextEditingController();
  List<Prediction> dropOffPredictionList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  setPickUpLocationAddress() {
    String userAdress = Provider.of<AddressProvider>(context, listen: false)
            .pickUpAddress!
            .humanReadableAddress ??
        '';
    print('User address: $userAdress');

    _pickUpController.text = userAdress;
  }

  searchLocation(String locationName) async {
    if (locationName.length > 1) {
      String? apiKey = Platform.isIOS
          ? dotenv.env['GOOGLE_MAPS_API_KEY_IOS']
          : dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'];
      String autoCompleteURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$apiKey&components=country:ma';

      // Send request to the API
      var response = await CommonMethods.sendRequestToApi(autoCompleteURL);

      if (response == 'error') {
        const CommonMethods().displaySnackBar('An error occured!', context);
      } else if (response == 'use_unrestricted') {
        // resend the request with a different API key
        response = await CommonMethods.sendRequestToApi(
            'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=${dotenv.env['GOOGLE_MAPS_NO_RESTRICTION_API_KEY']}&components=country:ma');
        if (response['status'] == 'OK') {
          var predictionResultInJson = response['predictions'];
          var predictionsList = (predictionResultInJson as List)
              .map((eachPlacePrediction) =>
                  Prediction.fromJson(eachPlacePrediction))
              .toList();
          setState(() {
            dropOffPredictionList = predictionsList;
          });
          print(
              'Drop off prediction list length: ${dropOffPredictionList.length}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    setPickUpLocationAddress();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 10,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 0.5,
                  blurRadius: 5,
                  offset: const Offset(0.7, 0.7),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24, top: 24, right: 24, bottom: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Text(
                        'Set destination location',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  // pick up location
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/pin_map_start_position.png',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(
                        width: 18,
                      ),
                      Expanded(
                          child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: TextField(
                            controller: _pickUpController,
                            decoration: InputDecoration(
                              hintText: 'Pick up location',
                              fillColor: Theme.of(context).primaryColor,
                              filled: true,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(
                                  left: 11, top: 9, bottom: 9),
                            ),
                          ),
                        ),
                      ))
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/pin_map_destination.png',
                        height: 20,
                        width: 20,
                        color: Colors.red[700],
                      ),
                      const SizedBox(
                        width: 18,
                      ),
                      Expanded(
                          child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: TextField(
                            controller: _dropOffController,
                            onChanged: (value) => searchLocation(value),
                            decoration: InputDecoration(
                              hintText: 'Drop off location',
                              fillColor: Theme.of(context).primaryColor,
                              filled: true,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(
                                  left: 11, top: 9, bottom: 9),
                            ),
                          ),
                        ),
                      ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        // display the prediction results for drop off location
        (dropOffPredictionList.isNotEmpty)
            ? Flexible(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      child: PredictionPlaceUi(
                        prediction: dropOffPredictionList[index],
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(
                    height: 2,
                  ),
                  itemCount: dropOffPredictionList.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                ),
              )
            : Container(),
      ],
    );
  }
}
