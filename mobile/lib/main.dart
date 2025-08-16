import 'package:fixit/pages/vendor/vendor_home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'pages/auth/login_page.dart';
import 'pages/home_page.dart';
import 'pages/onboarding/interests_page.dart';
import 'pages/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/vendor_service.dart';

void main() async {
  developer.log('Starting FixIt App', name: 'Main');
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('Flutter bindings initialized', name: 'Main');

  try {
    // Load environment variables first
    developer.log('Loading environment variables...', name: 'Main');
    await dotenv.load(fileName: ".env");
    developer.log('Environment variables loaded', name: 'Main');

    developer.log('[MAIN] Running FixIt App', name: 'Main');

    developer.log('Running FixIt App', name: 'Main');
    runApp(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => ThemeService()),
      ChangeNotifierProvider(create: (_) => VendorService()),
    ], child: const FixItApp()));
  } catch (e, stackTrace) {
    developer.log('Error during app initialization: $e',
        name: 'Main', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

class FixItApp extends StatelessWidget {
  const FixItApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('Building FixItApp widget', name: 'FixItApp');
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        developer.log('Building MaterialApp with theme', name: 'FixItApp');
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
          home: const SplashScreen(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginPage(),
            '/interests': (context) => const InterestsPage(userType: 'client'),
          },
          onGenerateRoute: (settings) {
            // Handle routes that need AuthService data
            switch (settings.name) {
              case '/home':
                return MaterialPageRoute(
                  builder: (context) {
                    final authService =
                        Provider.of<AuthService>(context, listen: false);
                    final user = authService.currentUser;
                    final token = authService.jwtToken;

                    if (user != null && token != null) {
                      return HomePage(user: user, token: token);
                    } else {
                      // If no user data, redirect to login
                      return const LoginPage();
                    }
                  },
                );
              case '/vendor_home':
                return MaterialPageRoute(
                  builder: (context) {
                    final authService =
                        Provider.of<AuthService>(context, listen: false);
                    final user = authService.currentUser;
                    final token = authService.jwtToken;

                    if (user != null && token != null) {
                      return VendorHomePage(user: user, token: token);
                    } else {
                      // If no user data, redirect to login
                      return const LoginPage();
                    }
                  },
                );
              default:
                return null;
            }
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('[AUTH] Building AuthWrapper', name: 'AuthWrapper');
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        developer.log(
            '[AUTH] AuthService state - Loading: ${authService.isLoading}, User: ${authService.currentUser?.email ?? "null"}',
            name: 'AuthWrapper');

        if (authService.isLoading) {
          developer.log('[AUTH] Showing loading screen', name: 'AuthWrapper');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.currentUser != null) {
          developer.log(
              '[AUTH] User authenticated - routing based on user type',
              name: 'AuthWrapper');
          final user = authService.currentUser!;
          if (user.role == 'vendor') {
            print('[AUTH] Vendor user - showing VendorHomePage');
            return VendorHomePage(
                user: user, token: authService.jwtToken ?? '');
          } else {
            print('[AUTH] Client user - showing HomePage');
            return HomePage(
              user: user,
              token: authService.jwtToken ?? '',
            );
          }
        }

        developer.log('[AUTH] No user - showing LoginPage',
            name: 'AuthWrapper');
        return const LoginPage();
      },
    );
  }
}
