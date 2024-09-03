import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/providers/address_provider.dart';
import 'package:car_go_pfe_lp_j2ee/providers/location_provider.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/models/user.dart' as model;
import 'package:car_go_pfe_lp_j2ee/screens/authentication/signin_screen.dart';
import 'package:car_go_pfe_lp_j2ee/firebase_options.dart';
import 'package:car_go_pfe_lp_j2ee/resources/app_colors.dart';
import 'package:car_go_pfe_lp_j2ee/screens/blocked_screen.dart';
import 'package:car_go_pfe_lp_j2ee/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Check if Firebase has been initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure App Check
      await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug);
    }
  } catch (e) {
    if (kDebugMode) {
      print(e.toString());
    }
  }

  // Set the orientation to portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final CommonMethods commonMethods = const CommonMethods();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'CarGo',
        theme: ThemeData(
          primaryColor: AppColors.lightPrimary,
          scaffoldBackgroundColor: AppColors.lightSurface,
          colorScheme: const ColorScheme.light(
            primary: AppColors.lightPrimary,
            onPrimary: AppColors.lightOnPrimary,
            secondary: AppColors.lightSecondary,
            onSecondary: AppColors.lightOnSecondary,
          ),
          fontFamily: 'Montserrat',
          textTheme: const TextTheme(
            headlineLarge:
                TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
            headlineMedium:
                TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
            headlineSmall: TextStyle(fontSize: 14.0, fontFamily: 'Roboto'),
          ),
        ),
        darkTheme: ThemeData(
          primaryColor: AppColors.darkPrimary,
          canvasColor: AppColors.darkBackground,
          scaffoldBackgroundColor: AppColors.darkSurface,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.darkPrimary,
            onPrimary: AppColors.darkOnPrimary,
            secondary: AppColors.darkSecondary,
            onSecondary: AppColors.darkOnSecondary,
          ),
          fontFamily: 'Montserrat',
          textTheme: const TextTheme(
            headlineLarge:
                TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
            headlineMedium:
                TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
            headlineSmall: TextStyle(fontSize: 14.0, fontFamily: 'Roboto'),
          ),
        ),
        themeMode: ThemeMode
            .system, // Automatically select the theme based on the system settings
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (userSnapshot.hasError) {
              return const SigninScreen();
            } else if (userSnapshot.hasData) {
              User? user = userSnapshot.data;

              return FutureBuilder(
                future: const CommonMethods().askForLocationPermission(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    commonMethods.displaySnackBar(
                        'Please allow location permission.', context);
                    return const SigninScreen();
                  } else {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return const SigninScreen();
                        } else if (!snapshot.data!.exists) {
                          return const SigninScreen();
                        } else if (snapshot.hasData) {
                          model.User? user =
                              model.User.fromSnap(snapshot.data!);
                          Provider.of<UserProvider>(context, listen: false)
                              .setUser = user;

                          bool isBlocked =
                              snapshot.data!.get('isBlocked') as bool;
                          if (isBlocked) {
                            return const BlockedScreen(); // return a screen for blocked users
                          } else {
                            return const HomeScreen(); // return the dashboard if the user is not blocked
                          }
                        } else {
                          return const Center(
                            child: Text('No data'),
                          );
                        }
                      },
                    );
                  }
                },
              );
            } else {
              return const SigninScreen();
            }
          },
        ),
      ),
    );
  }
}
