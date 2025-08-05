import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../services/auth_service.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key, required this.token});

  final String token;

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _twoFactorEnabled = false;
  bool _loginNotifications = true;
  bool _profileVisibility = true;
  bool _dataSharing = false;
  bool _activityTracking = true;

  @override
  void initState() {
    super.initState();
    developer.log('🔒 Privacy & Security page initialized',
        name: 'PrivacyPage');
    _loadSettings();
  }

  void _loadSettings() {
    // TODO: Load actual settings from backend
    setState(() {
      _twoFactorEnabled = false;
      _loginNotifications = true;
      _profileVisibility = true;
      _dataSharing = false;
      _activityTracking = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy & Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Section
            _buildSectionHeader('Security'),
            const SizedBox(height: 16),
            _buildSecurityCard(),

            const SizedBox(height: 24),

            // Privacy Section
            _buildSectionHeader('Privacy Settings'),
            const SizedBox(height: 16),
            _buildPrivacyCard(),

            const SizedBox(height: 24),

            // Data Management Section
            _buildSectionHeader('Data Management'),
            const SizedBox(height: 16),
            _buildDataManagementCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account password',
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.security,
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              trailing: Switch(
                value: _twoFactorEnabled,
                onChanged: _toggleTwoFactor,
                activeColor: const Color(0xFF2563EB),
              ),
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.notifications_active,
              title: 'Login Notifications',
              subtitle: 'Get notified of new sign-ins',
              trailing: Switch(
                value: _loginNotifications,
                onChanged: (value) {
                  setState(() {
                    _loginNotifications = value;
                  });
                  _showSnackBar(
                    'Login notifications ${value ? 'enabled' : 'disabled'}',
                    Colors.green,
                  );
                },
                activeColor: const Color(0xFF2563EB),
              ),
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.history,
              title: 'Login History',
              subtitle: 'View your recent login activity',
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLoginHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingItem(
              icon: Icons.visibility,
              title: 'Profile Visibility',
              subtitle: 'Control who can see your profile',
              trailing: Switch(
                value: _profileVisibility,
                onChanged: (value) {
                  setState(() {
                    _profileVisibility = value;
                  });
                  _showSnackBar(
                    'Profile is now ${value ? 'public' : 'private'}',
                    Colors.green,
                  );
                },
                activeColor: const Color(0xFF2563EB),
              ),
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.share,
              title: 'Data Sharing',
              subtitle: 'Share data to improve services',
              trailing: Switch(
                value: _dataSharing,
                onChanged: (value) {
                  setState(() {
                    _dataSharing = value;
                  });
                  _showSnackBar(
                    'Data sharing ${value ? 'enabled' : 'disabled'}',
                    Colors.green,
                  );
                },
                activeColor: const Color(0xFF2563EB),
              ),
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.track_changes,
              title: 'Activity Tracking',
              subtitle: 'Track app usage for better experience',
              trailing: Switch(
                value: _activityTracking,
                onChanged: (value) {
                  setState(() {
                    _activityTracking = value;
                  });
                  _showSnackBar(
                    'Activity tracking ${value ? 'enabled' : 'disabled'}',
                    Colors.green,
                  );
                },
                activeColor: const Color(0xFF2563EB),
              ),
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.block,
              title: 'Blocked Users',
              subtitle: 'Manage blocked service providers',
              trailing: const Icon(Icons.chevron_right),
              onTap: _showBlockedUsers,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingItem(
              icon: Icons.download,
              title: 'Download Your Data',
              subtitle: 'Get a copy of your data',
              trailing: const Icon(Icons.chevron_right),
              onTap: _downloadData,
            ),
            const Divider(),
            _buildSettingItem(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              trailing: const Icon(Icons.chevron_right),
              onTap: _showDeleteAccountDialog,
              textColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? const Color(0xFF2563EB)).withOpacity(0.1),
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
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _changePassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Text('Change Password'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: oldPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_open_outlined),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        helperText:
                            'At least 8 characters with letters and numbers',
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (oldPasswordController.text.isEmpty ||
                              newPasswordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty) {
                            setState(() {
                              errorMessage = 'All fields are required.';
                            });
                            return;
                          }

                          if (newPasswordController.text.length < 8) {
                            setState(() {
                              errorMessage =
                                  'New password must be at least 8 characters long.';
                            });
                            return;
                          }

                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            setState(() {
                              errorMessage = 'New passwords do not match.';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final authService = Provider.of<AuthService>(
                                context,
                                listen: false);
                            await authService.resetPassword(
                              oldPasswordController.text,
                              newPasswordController.text,
                              widget.token,
                            );

                            Navigator.pop(context);
                            _showSnackBar(
                                'Password changed successfully!', Colors.green);
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage =
                                  'Failed to change password. Please check your current password and try again.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleTwoFactor(bool value) {
    if (value) {
      _showTwoFactorSetupDialog();
    } else {
      _showTwoFactorDisableDialog();
    }
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text('Enable Two-Factor Authentication'),
          ],
        ),
        content: const Text(
          'Two-factor authentication adds an extra layer of security to your account. '
          'You\'ll need to enter a code from your authenticator app each time you sign in.\n\n'
          'This feature will be available in the next update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Two-factor authentication will be available soon!',
                  Colors.blue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Disable Two-Factor Authentication'),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? '
          'This will make your account less secure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _twoFactorEnabled = false;
              });
              Navigator.pop(context);
              _showSnackBar(
                  'Two-factor authentication disabled', Colors.orange);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showLoginHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.history, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text('Login History'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLoginHistoryItem(
                'Current Session',
                'Now',
                'Mobile App',
                true,
              ),
              _buildLoginHistoryItem(
                'Today',
                '2 hours ago',
                'Mobile App',
                false,
              ),
              _buildLoginHistoryItem(
                'Yesterday',
                '1 day ago',
                'Web Browser',
                false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistoryItem(
      String date, String time, String device, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF2563EB).withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? const Color(0xFF2563EB) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            device.contains('Mobile') ? Icons.phone_android : Icons.computer,
            color: isCurrent ? const Color(0xFF2563EB) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCurrent ? const Color(0xFF2563EB) : Colors.black87,
                  ),
                ),
                Text(
                  '$time • $device',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBlockedUsers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.block, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text('Blocked Users'),
          ],
        ),
        content: const SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No Blocked Users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You haven\'t blocked any service providers.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.download, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text('Download Your Data'),
          ],
        ),
        content: const Text(
          'We\'ll prepare a downloadable file containing all your data including:\n\n'
          '• Profile information\n'
          '• Service history\n'
          '• Messages and reviews\n'
          '• Account settings\n\n'
          'You\'ll receive an email with the download link within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(
                  'Data export request submitted. Check your email in 24 hours.',
                  Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();
    bool isConfirmed = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Delete Account'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action cannot be undone. Deleting your account will:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Permanently delete all your data\n'
                    '• Remove your service history\n'
                    '• Cancel all pending requests\n'
                    '• Delete all messages and reviews',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type "DELETE" to confirm:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Type DELETE here',
                    ),
                    onChanged: (value) {
                      setState(() {
                        isConfirmed = value.toUpperCase() == 'DELETE';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isConfirmed
                      ? () {
                          Navigator.pop(context);
                          _showSnackBar(
                              'Account deletion scheduled. You have 30 days to cancel.',
                              Colors.orange);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
