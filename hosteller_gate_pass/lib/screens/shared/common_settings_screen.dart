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
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('App Theme',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _themeOption(context, themeProvider, ThemeMode.light, 'Light',
                      Icons.light_mode_outlined, setDialogState),
                  _themeOption(context, themeProvider, ThemeMode.dark, 'Dark',
                      Icons.dark_mode_outlined, setDialogState),
                  _themeOption(
                      context,
                      themeProvider,
                      ThemeMode.system,
                      'System Default',
                      Icons.brightness_auto_outlined,
                      setDialogState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeOption(BuildContext context, ThemeProvider themeProvider,
      ThemeMode mode, String label, IconData icon, StateSetter setDialogState) {
    final isSelected = themeProvider.themeMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        themeProvider.setThemeMode(mode);
        setDialogState(() {});
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? primaryColor
                    : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal)),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 18),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Language',
            style: TextStyle(fontWeight: FontWeight.w600)),
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(
                context, 'English', '🇬🇧', () => Navigator.pop(context)),
            _languageOption(context, 'Malayalam', '🇮🇳', () {
              Navigator.pop(context);
              _showSnackBar('Malayalam language support coming soon!');
            }),
            _languageOption(context, 'Hindi', '🇮🇳', () {
              Navigator.pop(context);
              _showSnackBar('Hindi language support coming soon!');
            }),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
      BuildContext context, String label, String flag, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showInformationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF1E3A8A);
    final accentColor = const Color(0xFF5B61DB);

    final cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final cardBorderColor =
        isDark ? const Color(0xFF2E2E3E) : Colors.grey.shade200;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final sectionHeaderColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final titleColor = isDark ? Colors.white : primaryColor;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your preferences and account',
                    style: TextStyle(fontSize: 13.5, color: subtitleColor),
                  ),
                ],
              ),
            ),

            // Preferences Section
            _sectionLabel('Preferences', sectionHeaderColor),
            _settingsCard(
              isDark: isDark,
              cardColor: cardColor,
              borderColor: cardBorderColor,
              children: [
                _settingsTile(
                  icon: Icons.palette_outlined,
                  iconColor: accentColor,
                  title: 'App Theme',
                  trailing:
                      _badge(themeProvider.themeName, subtitleColor, isDark),
                  onTap: _showThemeDialog,
                  theme: theme,
                ),
                _divider(isDark),
                _settingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF0891B2),
                  title: 'Language',
                  trailing: _badge('English', subtitleColor, isDark),
                  onTap: _showLanguageDialog,
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Notifications Section
            _sectionLabel('Notifications', sectionHeaderColor),
            _settingsCard(
              isDark: isDark,
              cardColor: cardColor,
              borderColor: cardBorderColor,
              children: [
                _switchTile(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFFD97706),
                  title: 'Push Notifications',
                  subtitle: 'Receive alerts on your device',
                  value: _pushNotifications,
                  accentColor: accentColor,
                  onChanged: (v) {
                    setState(() => _pushNotifications = v);
                    _showSnackBar(
                        'Push notifications ${v ? 'enabled' : 'disabled'}');
                  },
                  theme: theme,
                  isDark: isDark,
                ),
                _divider(isDark),
                _switchTile(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF059669),
                  title: 'Email Notifications',
                  subtitle: 'Get updates in your inbox',
                  value: _emailNotifications,
                  accentColor: accentColor,
                  onChanged: (v) {
                    setState(() => _emailNotifications = v);
                    _showSnackBar(
                        'Email notifications ${v ? 'enabled' : 'disabled'}');
                  },
                  theme: theme,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Security & Privacy Section
            _sectionLabel('Security & Privacy', sectionHeaderColor),
            _settingsCard(
              isDark: isDark,
              cardColor: cardColor,
              borderColor: cardBorderColor,
              children: [
                _settingsTile(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Privacy Policy',
                  onTap: () => _showInformationDialog(
                    'Privacy Policy',
                    'Your data is securely stored and only used for gate pass processing. We do not share your information with third parties.',
                  ),
                  theme: theme,
                ),
                _divider(isDark),
                _switchTile(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Location Services',
                  subtitle: 'Allow access to your location',
                  value: _locationServices,
                  accentColor: accentColor,
                  onChanged: (v) {
                    setState(() => _locationServices = v);
                    _showSnackBar(
                        'Location services ${v ? 'enabled' : 'disabled'}');
                  },
                  theme: theme,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // About Section
            _sectionLabel('About', sectionHeaderColor),
            _settingsCard(
              isDark: isDark,
              cardColor: cardColor,
              borderColor: cardBorderColor,
              children: [
                _settingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF0369A1),
                  title: 'App Version',
                  trailing: _badge('v1.0.0', subtitleColor, isDark),
                  theme: theme,
                ),
                _divider(isDark),
                _settingsTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF0891B2),
                  title: 'Help & Support',
                  onTap: () => _showInformationDialog(
                    'Help & Support',
                    'Reach out to support@gatepass.edu or visit the administrative office for assistance.',
                  ),
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final iconBg = iconColor.withOpacity(0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor)),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right_rounded,
                  color: theme.iconTheme.color?.withOpacity(0.4), size: 20),
            if (onTap != null && trailing != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: theme.iconTheme.color?.withOpacity(0.4), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    required bool isDark,
  }) {
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleTextColor =
        isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final iconBg = iconColor.withOpacity(0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: subtitleTextColor)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: accentColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor:
                  isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12.5, color: textColor, fontWeight: FontWeight.w500)),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      endIndent: 0,
      color:
          isDark ? Colors.grey.shade800.withOpacity(0.6) : Colors.grey.shade100,
    );
  }
}
