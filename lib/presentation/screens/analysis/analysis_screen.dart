import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../widgets/common/app_drawer.dart';
import '../../../core/services/supabase_service.dart';

class Student {
  final String id, name, grade, section;
  final String? parentMobile;
  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    this.parentMobile,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'section': section,
        'parentMobile': parentMobile,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        name: json['name'],
        grade: json['grade'],
        section: json['section'],
        parentMobile: json['parentMobile'],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StudentsRepository {
  StudentsRepository._();
  static final instance = StudentsRepository._();
  final List<Student> _cache = [];
  List<Student> get students => List.unmodifiable(_cache);

  Future<void> load() async {
    _cache.clear();
    if (kIsWeb) {
      // For web, use localStorage or similar web-compatible storage
      await _loadDefault();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/master_students.json');

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _cache.addAll(jsonList.map((e) => Student.fromJson(e)));
      } catch (e) {
        await _loadDefault();
      }
    } else {
      await _loadDefault();
    }
    await save();
  }

  Future<void> _loadDefault() async {
    _cache.addAll([
      const Student(
        id: "114479180164",
        name: "BALTAZAR, KIM GABRIEL, REGALARIO",
        grade: "7",
        section: "Fort Santiago",
        parentMobile: "+639171234567",
      ),
      const Student(
        id: "114479180022",
        name: "BEQUILLO, JULIAN MATTHEW, CASTILLO",
        grade: "7",
        section: "Fort Santiago",
        parentMobile: "+639171234568",
      ),
      const Student(
        id: "403853160005",
        name: "SAMPLE STUDENT ONE",
        grade: "7",
        section: "Section A",
        parentMobile: "+639123456789",
      ),
      const Student(
        id: "6970009245457",
        name: "SAMPLE STUDENT TWO",
        grade: "8",
        section: "Section B",
        parentMobile: "+639123456780",
      ),
      const Student(
        id: "N528A0230322",
        name: "SAMPLE STUDENT THREE",
        grade: "9",
        section: "Section C",
        parentMobile: "+639123456781",
      ),
      const Student(
        id: "CH-AE-NTAS",
        name: "SAMPLE STUDENT FOUR",
        grade: "10",
        section: "Section D",
        parentMobile: "+639123456782",
      ),
    ]);
  }

  Future<void> save() async {
    if (kIsWeb) {
      // For web, use localStorage or similar web-compatible storage
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/master_students.json');
    final jsonList = _cache.map((e) => e.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<void> create(Student s) async {
    _cache.add(s);
    await save();
  }

  Future<void> update(String oldId, Student newS) async {
    final index = _cache.indexWhere((e) => e.id == oldId);
    if (index == -1) return;
    _cache[index] = newS;
    await save();
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((e) => e.id == id);
    await save();
  }

  Future<File> export() async {
    if (kIsWeb) {
      throw UnsupportedError('File export not supported on web');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/students_export_${DateTime.now().millisecondsSinceEpoch}.json');
    final jsonList = _cache.map((e) => e.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
    return file;
  }
}

class AnalysisPage extends StatefulWidget {
  final List<Map<String, String>> logs;
  final Student? lastStudent;
  const AnalysisPage({super.key, required this.logs, this.lastStudent});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String _searchQuery = '';
  String _selectedGrade = 'All';
  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    // 1) Start with any local cache so UI is not empty
    setState(() {
      _students = StudentsRepository.instance.students;
      _filterStudents();
    });

    // 2) If Supabase is configured, try to fetch remote students and replace
    if (SupabaseService.isConfigured) {
      try {
        final rows = await SupabaseService.fetchStudents();
        if (rows.isNotEmpty && mounted) {
          final remote = rows.map((r) {
            return Student(
              id: (r['id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
              grade: (r['grade'] ?? '').toString(),
              section: (r['section'] ?? '').toString(),
              parentMobile: r['parent_mobile']?.toString(),
            );
          }).toList();

          setState(() {
            _students = remote;
            _filterStudents();
          });
        }
      } catch (_) {
        // Ignore fetch errors to keep local data visible
      }
    }
  }

  void _filterStudents() {
    final query = _searchQuery.toLowerCase().trim();

    setState(() {
      _filteredStudents = _students.where((student) {
        final matchesSearch = query.isEmpty ||
            student.id.toLowerCase().contains(query) ||
            student.name.toLowerCase().contains(query) ||
            student.section.toLowerCase().contains(query) ||
            student.grade.toLowerCase().contains(query);

        final matchesGrade =
            _selectedGrade == 'All' || student.grade == _selectedGrade;

        return matchesSearch && matchesGrade;
      }).toList();
    });
  }

  Map<String, int> _calculateStudentStats(String studentId) {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);

    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    int schoolDays = 0;

    DateTime currentDay = firstDay;
    while (
        currentDay.isBefore(lastDay) || currentDay.isAtSameMomentAs(lastDay)) {
      if (currentDay.weekday != DateTime.saturday &&
          currentDay.weekday != DateTime.sunday) {
        schoolDays++;
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    final studentLogs = widget.logs.where((log) =>
        log['id'] == studentId &&
        log['time']!.startsWith(thisMonth) &&
        log['status'] == 'Entry');

    final presentDays =
        studentLogs.map((log) => log['time']!.substring(0, 10)).toSet().length;
    final absentDays = schoolDays - presentDays;

    return {
      'schoolDays': schoolDays,
      'present': presentDays,
      'absent': absentDays,
    };
  }

  Widget _buildStudentTable() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) => const Color(0xFF4361ee),
          ),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF4361ee).withOpacity(0.2);
              }
              return Colors.white;
            },
          ),
          columns: const [
            DataColumn(
              label: Text(
                'ID (LRN)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Section',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Grade',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'School Days',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Present',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Absent',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: _filteredStudents.map((student) {
            final stats = _calculateStudentStats(student.id);

            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      student.id,
                      style: const TextStyle(
                        fontFamily: 'Monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      student.section,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      student.grade,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      stats['schoolDays']!.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      stats['present']!.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      stats['absent']!.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  int _calculateTotalEntry() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return widget.logs
        .where(
            (log) => log['time']!.startsWith(today) && log['status'] == 'Entry')
        .length;
  }

  int _calculateTotalExit() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return widget.logs
        .where(
            (log) => log['time']!.startsWith(today) && log['status'] == 'Exit')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f9ff),
      appBar: AppBar(
        title: const Text('Student Analysis'),
        backgroundColor: const Color(0xfff0f9ff),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh Data',
          ),
          TopActions(
            currentRoute: '/analysis',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff0f9ff), Color(0xffe0f2fe)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFFFFFF).withOpacity(0.9),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterStudents();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          ['All', '7', '8', '9', '10', '11', '12'].map((grade) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(grade),
                            selected: _selectedGrade == grade,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGrade = grade;
                                _filterStudents();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStat(
                      'Total Students', _filteredStudents.length, Colors.blue),
                  _buildSummaryStat(
                      'Total Entry', _calculateTotalEntry(), Colors.green),
                  _buildSummaryStat(
                      'Total Exit', _calculateTotalExit(), Colors.red),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.table_chart, color: Color(0xFF4361ee)),
                          SizedBox(width: 8),
                          Text(
                            'Student Attendance Records',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildStudentTable(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
