import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _searchController = TextEditingController();
  final List<Student> _students = [
    Student(
      id: 'S-0001',
      name: 'Juan Dela Cruz',
      section: 'Grade 7-A',
      lrn: 'CH-AE-NTAS',
    ),
    Student(
      id: 'S-0002',
      name: 'Maria Santos',
      section: 'Grade 7-A',
      lrn: 'CH-AE-NTBS',
    ),
    Student(
      id: 'S-0003',
      name: 'Pedro Reyes',
      section: 'Grade 7-B',
      lrn: 'CH-AE-NTCS',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> get _filteredStudents {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _students;
    return _students
        .where((student) =>
            student.name.toLowerCase().contains(query) ||
            student.id.toLowerCase().contains(query) ||
            student.lrn.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or LRN',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Students List
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      'No students found',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(student);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add student functionality coming soon'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
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
                AppColors.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              student.name.split(' ').first[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          student.name,
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
                  'ID: ${student.id}',
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
                  student.section,
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
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class Student {
  final String id;
  final String name;
  final String section;
  final String lrn;

  Student({
    required this.id,
    required this.name,
    required this.section,
    required this.lrn,
  });
}
