import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  LatLng? _currentPositionLatLng;

  Position? get currentPosition => _currentPosition;
  LatLng? get currentPositionLatLng => _currentPositionLatLng;

  void setCurrentPosition(Position position) {
    _currentPosition = position;
    _currentPositionLatLng = LatLng(position.latitude, position.longitude);
    notifyListeners();
  }
}
