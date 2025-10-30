import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../records/records_screen.dart'; // Corrected import for User model
import '../../widgets/common/app_drawer.dart';
import '../../../core/services/supabase_service.dart';

class ScanLog {
  final String id;
  final DateTime timestamp;
  final String? name;
  final String type;

  ScanLog({
    required this.id,
    required this.timestamp,
    this.name,
    required this.type,
  });
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocus = FocusNode();
  final List<ScanLog> _logs = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Auto-focus the scan field for physical barcode scanners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestScanFocus();
    });
  }

  int get _totalRecords => _logs.length;
  int get _entryCount => _logs.where((log) => log.type == 'Entry').length;
  int get _exitCount => _logs.where((log) => log.type == 'Exit').length;

  List<ScanLog> get _filteredLogs {
    var filtered = _logs;

    // Filter by selected date
    if (_selectedDate != null) {
      filtered = filtered
          .where((log) =>
              log.timestamp.year == _selectedDate!.year &&
              log.timestamp.month == _selectedDate!.month &&
              log.timestamp.day == _selectedDate!.day)
          .toList();
    }

    return filtered;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _requestScanFocus() {
    if (!_scanFocus.hasFocus) {
      _scanFocus.requestFocus();
    }
  }

  Future<void> _processScan(String value) async {
    final id = value.trim();
    if (id.isEmpty) return;

    try {
      // Fetch student from Supabase
      final user = await _resolveUserFromSupabase(id);
      final scanType =
          await _determineScanType(id); // Determine if it's Entry or Exit
      final userName = user?.name ?? 'User-$id';

      setState(() {
        _logs.insert(
          0,
          ScanLog(
            id: id,
            timestamp: DateTime.now(),
            name: userName,
            type: scanType,
          ),
        );
      });

      // Persist to Supabase
      await SupabaseService.logScan(
        studentId: id,
        name: userName,
        scanType: scanType,
        scannedAt: DateTime.now(),
      );

      // Feedback banner
      if (mounted) {
        final nameText = user != null ? ' (${user.name})' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$scanType recorded: $id$nameText'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: scanType == 'Entry' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process scan: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    _scanController.clear();
    _requestScanFocus();
  }

  // Fetch user details from Supabase using their ID (LRN)
  Future<User?> _resolveUserFromSupabase(String id) async {
    final studentData = await SupabaseService.getStudentById(id);

    if (studentData != null) {
      return User.fromJson(studentData);
    }

    // If the student is not found in the database, throw an exception
    // to notify the user. This is better than silently failing.
    throw Exception('User with LRN "$id" not found in the database.');
  }

  // Determine if scan is Entry or Exit based on previous scans
  Future<String> _determineScanType(String studentId) async {
    // Query Supabase for the last scan of this student today.
    final lastScan =
        await SupabaseService.getLastScanForStudentToday(studentId);

    if (lastScan == null) {
      return 'Entry'; // No scans today, so this is an Entry.
    }

    // If the last scan was an Entry, this one is an Exit, and vice-versa.
    return lastScan['scan_type'] == 'Entry' ? 'Exit' : 'Entry';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Logs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TopActions(
            currentRoute: '/scanner',
            onScan: _requestScanFocus,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Scanner Input Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Scan Input Field
                    GestureDetector(
                      onTap: _requestScanFocus,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: _scanController,
                          focusNode: _scanFocus,
                          onSubmitted: _processScan,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Scan user ID or enter manually...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: Icon(Icons.qr_code_scanner,
                                color: AppColors.primary),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use physical scanner or type user ID and press Enter',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Total Records',
                              _totalRecords.toString(), Icons.list_alt),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                              'Entrées', _entryCount.toString(), Icons.login),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                              'Exits', _exitCount.toString(), Icons.logout),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date Selector
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.grey[600], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: _selectedDate == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_selectedDate != null)
                              IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.grey[600], size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Logs List
              Expanded(
                child: _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No logs found',
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
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          return _buildLogItem(log);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(ScanLog log) {
    final time = TimeOfDay.fromDateTime(log.timestamp);
    final timeString =
        '${time.hourOfPeriod.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
    final dateString =
        '${log.timestamp.month.toString().padLeft(2, '0')}/${log.timestamp.day.toString().padLeft(2, '0')}/${log.timestamp.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar/Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.name!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${log.id}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateString - $timeString',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Entry/Exit Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: log.type == 'Entry'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              log.type,
              style: TextStyle(
                color: log.type == 'Entry' ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
