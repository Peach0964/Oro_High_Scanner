import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../records/records_screen.dart'; // Corrected import for User model
import '../../../generate_qr_code/generate_qr_code_screen.dart';
import '../../widgets/common/app_drawer.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/theme_service.dart';

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

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with 3 tabs: Scanner, Records, Generate QR
    _tabController = TabController(length: 3, vsync: this);
    // Fetch initial scan data when the screen loads
    _fetchInitialScans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // This list will hold all scan logs and be the single source of truth.
  final List<ScanLog> _allLogs = [];

  // Fetch initial data from Supabase when the app starts.
  Future<void> _fetchInitialScans() async {
    final scansData = await SupabaseService.fetchScans(limit: 500);
    final logs = scansData.map((scan) {
      return ScanLog(
        id: scan['student_id'] ?? 'N/A',
        timestamp: DateTime.parse(scan['scanned_at']),
        // The name is already stored directly in the 'scans' table.
        name: scan['name'] ?? 'Unknown',
        type: scan['scan_type'] ?? 'N/A',
      );
    }).toList();
    setState(() => _allLogs.addAll(logs));
  }

  // This function will be passed to the ScannerScreen to add new logs.
  void _addScanLog(ScanLog log) {
    setState(() => _allLogs.insert(0, log));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
        title: Text(
          'Oro High Scanner',
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: const [
          TopActions(currentRoute: '/scanner'),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? Colors.grey[400] : Colors.grey[600],
              indicator: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Scanner'),
                    ],
                  ),
                ),
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Records'),
                    ],
                  ),
                ),
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Create'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: TabBarView(
          controller: _tabController,
          // Pass the central log list and the function to add to it.
          children: [
            ScannerScreen(
              logs: _allLogs, // Pass the full list of logs
              onScan: _addScanLog, // Pass the function to add a new log
            ),
            RecordsPage(
                users: const [], logs: _allLogs), // Pass logs to Records
            const GenerateQRCodeScreen(),
          ],
        ),
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  // Receive the logs list and the onScan function from the parent.
  final List<ScanLog> logs;
  final void Function(ScanLog log) onScan;

  const ScannerScreen({super.key, required this.logs, required this.onScan});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocus = FocusNode();
  DateTime? _selectedDate;
  String _manualScanMode = 'Auto'; // Can be 'Auto', 'Entry', or 'Exit'

  @override
  void initState() {
    super.initState();
    // Auto-focus the scan field for physical barcode scanners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestScanFocus();
    });
  }

  int get _totalRecords => widget.logs.length;
  int get _entryCount => widget.logs.where((log) => log.type == 'Entry').length;
  int get _exitCount => widget.logs.where((log) => log.type == 'Exit').length;

  List<ScanLog> get _filteredLogs {
    var filtered = widget.logs; // Use the list from the parent widget

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
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
            dialogBackgroundColor:
                isDark ? const Color(0xFF1C1C1E) : Colors.white,
          ),
          child: child!,
        );
      },
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
    final rawValue = value.trim();
    if (rawValue.isEmpty) return;

    // 1. Extract the ID part from the QR code string (the part before '|')
    var id = rawValue.split('|').first;

    // 2. If the ID starts with "S-", remove it to get the clean LRN.
    //    This makes the scanner compatible with both "S-123" and "123" formats.
    if (id.startsWith('S-')) id = id.substring(2);

    try {
      // Fetch student from Supabase
      final user = await _resolveUserFromSupabase(id);

      // Use the manual override if it's not 'Auto', otherwise determine automatically.
      final String scanType;
      if (_manualScanMode != 'Auto') {
        scanType = _manualScanMode;
      } else {
        scanType = _determineScanType(id);
      }
      final userName = user?.name ?? 'User-$id';

      // Create the new log object.
      final newLog = ScanLog(
        id: id,
        timestamp: DateTime.now(),
        name: userName,
        type: scanType,
      );

      // Call the parent's function to add the log to the central list.
      // This makes the UI update instantly.
      widget.onScan(newLog);

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

      // Try to persist to Supabase in the background.
      // If it fails, show a warning but don't block the user.
      try {
        await SupabaseService.logScan(
          studentId: id,
          name: userName,
          scanType: scanType,
          scannedAt: newLog.timestamp.toUtc(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: Could not sync scan to the cloud.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
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
    final userData = await SupabaseService.getUserById(id);

    if (userData != null) {
      return User.fromJson(userData);
    }

    // If the student is not found in the database, throw an exception
    // to notify the user. This is better than silently failing.
    throw Exception('User with ID "$id" not found in the database.');
  }

  // Determine if scan is Entry or Exit based on previous scans
  String _determineScanType(String studentId) {
    // Use the local-first hybrid approach to prevent race conditions.
    // 1. Check the local list of logs first for an instantaneous result.
    final now = DateTime.now();
    final lastScanForStudentToday = widget.logs.where((log) =>
        log.id == studentId &&
        log.timestamp.year == now.year &&
        log.timestamp.month == now.month &&
        log.timestamp.day == now.day);

    if (lastScanForStudentToday.isEmpty) {
      // No scans found in the local list for today, so this is an Entry.
      return 'Entry';
    }

    // 2. If scans exist, find the most recent one.
    //    The `_allLogs` list in the parent is always sorted with the newest scan at index 0.
    final mostRecentLog = lastScanForStudentToday.first;

    // If the last scan was an Entry, this one is an Exit, and vice-versa.
    return mostRecentLog.type == 'Entry' ? 'Exit' : 'Entry';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Scaffold(
      // The AppBar is now managed by MainTabsScreen
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Scanner Input Section
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1C1C1E),
                                  const Color(0xFF1C1C1E)
                                ]
                              : [Colors.white, const Color(0xFFFAFAFA)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(32)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row with Title and Compact Switcher
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scan Student ID',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enter ID manually or scan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              // Compact Mode Switcher
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildCompactModeOption('Auto', Icons.sync),
                                    _buildCompactModeOption(
                                        'Entry', Icons.login),
                                    _buildCompactModeOption(
                                        'Exit', Icons.logout),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent
                                      .withValues(alpha: isDark ? 0.1 : 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.2)),
                            ),
                            child: TextField(
                              controller: _scanController,
                              focusNode: _scanFocus,
                              onSubmitted: _processScan,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: 'Click here to scan...',
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400]),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: AppColors.accent,
                                    size: 24,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats & Filter Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        // Date Filter
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[200]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: _selectedDate == null
                                      ? (isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500])
                                      : AppColors.accent,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedDate == null
                                      ? 'Filter Date'
                                      : '${_selectedDate!.month}/${_selectedDate!.day}',
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600])
                                        : theme.colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_selectedDate != null) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            _totalRecords.toString(),
                            Icons.bar_chart_rounded,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Entries',
                            _entryCount.toString(),
                            Icons.login_rounded,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Exits',
                            _exitCount.toString(),
                            Icons.logout_rounded,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Logs List
              Expanded(
                child: _filteredLogs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 72,
                              color:
                                  isDark ? Colors.grey[700] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No scans yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan a student ID to see activity appear here in real time.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                                fontSize: 13,
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Container(
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
    );
  }

  Widget _buildCompactModeOption(String value, IconData icon) {
    final isSelected = _manualScanMode == value;
    final isDark = ThemeService().isDarkMode;

    return GestureDetector(
      onTap: () => setState(() => _manualScanMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3C3C3E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
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
          onTap: () {}, // Optional: Show details on tap
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with Status Indicator
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

                // Info
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

                // Status Badge
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
