import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import 'edit_profile_page.dart';
import '../feedback_page.dart';
import '../auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _locationEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    developer.log('⚙️ Settings page initialized', name: 'SettingsPage');
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // User Profile Section
          if (user != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF7C3AED),
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(
                            '${user.firstName[0]}${user.lastName[0]}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      developer.log('✏️ Edit profile pressed', name: 'SettingsPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Account Settings Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              developer.log('🔒 Privacy & Security tapped', name: 'SettingsPage');
              _showPrivacyDialog(context);
            },
          ),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          _buildSettingsTile(
            icon: themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: 'Theme',
            subtitle: themeService.isDarkMode ? 'Dark mode' : 'Light mode',
            trailing: Switch(
              value: themeService.isDarkMode,
              onChanged: (value) {
                developer.log('🎨 Theme toggled to: ${value ? 'dark' : 'light'}', 
                    name: 'SettingsPage');
                themeService.toggleTheme();
              },
              activeColor: const Color(0xFF2563EB),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              developer.log('🌍 Language settings tapped', name: 'SettingsPage');
              _showLanguageDialog(context, themeService);
            },
          ),

          const SizedBox(height: 24),

          // Notification Settings Section
          _buildSectionHeader('Notifications'),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
                developer.log('🔔 Push notifications: $value', name: 'SettingsPage');
              },
              activeColor: const Color(0xFF2563EB),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            trailing: Switch(
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
                developer.log('📧 Email notifications: $value', name: 'SettingsPage');
              },
              activeColor: const Color(0xFF2563EB),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Location Services',
            subtitle: 'Allow location access for better service',
            trailing: Switch(
              value: _locationEnabled,
              onChanged: (value) {
                setState(() {
                  _locationEnabled = value;
                });
                developer.log('📍 Location services: $value', name: 'SettingsPage');
              },
              activeColor: const Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {
              developer.log('❓ Help Center tapped', name: 'SettingsPage');
              _showHelpDialog(context);
            },
          ),
          _buildSettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts with us',
            onTap: () {
              developer.log('💬 Feedback tapped', name: 'SettingsPage');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackPage(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              developer.log('ℹ️ About tapped', name: 'SettingsPage');
              _showAboutDialog(context);
            },
          ),

          const SizedBox(height: 24),

          // Account Actions Section
          _buildSectionHeader('Account Actions'),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            onTap: () {
              developer.log('🚪 Sign out tapped', name: 'SettingsPage');
              _showSignOutDialog(context, authService);
            },
            textColor: Colors.red,
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: textColor ?? const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: themeService.language,
              onChanged: (value) {
                if (value != null) {
                  themeService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Português'),
              value: 'pt',
              groupValue: themeService.language,
              onChanged: (value) {
                if (value != null) {
                  themeService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es',
              groupValue: themeService.language,
              onChanged: (value) {
                if (value != null) {
                  themeService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Privacy and security settings will be available in a future update. '
          'Your data is protected according to our privacy policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Text(
          'Need help? Contact our support team:\n\n'
          '📧 Email: support@fixit.com\n'
          '📱 Phone: +55 (81) 9999-9999\n'
          '💬 Chat: Available 24/7 in the app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FixIt'),
        content: const Text(
          'FixIt v1.0.0\n\n'
          'Connect with trusted service providers in your area.\n\n'
          'Developed with ❤️ for better local services.\n\n'
          '© 2024 FixIt. All rights reserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog first
              try {
                await authService.signOut();
                developer.log('✅ User signed out successfully', name: 'SettingsPage');
                // Navigate back to login and clear all previous routes
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                }
              } catch (e) {
                developer.log('❌ Error during sign out: $e', 
                    name: 'SettingsPage', error: e);
                // Show error message to user
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
