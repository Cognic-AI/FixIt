import 'package:fixit/pages/auth/account_type_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    print('[LOGIN] LoginPage initialized');
    developer.log('[LOGIN] LoginPage initialized', name: 'LoginPage');
    if (Provider.of<AuthService>(context, listen: false).currentUser != null) {
      print('[LOGIN] User already logged in - navigating to home');
      developer.log('[LOGIN] User already logged in - navigating to home',
          name: 'LoginPage');
      if (Provider.of<AuthService>(context, listen: false).currentUser!.role ==
          'client') {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/vendor_home');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  void dispose() {
    print('[LOGIN] LoginPage disposing controllers');
    developer.log('[LOGIN] LoginPage disposing controllers', name: 'LoginPage');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    print('[LOGIN] Login attempt started');
    developer.log('[LOGIN] Login attempt started', name: 'LoginPage');
    if (!_formKey.currentState!.validate()) {
      print('[LOGIN] Form validation failed');
      developer.log('[LOGIN] Form validation failed', name: 'LoginPage');
      return;
    }

    setState(() => _isLoading = true);
    print('[LOGIN] Setting loading state to true');
    developer.log('[LOGIN] Setting loading state to true', name: 'LoginPage');

    try {
      print(
          '[LOGIN] Attempting login with email: ${_emailController.text.trim()}');
      developer.log(
          '[LOGIN] Attempting login with email: ${_emailController.text.trim()}',
          name: 'LoginPage');
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        developer.log('[LOGIN] Login successful - navigating to home',
            name: 'LoginPage');
        authService.currentUser?.role == 'client'
            ? Navigator.pushReplacementNamed(context, '/home')
            : Navigator.pushReplacementNamed(context, '/vendor_home');
      }
    } catch (e) {
      print('[LOGIN] Login failed: $e');
      developer.log('[LOGIN] Login failed: $e', name: 'LoginPage', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        print('[LOGIN] Setting loading state to false');
        developer.log('[LOGIN] Setting loading state to false',
            name: 'LoginPage');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _devLogin(String userType) async {
    print('[LOGIN] Developer login attempt for $userType');
    developer.log('[LOGIN] Developer login attempt for $userType',
        name: 'LoginPage');

    setState(() => _isLoading = true);

    try {
      String email, password;
      if (userType == 'vendor') {
        email = 'sahan2@fixit.lk';
        password = 'sahan123';
      } else {
        email = 'nishan@fixit.lk';
        password = 'nishan123';
      }

      _emailController.text = email;
      _passwordController.text = password;

      print('[LOGIN] Attempting dev login with email: $email');
      developer.log('[LOGIN] Attempting dev login with email: $email',
          name: 'LoginPage');

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmailAndPassword(email, password);

      if (mounted) {
        developer.log(
            '[LOGIN] Dev login successful - navigating based on user type',
            name: 'LoginPage');
        if (userType == 'vendor') {
          Navigator.pushReplacementNamed(context, '/vendor_home');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('[LOGIN] Dev login failed: $e');
      developer.log('[LOGIN] Dev login failed: $e',
          name: 'LoginPage', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Dev Login Failed ($userType)'),
                      Text(
                        'Error: ${e.toString()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[LOGIN] Building LoginPage widget');
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF006FFD),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with logo and curved bottom
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006FFD),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo - using Image.asset instead of image.asset
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.width * 0.4,
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/logo-no-bg.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit
                              .contain, // Changed to contain to preserve aspect ratio
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom section with form
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Sign in title
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Welcome back! Please enter your details.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // Remember me and forgot password
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: false, // You can add state for this
                                    onChanged: (value) {
                                      // Handle remember me
                                    },
                                    activeColor: const Color(0xFF006FFD),
                                  ),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  // Handle forgot password
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF006FFD),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006FFD),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AccountTypePage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006FFD),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Developer Login Buttons
                          const Divider(),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Developer Quick Login',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _devLogin('vendor'),
                                  icon: const Icon(Icons.build, size: 18),
                                  label: const Text('Vendor'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF006FFD),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _devLogin('client'),
                                  icon: const Icon(Icons.person, size: 18),
                                  label: const Text('Client'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
