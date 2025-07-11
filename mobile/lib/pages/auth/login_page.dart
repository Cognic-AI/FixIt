import 'package:fixit/pages/auth/account_type_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
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
      if (Provider.of<AuthService>(context, listen: false)
              .currentUser!
              .userType ==
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
        authService.currentUser?.userType == 'client'
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
        email = 'sahan@fixit.lk';
        password = 'sahan123';
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.build_circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to your FixIt account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
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
                        const SizedBox(height: 16),

                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
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
                        const SizedBox(height: 24),

                        // Login Button
                        CustomButton(
                          text: 'Sign In',
                          onPressed: _isLoading ? null : _handleLogin,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
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
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Developer Login Buttons
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Developer Quick Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
          ),
        ),
      ),
    );
  }
}
