import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

/// Top-right actions for AppBar: full app menu + scan shortcut + logout.
class TopActions extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onScan;

  const TopActions({
    super.key,
    required this.currentRoute,
    this.onScan,
  });

  void _nav(BuildContext context, String route) {
    if (route != currentRoute) {
      Navigator.of(context).pushNamed(route);
    } else if (route == '/scanner' && onScan != null) {
      onScan!.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ready to scan. Type or scan now.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: (value) async {
            switch (value) {
              case '/settings':
                _nav(context, value);
                break;
              case 'logout':
                await SupabaseService.signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                }
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: '/settings',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Settings'),
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
