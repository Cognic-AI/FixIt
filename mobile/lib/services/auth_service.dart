import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as app_user;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static final String _baseUrl =
      dotenv.env['AUTH_SERVICE_URL'] ?? 'http://localhost:8080/api/auth';
  String? _jwtToken;
  app_user.User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get jwtToken => _jwtToken;
  bool get isInitialized => _isInitialized;

  AuthService() {
    print('[AUTH_SERVICE] AuthService initialized');
    checkHealth();
    developer.log('AuthService initialized', name: 'AuthService');
    // Note: loadUserProfile will be called explicitly from SplashScreen
  }

  Future<void> checkHealth() async {
    try {
      final _ = await http.get(
        Uri.parse(
            "${(_baseUrl.split('/auth')[0]).replaceAll("8080", "8083")}/health"),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      developer.log('Error during initialization: $e',
          name: 'AuthService', error: e);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    print('[AUTH_SERVICE] Attempting sign in with email: $email');
    developer.log('Attempting sign in with email: $email', name: 'AuthService');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        await _storage.write(key: 'token', value: _jwtToken);
        if (data['user'] != null) {
          _currentUser = app_user.User.fromJson(data['user']);
        } else {
          _currentUser = null;
          developer.log('Login response missing user data',
              name: 'AuthService');
        }
        print('[AUTH_SERVICE] Login successful');
        developer.log('Login successful', name: 'AuthService');
      } else {
        developer.log('Login failed: ${response.body}', name: 'AuthService');
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      developer.log('Error during login: $e', name: 'AuthService', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'role': userType,
          'phoneNumber': phoneNumber,
          'location': "6.7879,79.8889"
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        _currentUser = app_user.User.fromJson(data['user']);
        await _storage.write(key: 'token', value: _jwtToken);

        developer.log('Registration successful', name: 'AuthService');
      } else {
        developer.log('Registration failed: ${response.body}',
            name: 'AuthService');
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      developer.log('Error during registration: $e',
          name: 'AuthService', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile() async {
    if (_isInitialized) {
      developer.log('[AUTH] Already initialized, skipping',
          name: 'AuthService');
      return;
    }

    if (_jwtToken == null) {
      _jwtToken = await _storage.read(key: 'token');
      if (_jwtToken == null) {
        developer.log(
            '[AUTH] No token found, marking as initialized without user',
            name: 'AuthService');
        _isInitialized = true;
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = app_user.User.fromJson(data);
        developer.log('User profile loaded', name: 'AuthService');
      } else {
        developer.log('Failed to load profile: ${response.body}',
            name: 'AuthService');
        // Clear invalid token
        _jwtToken = null;
        await _storage.delete(key: 'token');
      }
    } catch (e) {
      developer.log('Error loading profile: $e', name: 'AuthService', error: e);
      // Clear potentially invalid token on error
      _jwtToken = null;
      await _storage.delete(key: 'token');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _jwtToken = null;
    _currentUser = null;
    _isInitialized = false;
    await _storage.delete(key: 'token');
    notifyListeners();
  }

  // Password reset would need a backend endpoint, not implemented here
  Future<void> resetPassword(
      String oldPassword, String newPassword, String token) async {
    try {
      print('[AUTH_SERVICE] Attempting to change password');
      final response = await http.put(
        Uri.parse('$_baseUrl/changePassword'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      print('[AUTH_SERVICE] Password change response: ${response.body}');

      if (response.statusCode == 200) {
        print('[AUTH_SERVICE] Password change successful');
        developer.log('Password change successful', name: 'AuthService');
      } else {
        print('[AUTH_SERVICE] Failed to change password: ${response.body}');
        developer.log('Failed to change password: ${response.body}',
            name: 'AuthService');
        throw Exception('Failed to change password: ${response.body}');
      }
    } catch (e) {
      print('[AUTH_SERVICE] Error changing password: $e');
      developer.log('Error changing password: $e',
          name: 'AuthService', error: e);
      rethrow;
    }
  }
}
