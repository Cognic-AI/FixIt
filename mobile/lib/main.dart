import 'package:fixit/pages/vendor/vendor_home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'pages/auth/login_page.dart';
import 'pages/home_page.dart';
import 'pages/onboarding/interests_page.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🚀 [MAIN] Starting FixIt App - ${DateTime.now()}');
  developer.log('🚀 Starting FixIt App', name: 'Main');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ [MAIN] Flutter bindings initialized');
  developer.log('✅ Flutter bindings initialized', name: 'Main');

  try {
    // Load environment variables first
    print('📄 [MAIN] Loading environment variables...');
    developer.log('📄 Loading environment variables...', name: 'Main');
    await dotenv.load(fileName: ".env");
    print('✅ [MAIN] Environment variables loaded');
    developer.log('✅ Environment variables loaded', name: 'Main');

    // Check if Firebase is already initialized before trying to initialize it again
    print('🔥 [MAIN] Checking Firebase initialization status...');
    developer.log('🔥 Checking Firebase initialization status...',
        name: 'Main');

    if (Firebase.apps.isEmpty) {
      print('🔥 [MAIN] Initializing Firebase...');
      developer.log('🔥 Initializing Firebase...', name: 'Main');
      await Firebase.initializeApp();
      print('✅ [MAIN] Firebase initialized successfully');
      developer.log('✅ Firebase initialized successfully', name: 'Main');
    } else {
      print('✅ [MAIN] Firebase already initialized');
      developer.log('✅ Firebase already initialized', name: 'Main');
    }

    print('🎯 [MAIN] Running FixIt App');
    developer.log('🎯 Running FixIt App', name: 'Main');
    runApp(const FixItApp());
  } catch (e, stackTrace) {
    print('❌ [MAIN] Error during app initialization: $e');
    developer.log('❌ Error during app initialization: $e',
        name: 'Main', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

class FixItApp extends StatelessWidget {
  const FixItApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('🔧 Building FixItApp widget', name: 'FixItApp');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          developer.log('🏗️ Creating AuthService provider', name: 'FixItApp');
          return AuthService();
        }),
        ChangeNotifierProvider(create: (_) {
          developer.log('🏗️ Creating ThemeService provider', name: 'FixItApp');
          return ThemeService();
        }),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          developer.log('🎨 Building MaterialApp with theme', name: 'FixItApp');
          return MaterialApp(
            title: 'FixIt',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2563EB),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2563EB),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/home': (context) => const HomePage(),
              '/interests': (context) => const InterestsPage(),
              '/vendor_home': (context) => const VendorHomePage(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔐 [AUTH] Building AuthWrapper');
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        print(
            '🔐 [AUTH] AuthService state - Loading: ${authService.isLoading}, User: ${authService.currentUser?.email ?? "null"}');

        if (authService.isLoading) {
          print('⏳ [AUTH] Showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.currentUser != null) {
          print('✅ [AUTH] User authenticated - showing HomePage');
          return const HomePage();
        }

        print('🔑 [AUTH] No user - showing LoginPage');
        return const LoginPage();
      },
    );
  }
}
