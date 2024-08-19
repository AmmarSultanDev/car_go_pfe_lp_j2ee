// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCIsG4boMatPHruLlfr8VqLKIQJhsTXnxs',
    appId: '1:321538158709:web:bdfd749b0d67639d13083c',
    messagingSenderId: '321538158709',
    projectId: 'car-go-pfe-lp-j2ee',
    authDomain: 'car-go-pfe-lp-j2ee.firebaseapp.com',
    storageBucket: 'car-go-pfe-lp-j2ee.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6oFarfQStUoSvzvbrNm4PylLoB3f4to4',
    appId: '1:321538158709:android:90e2bc064337fdc713083c',
    messagingSenderId: '321538158709',
    projectId: 'car-go-pfe-lp-j2ee',
    storageBucket: 'car-go-pfe-lp-j2ee.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAlwxsIsmaDI6I1kWsCNCt3C1NryGXu-do',
    appId: '1:321538158709:ios:d24b1d419e91e53313083c',
    messagingSenderId: '321538158709',
    projectId: 'car-go-pfe-lp-j2ee',
    storageBucket: 'car-go-pfe-lp-j2ee.appspot.com',
    iosBundleId: 'com.example.carGoPfeLpJ2ee',
  );
}