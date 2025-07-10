import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_page.dart';

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
    print('🔐 [LOGIN] LoginPage initialized');
    developer.log('🔐 LoginPage initialized', name: 'LoginPage');
  }

  @override
  void dispose() {
    print('🗑️ [LOGIN] LoginPage disposing controllers');
    developer.log('🗑️ LoginPage disposing controllers', name: 'LoginPage');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    print('🚀 [LOGIN] Login attempt started');
    developer.log('🚀 Login attempt started', name: 'LoginPage');
    if (!_formKey.currentState!.validate()) {
      print('❌ [LOGIN] Form validation failed');
      developer.log('❌ Form validation failed', name: 'LoginPage');
      return;
    }

    setState(() => _isLoading = true);
    print('⏳ [LOGIN] Setting loading state to true');
    developer.log('⏳ Setting loading state to true', name: 'LoginPage');

    try {
      print(
          '📧 [LOGIN] Attempting login with email: ${_emailController.text.trim()}');
      developer.log(
          '📧 Attempting login with email: ${_emailController.text.trim()}',
          name: 'LoginPage');
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        print('✅ [LOGIN] Login successful - navigating to home');
        developer.log('✅ Login successful - navigating to home',
            name: 'LoginPage');
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('❌ [LOGIN] Login failed: $e');
      developer.log('❌ Login failed: $e', name: 'LoginPage', error: e);
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
        print('⏹️ [LOGIN] Setting loading state to false');
        developer.log('⏹️ Setting loading state to false', name: 'LoginPage');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seedDatabase() async {
    print('🌱 [LOGIN] Starting Firestore database seeding directly');
    developer.log('🌱 Starting Firestore database seeding directly',
        name: 'LoginPage');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Seeding Firestore database...'),
          ],
        ),
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;
      print('� [LOGIN] Connected to Firestore');

      // Clear existing data first
      print('🗑️ [LOGIN] Clearing existing collections...');
      await _clearCollection(firestore, 'users');
      await _clearCollection(firestore, 'services');
      await _clearCollection(firestore, 'events');
      await _clearCollection(firestore, 'chats');
      await _clearCollection(firestore, 'messages');
      print('✅ [LOGIN] Existing collections cleared');

      // Seed Users
      print('👥 [LOGIN] Seeding users...');
      await _seedUsers(firestore);

      // Seed Services
      print('🏠 [LOGIN] Seeding services...');
      await _seedServices(firestore);

      // Seed Events
      print('🎉 [LOGIN] Seeding events...');
      await _seedEvents(firestore);

      // Seed Chats
      print('💬 [LOGIN] Seeding chats...');
      await _seedChats(firestore);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        print('✅ [LOGIN] Firestore database seeded successfully');
        developer.log('✅ Firestore database seeded successfully',
            name: 'LoginPage');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore database seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [LOGIN] Error during Firestore seeding: $e');
      developer.log('❌ Error during Firestore seeding: $e',
          name: 'LoginPage', error: e);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCollection(
      FirebaseFirestore firestore, String collectionName) async {
    print('🗑️ [LOGIN] Clearing $collectionName collection');
    try {
      final collection = firestore.collection(collectionName);
      final snapshot = await collection.get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ [LOGIN] $collectionName collection cleared');
    } catch (e) {
      print('⚠️ [LOGIN] Error clearing $collectionName: $e');
    }
  }

  Future<void> _seedUsers(FirebaseFirestore firestore) async {
    final users = [
      {
        'id': 'user_1',
        'firstName': 'Karen',
        'lastName': 'Roe',
        'email': 'karen.roe@example.com',
        'userType': 'vendor',
        'rating': 4.8,
        'reviewCount': 89,
        'location': 'Recife, Brazil',
        'verified': true,
        'avatar':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'user_2',
        'firstName': 'João',
        'lastName': 'Silva',
        'email': 'joao.silva@example.com',
        'userType': 'vendor',
        'rating': 4.6,
        'reviewCount': 45,
        'location': 'Olinda, Brazil',
        'verified': true,
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'user_3',
        'firstName': 'Lucas',
        'lastName': 'Scott',
        'email': 'test@fixit.lk',
        'userType': 'client',
        'rating': 0.0,
        'reviewCount': 0,
        'location': 'Recife, Brazil',
        'verified': false,
        'avatar':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final user in users) {
      await firestore.collection('users').doc(user['id'] as String).set(user);
    }
    print('✅ [LOGIN] Users seeded: ${users.length} users');
  }

  Future<void> _seedServices(FirebaseFirestore firestore) async {
    final services = [
      {
        'id': 'service_1',
        'title': 'Great Apartment',
        'description':
            'Perfect flat for 4 people. Peaceful and good location, close to bus stops and many restaurants.',
        'price': 150.0,
        'location': 'Recife, Brazil',
        'rating': 4.8,
        'reviewCount': 124,
        'hostId': 'user_1',
        'hostName': 'Karen Roe',
        'category': 'accommodation',
        'amenities': ['WiFi', 'Kitchen', 'Air Conditioning', 'Parking'],
        'imageUrl':
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400',
        'dates': 'Mar 12 – Mar 15',
        'active': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'service_2',
        'title': 'Cozy Studio',
        'description': 'Charming studio apartment in historic Olinda.',
        'price': 85.0,
        'location': 'Olinda, Brazil',
        'rating': 4.6,
        'reviewCount': 67,
        'hostId': 'user_2',
        'hostName': 'João Silva',
        'category': 'accommodation',
        'amenities': ['WiFi', 'Kitchen', 'Historic Location'],
        'imageUrl':
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400',
        'dates': 'Mar 20 – Mar 23',
        'active': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final service in services) {
      await firestore
          .collection('services')
          .doc(service['id'] as String)
          .set(service);
    }
    print('✅ [LOGIN] Services seeded: ${services.length} services');
  }

  Future<void> _seedEvents(FirebaseFirestore firestore) async {
    final events = [
      {
        'id': 'event_1',
        'title': 'Maroon 5',
        'description':
            'Don\'t miss Maroon 5 live in concert at Recife Arena! Experience their greatest hits.',
        'location': 'Recife Arena',
        'date': 'MAR 05',
        'time': '20:00',
        'price': 120.0,
        'category': 'CONCERTS',
        'capacity': 50000,
        'ticketsAvailable': 15000,
        'organizer': 'Live Nation Brazil',
        'imageUrl':
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        'active': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'event_2',
        'title': 'Alicia Keys',
        'description':
            'Live performance by Alicia Keys in the beautiful city of Olinda.',
        'location': 'Centro de Convenções',
        'date': 'MAR 05',
        'time': '19:00',
        'price': 95.0,
        'category': 'CONCERTS',
        'capacity': 25000,
        'ticketsAvailable': 8000,
        'organizer': 'Music Events Brazil',
        'imageUrl':
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        'active': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final event in events) {
      await firestore
          .collection('events')
          .doc(event['id'] as String)
          .set(event);
    }
    print('✅ [LOGIN] Events seeded: ${events.length} events');
  }

  Future<void> _seedChats(FirebaseFirestore firestore) async {
    final chats = [
      {
        'id': 'chat_1',
        'participants': ['user_1', 'user_3'],
        'serviceId': 'service_1',
        'lastMessage': {
          'content': 'Thanks for your help!',
          'senderId': 'user_3',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final chat in chats) {
      await firestore.collection('chats').doc(chat['id'] as String).set(chat);
    }

    // Seed messages for the chat
    final messages = [
      {
        'id': 'msg_1',
        'chatId': 'chat_1',
        'senderId': 'user_3',
        'senderName': 'Lucas',
        'content': 'Hi! I\'m interested in your apartment.',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'read': true,
        'messageType': 'text',
      },
      {
        'id': 'msg_2',
        'chatId': 'chat_1',
        'senderId': 'user_1',
        'senderName': 'Karen',
        'content': 'Hello! It\'s available for the dates you mentioned.',
        'timestamp':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'read': true,
        'messageType': 'text',
      },
      {
        'id': 'msg_3',
        'chatId': 'chat_1',
        'senderId': 'user_3',
        'senderName': 'Lucas',
        'content': 'Thanks for your help!',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'messageType': 'text',
      },
    ];

    for (final message in messages) {
      await firestore
          .collection('messages')
          .doc(message['id'] as String)
          .set(message);
    }

    print(
        '✅ [LOGIN] Chats seeded: ${chats.length} chats, ${messages.length} messages');
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 [LOGIN] Building LoginPage widget');
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
                                        const RegisterPage(userType: 'user'),
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

                        // Seed Database Button (Development Only)
                        OutlinedButton.icon(
                          onPressed: _seedDatabase,
                          icon: const Icon(Icons.cloud_upload,
                              color: Colors.orange),
                          label: const Text(
                            'Seed Database',
                            style: TextStyle(color: Colors.orange),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
