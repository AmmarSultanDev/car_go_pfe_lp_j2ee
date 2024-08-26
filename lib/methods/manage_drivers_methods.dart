import 'package:car_go_pfe_lp_j2ee/models/online_nearby_driver.dart';

class ManageDriversMethods {
  static List<OnlineNearbyDriver> nearbyOnlineDriversList = [];

  static void removeDriverFromList(String driverUid) {
    int index = nearbyOnlineDriversList
        .indexWhere((driver) => driver.uidDriver == driverUid);

    if (nearbyOnlineDriversList.isNotEmpty && index != -1) {
      nearbyOnlineDriversList.removeAt(index);
    }
  }

  static void updateDriverLocation(OnlineNearbyDriver onlineNearbyDriverInfo) {
    int index = nearbyOnlineDriversList.indexWhere(
        (driver) => driver.uidDriver == onlineNearbyDriverInfo.uidDriver);

    if (nearbyOnlineDriversList.isNotEmpty && index != -1) {
      nearbyOnlineDriversList[index].latitude = onlineNearbyDriverInfo.latitude;
      nearbyOnlineDriversList[index].longitude =
          onlineNearbyDriverInfo.longitude;
    } else {
      nearbyOnlineDriversList.add(onlineNearbyDriverInfo);
    }
  }
}
