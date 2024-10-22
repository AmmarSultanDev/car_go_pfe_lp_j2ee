import 'package:car_go_pfe_lp_j2ee/models/trip_details.dart';
import 'package:flutter/material.dart';

class HistoryListItem extends StatelessWidget {
  const HistoryListItem({super.key, required this.tripDetails});

  final TripDetails tripDetails;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 10,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      NetworkImage(tripDetails.driverInfo!['photoUrl']),
                ),
                // from start to end locations
                Row(
                  children: [
                    Text(tripDetails.pickUpLocationAddress!),
                    Image.asset(
                      'assets/images/ic_arrow_right.png',
                      width: 24,
                      height: 24,
                    ),
                    Text(tripDetails.dropOffLocationAddress!),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
