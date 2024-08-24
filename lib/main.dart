import 'package:car_go_pfe_lp_j2ee/methods/common_methods.dart';
import 'package:car_go_pfe_lp_j2ee/providers/user_provider.dart';
import 'package:car_go_pfe_lp_j2ee/screens/authentication/signin_screen.dart';
import 'package:car_go_pfe_lp_j2ee/firebase_options.dart';
import 'package:car_go_pfe_lp_j2ee/resources/app_colors.dart';
import 'package:car_go_pfe_lp_j2ee/screens/blocked_screen.dart';
import 'package:car_go_pfe_lp_j2ee/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

var status;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Check if Firebase has been initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print(e.toString());
  }

  await askForPermission();

  runApp(const MyApp());
}

askForPermission() async {
  status = await Permission.locationWhenInUse.status;
  if (status == PermissionStatus.denied) {
    await Permission.locationWhenInUse.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
              return const Center(
                child: Text('Something went wrong!'),
              );
            } else if (userSnapshot.hasData) {
              User? user = userSnapshot.data;
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text('Something went wrong!'),
                    );
                  } else if (snapshot.hasData) {
                    bool isBlocked = snapshot.data!.get('isBlocked') as bool;
                    if (isBlocked) {
                      return const BlockedScreen(); // return a screen for blocked users
                    } else {
                      return status == PermissionStatus.granted
                          ? const HomeScreen()
                          : const SigninScreen();
                    }
                  } else {
                    return const SigninScreen();
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
