import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/theme_service.dart';
import '../../widgets/common/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: const [
          TopActions(
            currentRoute: '/settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your app settings and configurations.',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // General Section
          _SettingsSection(
            title: 'GENERAL',
            children: [
              ListenableBuilder(
                listenable: ThemeService(),
                builder: (context, _) {
                  return _SettingsTile.switchTile(
                    title: 'Dark Mode',
                    icon: Icons.dark_mode_rounded,
                    iconColor: Colors.purple,
                    value: ThemeService().isDarkMode,
                    onChanged: (v) {
                      ThemeService().toggleTheme();
                    },
                  );
                },
              ),
              _SettingsTile.switchTile(
                title: 'Sound on Scan',
                icon: Icons.volume_up_rounded,
                iconColor: Colors.blue,
                value: true,
                onChanged: (v) {},
              ),
            ],
          ),

          // Scanner Section
          _SettingsSection(
            title: 'SCANNER',
            children: [
              _SettingsTile.navigation(
                title: 'Default Action',
                subtitle: 'Auto-detect',
                icon: Icons.touch_app_rounded,
                iconColor: Colors.orange,
                onTap: () {
                  // TODO: Show action picker
                },
              ),
              _SettingsTile.navigation(
                title: 'Duplicate Scan Window',
                subtitle: '10 seconds',
                icon: Icons.timer_rounded,
                iconColor: Colors.teal,
                onTap: () {
                  // TODO: Show duration picker
                },
              ),
            ],
          ),

          // Data Section
          _SettingsSection(
            title: 'DATA & SYNC',
            children: [
              _SettingsTile.switchTile(
                title: 'Auto-sync',
                icon: Icons.cloud_sync_rounded,
                iconColor: Colors.indigo,
                value: true,
                onChanged: (v) {},
              ),
              _SettingsTile.switchTile(
                title: 'Keep Records',
                icon: Icons.history_rounded,
                iconColor: Colors.green,
                value: true,
                onChanged: (v) {},
              ),
            ],
          ),

          // Account Section
          _SettingsSection(
            title: 'ACCOUNT',
            children: [
              _SettingsTile.action(
                title: 'Log Out',
                icon: Icons.logout_rounded,
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () async {
                  try {
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logout failed: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Divider(
                      height: 1,
                      color: isDark
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile._({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.textColor,
    this.trailing,
    this.onTap,
  });

  factory _SettingsTile.switchTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _SettingsTile._(
      title: title,
      icon: icon,
      iconColor: iconColor,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
      ),
    );
  }

  factory _SettingsTile.navigation({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return _SettingsTile._(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
    );
  }

  factory _SettingsTile.action({
    required String title,
    required IconData icon,
    required Color iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return _SettingsTile._(
      title: title,
      icon: icon,
      iconColor: iconColor,
      textColor: textColor,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
