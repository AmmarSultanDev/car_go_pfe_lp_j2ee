import 'package:google_maps_flutter/google_maps_flutter.dart';

String googleMapKey = 'AIzaSyBtgO69A3xicdorydolvLf4CfEG91LAdIM';
// for dev purpose we're getting the location of google plex
const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
