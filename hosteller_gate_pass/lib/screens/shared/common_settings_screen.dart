import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class CommonSettingsScreen extends StatefulWidget {
  const CommonSettingsScreen({Key? key}) : super(key: key);

  @override
  State<CommonSettingsScreen> createState() => _CommonSettingsScreenState();
}

class _CommonSettingsScreenState extends State<CommonSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _locationServices = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select App Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  themeProvider.setThemeMode(mode!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  themeProvider.setThemeMode(mode!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  themeProvider.setThemeMode(mode!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Malayalam'),
              onTap: () {
                _showSnackBar('Malayalam language support coming soon!');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Hindi'),
              onTap: () {
                _showSnackBar('Hindi language support coming soon!');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Old Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                _showSnackBar('Passwords do not match');
                return;
              }
              _showSnackBar('Password changed successfully!');
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showInformationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('App Theme'),
                  trailing: Text(themeProvider.themeName, style: const TextStyle(color: Colors.grey)),
                  onTap: _showThemeDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: const Text('English', style: TextStyle(color: Colors.grey)),
                  onTap: _showLanguageDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Push Notifications'),
                  trailing: Switch(
                    value: _pushNotifications, 
                    activeColor: const Color(0xFF5B61DB),
                    onChanged: (v) {
                      setState(() => _pushNotifications = v);
                      _showSnackBar('Push notifications ${v ? 'enabled' : 'disabled'}');
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email Notifications'),
                  trailing: Switch(
                    value: _emailNotifications, 
                    activeColor: const Color(0xFF5B61DB),
                    onChanged: (v) {
                      setState(() => _emailNotifications = v);
                      _showSnackBar('Email notifications ${v ? 'enabled' : 'disabled'}');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Security & Privacy'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showInformationDialog('Privacy Policy', 'Your data is securely stored and only used for gate pass processing. We do not share your information with third parties.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Location Services'),
                  trailing: Switch(
                    value: _locationServices, 
                    activeColor: const Color(0xFF5B61DB),
                    onChanged: (v) {
                      setState(() => _locationServices = v);
                      _showSnackBar('Location services ${v ? 'enabled' : 'disabled'}');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showInformationDialog('Help & Support', 'Reach out to support@gatepass.edu or visit the administrative office for assistance.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

