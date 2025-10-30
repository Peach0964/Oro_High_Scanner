import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../widgets/common/app_drawer.dart';
import '../../../core/services/supabase_service.dart';

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
        'lrn': id, // 'id' in the model corresponds to 'lrn'
        'full_name': name, // 'name' in the model corresponds to 'full_name'
        'grade': grade,
        'section': section,
        'parentMobile': parentMobile,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['lrn'] ?? json['id'] ?? '')
            .toString(), // Handle both lrn and id for compatibility
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

class ScanFolder {
  final String name;
  final String path;
  final List<ScanRecord> records;
  final DateTime lastModified;

  ScanFolder({
    required this.name,
    required this.path,
    required this.records,
    required this.lastModified,
  });
}

class ScanRecord {
  final String id;
  final String name;
  final DateTime time;
  final String status;

  ScanRecord({
    required this.id,
    required this.name,
    required this.time,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time.toIso8601String(),
        'status': status,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'],
        name: json['name'],
        time: DateTime.parse(json['time']),
        status: json['status'],
      );
}

class RecordsPage extends StatefulWidget {
  final List<User> users;
  final List<Map<String, String>> logs;
  const RecordsPage({super.key, required this.users, required this.logs});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String _selectedView = 'All Logs';
  String _searchQuery = '';
  DateTime? _selectedDate;
  bool _showScanFolders = false;
  List<ScanFolder> _scanFolders = [];
  bool _loadingFolders = false;

  // Remote logs from Supabase (normalized to widget.logs structure)
  List<Map<String, String>> _remoteLogs = [];
  bool _loadingRemote = false;

  @override
  void initState() {
    super.initState();
    _loadScanFolders();
    _loadRemoteLogs(); // fetch from Supabase on open
  }

  Future<void> _loadScanFolders() async {
    setState(() => _loadingFolders = true);

    if (kIsWeb) {
      // For web, no file system access, so return empty folders
      setState(() {
        _scanFolders = [];
        _loadingFolders = false;
      });
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final qrDir = Directory('${dir.path}/QRLogs');

    final List<ScanFolder> folders = [];

    if (await qrDir.exists()) {
      await for (final entity in qrDir.list()) {
        if (entity is Directory) {
          final folderName = entity.path.split('/').last;
          final logFile = File('${entity.path}/scanned_logs.txt');

          List<ScanRecord> records = [];
          if (await logFile.exists()) {
            final lines = await logFile.readAsLines();
            final reg = RegExp(
                r"Time: ([\d\-T:\.]+), ID: ([^,]+), Name: ([^,]+), Status: (Entry|Exit)");

            for (final line in lines) {
              if (line.trim().isEmpty || line.startsWith('#')) continue;
              final match = reg.firstMatch(line);
              if (match != null) {
                records.add(ScanRecord(
                  id: match.group(2)!,
                  name: match.group(3)!,
                  time: DateTime.parse(match.group(1)!),
                  status: match.group(4)!,
                ));
              }
            }
          }

          records.sort((a, b) => b.time.compareTo(a.time));

          folders.add(ScanFolder(
            name: folderName,
            path: entity.path,
            records: records,
            lastModified: await logFile.exists()
                ? await logFile.lastModified()
                : await entity.stat().then((stat) => stat.modified),
          ));
        }
      }
    }

    folders.sort((a, b) => b.name.compareTo(a.name));

    setState(() {
      _scanFolders = folders;
      _loadingFolders = false;
    });
  }

  Future<void> _loadRemoteLogs() async {
    if (!mounted) return;
    if (!SupabaseService.isConfigured) {
      setState(() {
        _remoteLogs = [];
        _loadingRemote = false;
      });
      return;
    }
    setState(() => _loadingRemote = true);
    final rows = await SupabaseService.fetchScans(forDate: _selectedDate);
    final mapped = rows.map<Map<String, String>>((r) {
      final id = (r['student_id'] ?? '').toString();
      final name = (r['name'] ?? 'User-$id').toString();
      final timeIso =
          (r['scanned_at'] ?? DateTime.now().toIso8601String()).toString();
      final status = (r['scan_type'] ?? 'Entry').toString();
      return {
        'id': id,
        'name': name,
        'time': timeIso,
        'status': status,
      };
    }).toList();
    if (!mounted) return;
    setState(() {
      _remoteLogs = mapped;
      _loadingRemote = false;
    });
  }

  Future<void> _saveFolderAsJson(ScanFolder folder) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File export not supported on web'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          '${folder.name}_export_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json';
      final file = File('${dir.path}/$fileName');

      final List<Map<String, dynamic>> recordsJson =
          folder.records.map((record) {
        return {
          'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(record.time),
          'id': record.id,
          'name': record.name,
          'status': record.status,
        };
      }).toList();

      await file.writeAsString(json.encode(recordsJson));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder exported to ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFolder(ScanFolder folder) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File operations not supported on web'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
            'Are you sure you want to delete the folder "${folder.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final folderDir = Directory(folder.path);
        if (await folderDir.exists()) {
          await folderDir.delete(recursive: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Folder "${folder.name}" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadScanFolders();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showScanFolders ? Icons.list : Icons.folder_open,
                color: Colors.black87),
            onPressed: () {
              setState(() => _showScanFolders = !_showScanFolders);
            },
            tooltip: _showScanFolders ? 'Show Records' : 'Show Scan Folders',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              _loadScanFolders();
              await _loadRemoteLogs();
            },
            tooltip: 'Refresh',
          ),
          TopActions(
            currentRoute: '/records',
          ),
        ],
      ),
      body: _showScanFolders ? _buildScanFoldersView() : _buildRecordsView(),
    );
  }

  Widget _buildScanFoldersView() {
    return _loadingFolders
        ? const Center(child: CircularProgressIndicator())
        : _scanFolders.isEmpty
            ? _buildEmptyFoldersState()
            : _buildScanFolderList();
  }

  Widget _buildEmptyFoldersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No Scan Folders',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan QR codes to create folders',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadScanFolders,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFolderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scanFolders.length,
      itemBuilder: (context, index) {
        final folder = _scanFolders[index];
        return _buildScanFolderItem(folder);
      },
    );
  }

  Widget _buildScanFolderItem(ScanFolder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'QRLogs ${folder.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black, // Fixed color
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _saveFolderAsJson(folder),
                      icon: const Icon(Icons.save_alt, color: Colors.blue),
                      tooltip: 'Export as JSON',
                    ),
                    IconButton(
                      onPressed: () => _deleteFolder(folder),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Folder',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  'Last modified: ${DateFormat('MMM dd, yyyy - hh:mm a').format(folder.lastModified)}',
                  style: TextStyle(
                    color:
                        Colors.grey[700], // Darker grey for better visibility
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${folder.records.length} scans',
                  style: TextStyle(
                    color:
                        Colors.grey[700], // Darker grey for better visibility
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFolderStat('Total', folder.records.length, Colors.blue),
                  _buildFolderStat(
                      'Entries',
                      folder.records.where((r) => r.status == 'Entry').length,
                      Colors.green),
                  _buildFolderStat(
                      'Exits',
                      folder.records.where((r) => r.status == 'Exit').length,
                      Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Recent Scans:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black, // Fixed color
              ),
            ),
            const SizedBox(height: 8),
            ...folder.records
                .take(3)
                .map((record) => _buildScanRecordItem(record)),
            if (folder.records.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${folder.records.length - 3} more scans',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black, // Fixed color
          ),
        ),
      ],
    );
  }

  Widget _buildScanRecordItem(ScanRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.qr_code, color: Colors.blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${record.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black, // Fixed color
                  ),
                ),
                Text(
                  '${record.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87, // Fixed color
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(record.time),
                  style: const TextStyle(
                    color: Colors.black54, // Fixed color
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.status == 'Entry'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: record.status == 'Entry'
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                color: record.status == 'Entry' ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsView() {
    // Merge local (widget.logs) and remote (_remoteLogs)
    List<Map<String, String>> filteredLogs = [
      ...widget.logs,
      ..._remoteLogs,
    ];

    if (_selectedDate != null) {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      filteredLogs = filteredLogs
          .where((log) => log['time']!.startsWith(dateString))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredLogs = filteredLogs
          .where((log) =>
              log['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              log['id']!.contains(_searchQuery))
          .toList();
    }

    if (_selectedView == 'Entries Only') {
      filteredLogs =
          filteredLogs.where((log) => log['status'] == 'Entry').toList();
    } else if (_selectedView == 'Exits Only') {
      filteredLogs =
          filteredLogs.where((log) => log['status'] == 'Exit').toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search student to scan...',
                  hintStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedView,
                          items: const [
                            DropdownMenuItem(
                                value: 'All Logs',
                                child: Text('All Logs',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Entries Only',
                                child: Text('Entries Only',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Exits Only',
                                child: Text('Exits Only',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedView = value!),
                          style: const TextStyle(color: Colors.black),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.black54),
                        label: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('MMM dd, yyyy')
                                  .format(_selectedDate!),
                          style: const TextStyle(color: Colors.black),
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                            await _loadRemoteLogs();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedDate != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _selectedDate = null),
                  child: const Text('Clear Date Filter',
                      style: TextStyle(color: Colors.blue)),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildRecordStat(
                  'Total Records', filteredLogs.length.toString(), Colors.blue),
              const SizedBox(width: 12),
              _buildRecordStat(
                  'Entries',
                  filteredLogs
                      .where((log) => log['status'] == 'Entry')
                      .length
                      .toString(),
                  Colors.green),
              const SizedBox(width: 12),
              _buildRecordStat(
                  'Exits',
                  filteredLogs
                      .where((log) => log['status'] == 'Exit')
                      .length
                      .toString(),
                  Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No records found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[filteredLogs.length - 1 - index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: log['status'] == 'Entry'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            log['status'] == 'Entry'
                                ? Icons.login
                                : Icons.logout,
                            color: log['status'] == 'Entry'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(log['name']!,
                            style: const TextStyle(color: Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${log['id']}',
                                style: const TextStyle(color: Colors.black87)),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a')
                                  .format(DateTime.parse(log['time']!)),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            log['status']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: log['status'] == 'Entry'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecordStat(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
