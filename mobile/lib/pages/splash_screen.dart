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
  String _loadingText = 'Loading...';
  
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late AnimationController _backgroundController;
  
  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _loadingOpacity;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    developer.log('[SPLASH] Initializing splash screen', name: 'SplashScreen');
    
    _initializeAnimations();
    _startAnimationSequence();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Loading animations
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _loadingOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeIn,
    ));

    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _backgroundOpacity = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for loading indicator
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    // Start background animation
    _backgroundController.repeat(reverse: true);
    
    // Start logo animation immediately
    _logoController.forward();
    
    // Start text animation after logo starts
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _textController.forward();
    }
    
    // Start loading animation after text
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _loadingController.forward();
    }
  }

  Future<void> _startSplashSequence() async {
    try {
      // Initialize services
      await _initializeApp();
      
      // Ensure minimum splash duration (for better UX)
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Navigate to appropriate screen
      if (mounted) {
        await _exitAnimation();
        _navigateToNextScreen();
      }
    } catch (e) {
      developer.log('[SPLASH] Error during initialization: $e', 
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
            await _exitAnimation();
            _navigateToNextScreen();
          }
        } catch (retryError) {
          developer.log('[SPLASH] Retry failed: $retryError', 
              name: 'SplashScreen', error: retryError);
          // Final fallback - go to login
          setState(() {
            _loadingText = 'Starting app...';
          });
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            await _exitAnimation();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
      }
    }
  }

  Future<void> _exitAnimation() async {
    // Reverse all animations for smooth exit
    await Future.wait([
      _loadingController.reverse(),
      _textController.reverse(),
      _logoController.reverse(),
    ]);
  }

  Future<void> _initializeApp() async {
    developer.log('[SPLASH] Starting app initialization', name: 'SplashScreen');
    
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Update loading text with animation
      setState(() {
        _loadingText = 'Checking authentication...';
      });
      
      // Load user profile (this already includes token loading)
      developer.log('[SPLASH] Loading user profile', name: 'SplashScreen');
      await authService.loadUserProfile();

      // Update loading text
      setState(() {
        _loadingText = 'Almost ready...';
      });

      developer.log('[SPLASH] App initialization completed successfully', name: 'SplashScreen');
    } catch (e) {
      developer.log('[SPLASH] Error during app initialization: $e', 
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
      
      developer.log('[SPLASH] User authenticated, navigating to ${user.role} home', 
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
      developer.log('[SPLASH] No user authenticated, navigating to login', 
          name: 'SplashScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _textController,
        _loadingController,
        _backgroundController,
      ]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Color.lerp(
            const Color(0xFF006FFD).withOpacity(0.8),
            const Color(0xFF006FFD),
            _backgroundOpacity.value,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF006FFD),
                  Color.lerp(
                    const Color(0xFF006FFD),
                    const Color(0xFF0056CC),
                    _backgroundOpacity.value,
                  ) ?? const Color(0xFF0056CC),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  Transform.scale(
                    scale: _logoScale.value,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: Image.asset(
                          'assets/images/logo-no-bg.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.build_rounded,
                              size: 60,
                              color: Colors.white.withOpacity(_logoOpacity.value),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Animated Tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Text(
                        'A one-step solution',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.9 * _textOpacity.value),
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Animated Loading Indicator
                  FadeTransition(
                    opacity: _loadingOpacity,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9 * _loadingOpacity.value),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Animated Loading Text
                  FadeTransition(
                    opacity: _loadingOpacity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _loadingText,
                        key: ValueKey(_loadingText),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8 * _loadingOpacity.value),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Animated Version Text
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5 * _textOpacity.value),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}