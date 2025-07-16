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
import 'services/vendor_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {

  developer.log('🚀 Starting FixIt App', name: 'Main');
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('✅ Flutter bindings initialized', name: 'Main');

  try {
    // Load environment variables first
    developer.log('📄 Loading environment variables...', name: 'Main');
    await dotenv.load(fileName: ".env");
    developer.log('✅ Environment variables loaded', name: 'Main');

    // Check if Firebase is already initialized before trying to initialize it again
    developer.log('🔥 Checking Firebase initialization status...',
        name: 'Main');

    if (Firebase.apps.isEmpty) {
      developer.log('🔥 Initializing Firebase...', name: 'Main');
      await Firebase.initializeApp();
      developer.log('✅ Firebase initialized successfully', name: 'Main');
    } else {
      developer.log('✅ Firebase already initialized', name: 'Main');
    }
    developer.log('🎯 Running FixIt App', name: 'Main');
    runApp(const FixItApp());
  } catch (e, stackTrace) {
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
        ChangeNotifierProvider(create: (_) {
          developer.log('🏗️ Creating VendorService provider',
              name: 'FixItApp');
          return VendorService();
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
    developer.log('🔐 [AUTH] Building AuthWrapper', name: 'AuthWrapper');
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        developer.log(
            '🔐 [AUTH] AuthService state - Loading: ${authService.isLoading}, User: ${authService.currentUser?.email ?? "null"}', name: 'AuthWrapper');

        if (authService.isLoading) {
          developer.log('⏳ [AUTH] Showing loading screen', name: 'AuthWrapper');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.currentUser != null) {
          developer.log('✅ [AUTH] User authenticated - routing based on user type', name: 'AuthWrapper');
          final user = authService.currentUser!;
          if (user.userType == 'vendor') {
            developer.log('🏢 [AUTH] Vendor user - showing VendorHomePage', name: 'AuthWrapper');
            return const VendorHomePage();
          } else {
            developer.log('👤 [AUTH] Client user - showing HomePage', name: 'AuthWrapper');
            return const HomePage();
          }
        }

        developer.log('🔑 [AUTH] No user - showing LoginPage', name: 'AuthWrapper');
        return const LoginPage();
      },
    );
  }
}
