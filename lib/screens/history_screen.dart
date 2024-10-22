import 'package:car_go_pfe_lp_j2ee/methods/firestore_methods.dart';
import 'package:car_go_pfe_lp_j2ee/widgets/history_list_item.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  getTrips() async {
    // get trips from firestore
    await FirestoreMethods().getTripHistory().then((trips) {
      setState(() {
        endedTripDetails = trips;
      });
    });
  }

  List endedTripDetails = [];

  @override
  Widget build(BuildContext context) {
    getTrips();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('History'),
        ),
        body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            width: double.infinity,
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                endedTripDetails.isEmpty
                    ? const Center(
                        child: Text('No trips yet'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: endedTripDetails.length,
                        itemBuilder: (ctx, index) {
                          if (endedTripDetails.isNotEmpty) {
                            return HistoryListItem(
                              tripDetails: endedTripDetails[index],
                            );
                          } else {
                            return const Center(
                              child: Text('No trips yet'),
                            );
                          }
                        },
                      )
              ],
            )));
  }
}
