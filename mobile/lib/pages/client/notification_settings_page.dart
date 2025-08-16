import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // Service-related notifications
  bool _serviceRequests = true;
  bool _serviceUpdates = true;
  bool _serviceCompletion = true;
  bool _serviceReminders = true;

  // Account notifications
  bool _accountSecurity = true;
  bool _profileUpdates = false;
  bool _loginActivity = true;

  // Marketing notifications
  bool _promotions = false;
  bool _newsletters = true;
  bool _productUpdates = true;

  @override
  void initState() {
    super.initState();
    developer.log('Notification Settings page initialized',
        name: 'NotificationSettings');
    _loadSettings();
  }

  void _loadSettings() {
    // TODO: Load actual settings from backend/local storage
    // For now, using default values
  }

  void _saveSettings() {
    // TODO: Save settings to backend/local storage
    developer.log('Saving notification settings',
        name: 'NotificationSettings');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Methods
            _buildSectionHeader('Delivery Methods'),
            const SizedBox(height: 16),
            _buildDeliveryMethodsCard(),

            const SizedBox(height: 24),

            // Service Notifications
            _buildSectionHeader('Service Notifications'),
            const SizedBox(height: 16),
            _buildServiceNotificationsCard(),

            const SizedBox(height: 24),

            // Account Notifications
            _buildSectionHeader('Account & Security'),
            const SizedBox(height: 16),
            _buildAccountNotificationsCard(),

            const SizedBox(height: 24),

            // Marketing Notifications
            _buildSectionHeader('Marketing & Updates'),
            const SizedBox(height: 16),
            _buildMarketingNotificationsCard(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsCard(),

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

  Widget _buildDeliveryMethodsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNotificationItem(
              icon: Icons.notifications_active,
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Receive updates via email',
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.sms_outlined,
              title: 'SMS Notifications',
              subtitle: 'Receive text messages for urgent updates',
              value: _smsNotifications,
              onChanged: (value) {
                setState(() {
                  _smsNotifications = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNotificationItem(
              icon: Icons.request_page,
              title: 'Service Requests',
              subtitle: 'When providers respond to your requests',
              value: _serviceRequests,
              onChanged: (value) {
                setState(() {
                  _serviceRequests = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.update,
              title: 'Service Updates',
              subtitle: 'Progress updates on ongoing services',
              value: _serviceUpdates,
              onChanged: (value) {
                setState(() {
                  _serviceUpdates = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.check_circle,
              title: 'Service Completion',
              subtitle: 'When services are completed',
              value: _serviceCompletion,
              onChanged: (value) {
                setState(() {
                  _serviceCompletion = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.schedule,
              title: 'Service Reminders',
              subtitle: 'Upcoming service appointments',
              value: _serviceReminders,
              onChanged: (value) {
                setState(() {
                  _serviceReminders = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNotificationItem(
              icon: Icons.security,
              title: 'Security Alerts',
              subtitle: 'Login attempts and security changes',
              value: _accountSecurity,
              onChanged: (value) {
                setState(() {
                  _accountSecurity = value;
                });
              },
              isImportant: true,
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.person,
              title: 'Profile Updates',
              subtitle: 'Changes to your profile information',
              value: _profileUpdates,
              onChanged: (value) {
                setState(() {
                  _profileUpdates = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.login,
              title: 'Login Activity',
              subtitle: 'New sign-ins to your account',
              value: _loginActivity,
              onChanged: (value) {
                setState(() {
                  _loginActivity = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketingNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNotificationItem(
              icon: Icons.local_offer,
              title: 'Promotions & Offers',
              subtitle: 'Special deals and discounts',
              value: _promotions,
              onChanged: (value) {
                setState(() {
                  _promotions = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.newspaper,
              title: 'Newsletter',
              subtitle: 'Weekly updates and tips',
              value: _newsletters,
              onChanged: (value) {
                setState(() {
                  _newsletters = value;
                });
              },
            ),
            const Divider(),
            _buildNotificationItem(
              icon: Icons.system_update,
              title: 'Product Updates',
              subtitle: 'New features and improvements',
              value: _productUpdates,
              onChanged: (value) {
                setState(() {
                  _productUpdates = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enableAllNotifications,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Enable All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                    onPressed: _disableAllNotifications,
                    icon: const Icon(Icons.notifications_off),
                    label: const Text('Disable All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Defaults'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isImportant = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isImportant ? Colors.orange : const Color(0xFF2563EB))
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isImportant ? Colors.orange : const Color(0xFF2563EB),
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isImportant) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Important',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }

  void _enableAllNotifications() {
    setState(() {
      _pushNotifications = true;
      _emailNotifications = true;
      _serviceRequests = true;
      _serviceUpdates = true;
      _serviceCompletion = true;
      _serviceReminders = true;
      _accountSecurity = true;
      _profileUpdates = true;
      _loginActivity = true;
      _promotions = true;
      _newsletters = true;
      _productUpdates = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications enabled'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _disableAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Disable All Notifications'),
        content: const Text(
          'Are you sure you want to disable all notifications? '
          'You might miss important updates about your services and account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pushNotifications = false;
                _emailNotifications = false;
                _smsNotifications = false;
                _serviceRequests = false;
                _serviceUpdates = false;
                _serviceCompletion = false;
                _serviceReminders = false;
                _profileUpdates = false;
                _loginActivity = false;
                _promotions = false;
                _newsletters = false;
                _productUpdates = false;
                // Keep security notifications enabled for safety
                _accountSecurity = true;
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'All notifications disabled (except security alerts)'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable All'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _pushNotifications = true;
      _emailNotifications = true;
      _smsNotifications = false;
      _serviceRequests = true;
      _serviceUpdates = true;
      _serviceCompletion = true;
      _serviceReminders = true;
      _accountSecurity = true;
      _profileUpdates = false;
      _loginActivity = true;
      _promotions = false;
      _newsletters = true;
      _productUpdates = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
