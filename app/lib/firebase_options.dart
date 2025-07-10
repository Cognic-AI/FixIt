import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'dart:developer' as developer;

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
  static FirebaseOptions get currentPlatform {
    developer.log('🔥 Getting Firebase options for current platform',
        name: 'FirebaseOptions');
    if (kIsWeb) {
      developer.log('🌐 Platform detected: Web', name: 'FirebaseOptions');
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        developer.log('📱 Platform detected: Android', name: 'FirebaseOptions');
        return android;
      case TargetPlatform.iOS:
        developer.log('📱 Platform detected: iOS', name: 'FirebaseOptions');
        return ios;
      case TargetPlatform.macOS:
        developer.log('💻 Platform detected: macOS', name: 'FirebaseOptions');
        return macos;
      case TargetPlatform.windows:
        developer.log('💻 Platform detected: Windows', name: 'FirebaseOptions');
        return windows;
      case TargetPlatform.linux:
        developer.log('⚠️ Platform detected: Linux (unsupported)',
            name: 'FirebaseOptions');
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        developer.log('❌ Unknown platform detected', name: 'FirebaseOptions');
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web {
    developer.log('🌐 Creating web Firebase options', name: 'FirebaseOptions');
    return const FirebaseOptions(
      apiKey: "YOUR_API_KEY_HERE",
      appId: "YOUR_APP_ID_HERE",
      messagingSenderId: "YOUR_SENDER_ID_HERE",
      projectId: "YOUR_PROJECT_ID_HERE",
      authDomain: "YOUR_PROJECT_ID_HERE.firebaseapp.com",
      storageBucket: "YOUR_PROJECT_ID_HERE.appspot.com",
      measurementId: "YOUR_MEASUREMENT_ID_HERE",
    );
  }

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
