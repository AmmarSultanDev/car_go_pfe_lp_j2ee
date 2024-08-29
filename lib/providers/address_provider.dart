import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:flutter/material.dart';

class AddressProvider extends ChangeNotifier {
  Address? pickUpAddress;
  Address? dropOffAddress;

  void updatePickUpAddress(Address address) {
    Future.microtask(() {
      pickUpAddress = address;
      notifyListeners();
    });
  }

  void updateDropOffAddress(Address address) {
    Future.microtask(() {
      dropOffAddress = address;
      notifyListeners();
    });
  }
}
