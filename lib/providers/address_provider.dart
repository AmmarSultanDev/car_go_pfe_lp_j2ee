import 'package:car_go_pfe_lp_j2ee/models/address.dart';
import 'package:flutter/material.dart';

class AddressProvider extends ChangeNotifier {
  Address? pickUpAddress;
  Address? dropOffAddress;

  void updatePickUpAddress(Address address) {
    pickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddress(Address address) {
    dropOffAddress = address;
    notifyListeners();
  }
}
