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
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static Future<void> loadEnv() async {
    await dotenv.load(fileName: ".env");
  }

  static FirebaseOptions get currentPlatform {
    // Ensure environment variables are loaded
    if (!dotenv.isInitialized) {
      throw Exception(
          'Environment variables not loaded. Call loadEnv() first.');
    }

    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        authDomain:
            '${dotenv.env['FIREBASE_PROJECT_ID'] ?? ''}.firebaseapp.com',
        storageBucket: '${dotenv.env['FIREBASE_PROJECT_ID'] ?? ''}.appspot.com',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: '${dotenv.env['FIREBASE_PROJECT_ID'] ?? ''}.appspot.com',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: '${dotenv.env['FIREBASE_PROJECT_ID'] ?? ''}.appspot.com',
        iosClientId: dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? '',
        iosBundleId:
            dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'com.example.fixit',
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_MACOS_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_MACOS_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: '${dotenv.env['FIREBASE_PROJECT_ID'] ?? ''}.appspot.com',
        iosClientId: dotenv.env['FIREBASE_MACOS_CLIENT_ID'] ?? '',
        iosBundleId:
            dotenv.env['FIREBASE_MACOS_BUNDLE_ID'] ?? 'com.example.fixit',
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_WINDOWS_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_WINDOWS_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: '${dotenv.env['FIREBASE_PROJECT_ID'] ?? ''}.appspot.com',
      );
}
