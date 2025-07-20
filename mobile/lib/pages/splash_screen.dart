import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../services/auth_service.dart';
import 'auth/login_page.dart';
import 'home_page.dart';
import 'vendor/vendor_home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  
  String _loadingText = 'Loading...';

  @override
  void initState() {
    super.initState();
    developer.log('🚀 [SPLASH] Initializing splash screen', name: 'SplashScreen');
    
    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create animations
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations and initialization
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    try {
      // Start logo animation
      _logoController.forward();
      
      // Wait a bit then start fade animation
      await Future.delayed(const Duration(milliseconds: 500));
      _fadeController.forward();
      
      // Initialize services
      await _initializeApp();
      
      // Ensure minimum splash duration (for better UX)
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Navigate to appropriate screen
      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      developer.log('❌ [SPLASH] Error during initialization: $e', 
          name: 'SplashScreen', error: e);
      
      // Show error message and retry option
      setState(() {
        _loadingText = 'Connection error. Retrying...';
      });
      
      // Wait and retry once
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        try {
          await _initializeApp();
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            _navigateToNextScreen();
          }
        } catch (retryError) {
          developer.log('❌ [SPLASH] Retry failed: $retryError', 
              name: 'SplashScreen', error: retryError);
          // Final fallback - go to login
          setState(() {
            _loadingText = 'Starting app...';
          });
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
      }
    }
  }

  Future<void> _initializeApp() async {
    developer.log('⚙️ [SPLASH] Starting app initialization', name: 'SplashScreen');
    
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Update loading text
      setState(() {
        _loadingText = 'Checking authentication...';
      });
      
      // Load user profile (this already includes token loading)
      developer.log('👤 [SPLASH] Loading user profile', name: 'SplashScreen');
      await authService.loadUserProfile();

      // Update loading text
      setState(() {
        _loadingText = 'Almost ready...';
      });

      developer.log('✅ [SPLASH] App initialization completed successfully', name: 'SplashScreen');
    } catch (e) {
      developer.log('❌ [SPLASH] Error during app initialization: $e', 
          name: 'SplashScreen', error: e);
      setState(() {
        _loadingText = 'Finalizing...';
      });
    }
  }

  void _navigateToNextScreen() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser != null) {
      final user = authService.currentUser!;
      final token = authService.jwtToken ?? '';
      
      developer.log('✅ [SPLASH] User authenticated, navigating to ${user.role} home', 
          name: 'SplashScreen');
      
      if (user.role == 'vendor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VendorHomePage(user: user, token: token),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(user: user, token: token),
          ),
        );
      }
    } else {
      developer.log('🔑 [SPLASH] No user authenticated, navigating to login', 
          name: 'SplashScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563EB), // Primary blue color
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2563EB),
              const Color(0xFF1D4ED8),
              const Color(0xFF1E40AF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if logo doesn't load
                                return const Icon(
                                  Icons.build_rounded,
                                  size: 60,
                                  color: Color(0xFF2563EB),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Animated App Name and Tagline
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          const Text(
                            'FixIt',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 8,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Service Solution',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 80),
                
                // Loading Indicator
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _loadingText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Version or Footer Text (Optional)
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value * 0.6,
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
