import 'package:car_go_pfe_lp_j2ee/methods/auth_methods.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  model.User? _user;
  final AuthMethods _authMethods = AuthMethods();

  model.User? get getUser => _user;

  Future<model.User?> refreshUser() async {
    model.User? user = await _authMethods.getUserDetails();

    Future.microtask(() {
      _user = user;
      notifyListeners();
    });

    return user;
  }

  set setUser(model.User user) {
    Future.microtask(() {
      _user = user;
      notifyListeners();
    });
  }
}
