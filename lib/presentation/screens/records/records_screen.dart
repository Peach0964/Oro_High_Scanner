import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../scanner/scanner_screen.dart' show ScanLog;
import '../../widgets/common/app_drawer.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/theme_service.dart';

class User {
  final String id, name, grade, section;
  final String? parentMobile;
  const User({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    this.parentMobile,
  });

  Map<String, dynamic> toJson() => {
        'lrn': id,
        'full_name': name,
        'grade': grade,
        'section': section,
        'parentMobile': parentMobile,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['lrn'] ?? json['id'] ?? '').toString(),
        name: (json['full_name'] ?? json['name'] ?? 'Unnamed').toString(),
        grade: (json['grade'] ?? '').toString(),
        section: (json['section'] ?? '').toString(),
        parentMobile: (json['parentMobile'] ?? '').toString(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UsersRepository {
  UsersRepository._();
  static final instance = UsersRepository._();
  final List<User> _cache = [];
  List<User> get users => List.unmodifiable(_cache);

  Future<void> load() async {
    _cache.clear();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/master_users.json');

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _cache.addAll(jsonList.map((e) => User.fromJson(e)));
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
      const User(
        id: "114479180164",
        name: "BALTAZAR, KIM GABRIEL, REGALARIO",
        grade: "7",
        section: "Fort Santiago",
        parentMobile: "+639171234567",
      ),
      const User(
        id: "114479180022",
        name: "BEQUILLO, JULIAN MATTHEW, CASTILLO",
        grade: "7",
        section: "Fort Santiago",
        parentMobile: "+639171234568",
      ),
      const User(
        id: "403853160005",
        name: "SAMPLE STUDENT ONE",
        grade: "7",
        section: "Section A",
        parentMobile: "+639123456789",
      ),
      const User(
        id: "6970009245457",
        name: "SAMPLE STUDENT TWO",
        grade: "8",
        section: "Section B",
        parentMobile: "+639123456780",
      ),
      const User(
        id: "N528A0230322",
        name: "SAMPLE STUDENT THREE",
        grade: "9",
        section: "Section C",
        parentMobile: "+639123456781",
      ),
      const User(
        id: "CH-AE-NTAS",
        name: "SAMPLE STUDENT FOUR",
        grade: "10",
        section: "Section D",
        parentMobile: "+639123456782",
      ),
    ]);
  }

  Future<void> save() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/master_users.json');
    final jsonList = _cache.map((e) => e.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<void> create(User s) async {
    _cache.add(s);
    await save();
  }

  Future<void> update(String oldId, User newS) async {
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
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/users_export_${DateTime.now().millisecondsSinceEpoch}.json');
    final jsonList = _cache.map((e) => e.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
    return file;
  }
}

class RecordsPage extends StatefulWidget {
  final List<User> users;
  final List<ScanLog> logs;
  const RecordsPage({super.key, required this.users, required this.logs});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String _selectedView = 'All Logs';
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _buildRecordsView(),
    );
  }

  Widget _buildRecordsView() {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    List<ScanLog> filteredLogs = List.from(widget.logs);

    if (_selectedDate != null) {
      filteredLogs = filteredLogs.where((log) {
        return log.timestamp.year == _selectedDate!.year &&
            log.timestamp.month == _selectedDate!.month &&
            log.timestamp.day == _selectedDate!.day;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredLogs = filteredLogs
          .where((log) =>
              (log.name ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              log.id.contains(_searchQuery))
          .toList();
    }

    if (_selectedView == 'Entries Only') {
      filteredLogs = filteredLogs.where((log) => log.type == 'Entry').toList();
    } else if (_selectedView == 'Exits Only') {
      filteredLogs = filteredLogs.where((log) => log.type == 'Exit').toList();
    }

    final totalRecords = filteredLogs.length;
    final entriesCount =
        filteredLogs.where((log) => log.type == 'Entry').length;
    final exitsCount = filteredLogs.where((log) => log.type == 'Exit').length;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: AppColors.accent),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF2C2C2E) : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedView,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                            dropdownColor:
                                isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'All Logs',
                                child: Text('All Logs'),
                              ),
                              DropdownMenuItem(
                                value: 'Entries Only',
                                child: Text('Entries Only'),
                              ),
                              DropdownMenuItem(
                                value: 'Exits Only',
                                child: Text('Exits Only'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedView = value!),
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: theme.copyWith(
                                  colorScheme: theme.colorScheme.copyWith(
                                    primary: AppColors.accent,
                                    onPrimary: Colors.white,
                                    onSurface: theme.colorScheme.onSurface,
                                  ),
                                  dialogBackgroundColor: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: _selectedDate != null
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : (isDark
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.grey[50]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDate != null
                                  ? AppColors.accent.withValues(alpha: 0.3)
                                  : (isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: _selectedDate != null
                                    ? AppColors.accent
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null
                                    ? 'Filter Date'
                                    : DateFormat('MMM dd')
                                        .format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate != null
                                      ? AppColors.accent
                                      : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700]),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (_selectedDate != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDate = null),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildRecordStat('Total', totalRecords.toString(),
                    Icons.bar_chart_rounded, Colors.blue),
                const SizedBox(width: 12),
                _buildRecordStat('Entries', entriesCount.toString(),
                    Icons.login_rounded, Colors.green),
                const SizedBox(width: 12),
                _buildRecordStat('Exits', exitsCount.toString(),
                    Icons.logout_rounded, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[filteredLogs.length - 1 - index];
                      return _buildLogItem(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordStat(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(ScanLog log) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;
    final time = TimeOfDay.fromDateTime(log.timestamp);
    final timeString =
        '${time.hourOfPeriod.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';

    final isEntry = log.type == 'Entry';
    final statusColor = isEntry ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border:
            Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isDark ? const Color(0xFF2C2C2E) : Colors.grey[50],
                        border: Border.all(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[200]!),
                      ),
                      child: Center(
                        child: Text(
                          (log.name ?? '?')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.white,
                                width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.name ?? 'Unknown Student',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.id,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeString,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    log.type.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
