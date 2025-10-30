import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class FloatingNavMenu extends StatefulWidget {
  final String currentRoute;
  const FloatingNavMenu({super.key, required this.currentRoute});

  @override
  State<FloatingNavMenu> createState() => _FloatingNavMenuState();
}

class _FloatingNavMenuState extends State<FloatingNavMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.qr_code_scanner,
      label: 'Scanner',
      route: '/scanner',
      color: Colors.blue,
    ),
    _NavItem(
      icon: Icons.analytics_outlined,
      label: 'Analysis',
      route: '/analysis',
      color: Colors.green,
    ),
    _NavItem(
      icon: Icons.people_alt_outlined,
      label: 'Records',
      route: '/records',
      color: Colors.orange,
    ),
    _NavItem(
      icon: Icons.qr_code,
      label: 'Generate',
      route: '/generate-qr',
      color: Colors.purple,
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      route: '/settings',
      color: Colors.grey,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _navigateToRoute(String route) {
    if (route != widget.currentRoute) {
      Navigator.of(context).pushReplacementNamed(route);
    }
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Semi-transparent overlay when menu is open
            if (_isOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),

            // Menu items
            ..._buildMenuItems(),

            // Main FAB
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'nav_fab_${widget.currentRoute}',
                onPressed: _toggleMenu,
                backgroundColor: AppColors.primary,
                child: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animation,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMenuItems() {
    final widgets = <Widget>[];
    for (int i = 0; i < _navItems.length; i++) {
      final item = _navItems[i];
      final isSelected = item.route == widget.currentRoute;

      widgets.add(
        Positioned(
          bottom: 20 + (i + 1) * 70 * _animation.value,
          right: 20,
          child: Transform.scale(
            scale: _animation.value,
            child: Opacity(
              opacity: _animation.value,
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: () => _navigateToRoute(item.route),
                backgroundColor: isSelected ? item.color : Colors.white,
                foregroundColor: isSelected ? Colors.white : item.color,
                icon: Icon(item.icon),
                label: Text(item.label),
                elevation: isSelected ? 8 : 4,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

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
      Navigator.of(context).pushReplacementNamed(route);
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
        IconButton(
          tooltip: 'Scan Student ID',
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => _nav(context, '/scanner'),
        ),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: (value) async {
            switch (value) {
              case '/scanner':
              case '/analysis':
              case '/records':
              case '/student_management':
              case '/generate-qr':
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
              value: '/scanner',
              child: ListTile(
                leading: Icon(Icons.qr_code_scanner),
                title: Text('Scanner'),
              ),
            ),
            PopupMenuItem(
              value: '/analysis',
              child: ListTile(
                leading: Icon(Icons.analytics_outlined),
                title: Text('Analysis'),
              ),
            ),
            PopupMenuItem(
              value: '/records',
              child: ListTile(
                leading: Icon(Icons.people_alt_outlined),
                title: Text('Records'),
              ),
            ),
            PopupMenuItem(
              value: '/student_management',
              child: ListTile(
                leading: Icon(Icons.school_outlined),
                title: Text('Student Management'),
              ),
            ),
            PopupMenuItem(
              value: '/generate-qr',
              child: ListTile(
                leading: Icon(Icons.qr_code),
                title: Text('Generate QR'),
              ),
            ),
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
