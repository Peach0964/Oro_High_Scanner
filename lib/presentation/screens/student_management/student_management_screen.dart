import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/app_drawer.dart';
import '../records/records_screen.dart'; // Import shared User model
import '../../../core/services/supabase_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _searchController = TextEditingController();
  final List<User> _users = [];
  // New data structure for hierarchical view: Map<YearLevel, Map<Section, List<User>>>
  Map<String, Map<String, List<User>>> _groupedUsers = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    if (!mounted) return;
    if (!SupabaseService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase not configured.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final rows = await SupabaseService.fetchStudents();
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(() => _loading = false);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('No users found in Supabase.'),
        //     backgroundColor: AppColors.error,
        //   ),
        // );
        return;
      }
      setState(() {
        _users
          ..clear()
          ..addAll(rows.map((r) {
            return User(
              // Map new fields to the existing User model
              id: (r['lrn'] ?? r['id'] ?? '').toString(),
              name: (r['full_name'] ?? r['name'] ?? 'Unnamed').toString(),
              // Provide fallbacks for fields that may have been removed
              grade: (r['grade'] ?? '').toString(),
              section: (r['section'] ?? '').toString(),
              parentMobile: (r['parentMobile'] ?? '').toString(),
            );
          }));

        // Group users for hierarchical view
        _groupedUsers = {};
        for (var user in _users) {
          final grade =
              user.grade.isNotEmpty ? 'Grade ${user.grade}' : 'Ungraded';
          final section = user.section.isNotEmpty ? user.section : 'No Section';

          // Ensure year level map exists
          _groupedUsers.putIfAbsent(grade, () => {});
          // Ensure section list exists
          _groupedUsers[grade]!.putIfAbsent(section, () => []);
          // Add user to the section list
          _groupedUsers[grade]![section]!.add(user);
        }
        _loading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Loaded ${_users.length} users from Supabase'),
      //     backgroundColor: AppColors.primary,
      //   ),
      // );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load users from Supabase'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportToCSV() async {
    try {
      // Create CSV data
      List<List<String>> csvData = [
        ['LRN', 'Name', 'Section', 'Grade'], // Header row
        ..._users.map(
          (user) => [user.id, user.name, user.section, user.grade],
        ),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'users_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      // Write CSV to file
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Users exported to ${file.path}'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () async {
                // Try to open the directory
                // Note: This might not work on all platforms
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<User> get _filteredUsers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _users;
    return _users
        .where((user) =>
            user.name.toLowerCase().contains(query) ||
            user.id.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget _buildHierarchicalStudentList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_groupedUsers.isEmpty) {
      return Center(
        child: Text('No users found',
            style: TextStyle(color: AppColors.textMedium, fontSize: 16)),
      );
    }

    final yearLevels = _groupedUsers.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: yearLevels.length,
      itemBuilder: (context, index) {
        final yearLevel = yearLevels[index];
        final sections = _groupedUsers[yearLevel]!;
        final sectionNames = sections.keys.toList()..sort();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const Icon(Icons.school, color: AppColors.primary),
            title: Text(
              yearLevel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children: sectionNames.map((sectionName) {
              final userList = sections[sectionName]!;
              return ExpansionTile(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Icon(Icons.class_, color: AppColors.textMedium),
                ),
                title: Text(
                  sectionName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text('${userList.length} users'),
                children:
                    userList.map((user) => _buildStudentCard(user)).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFilteredList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredUsers;

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty
              ? 'No users match your search'
              : 'No users found',
          style: TextStyle(color: AppColors.textMedium, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        return _buildStudentCard(user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadFromSupabase,
          ),
          const TopActions(
            currentRoute: '/student_management',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'export',
            backgroundColor: AppColors.primary,
            onPressed: _exportToCSV,
            child: const Icon(Icons.download),
            tooltip: 'Export to CSV',
          ),
          const SizedBox(height: 16),
          FloatingNavMenu(currentRoute: '/student_management'),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Students List (Conditional View)
          Expanded(
              child: isSearching
                  ? _buildFilteredList()
                  : _buildHierarchicalStudentList()),
        ],
      ),
    );
  }

  Widget _buildStudentCard(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name.split(' ').first[0] : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: AppColors.textMedium),
                const SizedBox(width: 4),
                Text(
                  'LRN: ${user.id}',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.class_, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  user.section,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Edit ${user.name}'),
                  backgroundColor: AppColors.primary,
                ),
              );
            } else if (value == 'delete') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delete ${user.name}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
