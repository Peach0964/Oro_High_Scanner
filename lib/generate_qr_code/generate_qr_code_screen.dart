import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:excel/excel.dart' hide Border;
import '../core/constants/app_colors.dart';
import 'bulk_qr_display_screen.dart';
import '../core/services/supabase_service.dart';
import '../core/services/theme_service.dart';

class GenerateQRCodeScreen extends StatefulWidget {
  const GenerateQRCodeScreen({super.key});

  @override
  State<GenerateQRCodeScreen> createState() => _GenerateQRCodeScreenState();
}

class _GenerateQRCodeScreenState extends State<GenerateQRCodeScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  String? _generatedQRData;
  bool _isGenerating = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    final studentId = _studentIdController.text.trim();
    final studentName = _studentNameController.text.trim();

    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Student ID'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // Simulate QR generation delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _generatedQRData =
              'S-$studentId${studentName.isNotEmpty ? '|$studentName' : ''}';
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code generated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _clearForm() {
    setState(() {
      _studentIdController.clear();
      _studentNameController.clear();
      _generatedQRData = null;
    });
  }

  void _printQRCode() async {
    if (_generatedQRData == null) return;

    final isDark = ThemeService().isDarkMode;

    // Show print dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(
          'Print QR Code',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Print this QR code for the student?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Print functionality would be implemented here'),
                  backgroundColor: AppColors.info,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  void _shareQRCode() {
    if (_generatedQRData == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final platformFile = result.files.single;
      final fileExtension = platformFile.extension?.toLowerCase();
      List<List<dynamic>> rows;

      // Use bytes on web, path on other platforms
      if (kIsWeb) {
        final bytes = platformFile.bytes;
        if (bytes == null) throw Exception("File bytes are not available.");

        if (fileExtension == 'csv') {
          final csvString = utf8.decode(bytes);
          rows = const CsvToListConverter(shouldParseNumbers: false)
              .convert(csvString);
        } else if (fileExtension == 'xlsx') {
          final excel = Excel.decodeBytes(bytes);
          final sheet = excel.tables[excel.tables.keys.first];
          if (sheet == null)
            throw Exception('No sheet found in the Excel file.');
          rows = sheet.rows
              .map((row) => row.map((cell) => cell?.value).toList())
              .toList();
        } else {
          throw Exception('Unsupported file type: $fileExtension');
        }
      } else {
        final filePath = platformFile.path;
        if (filePath == null) throw Exception("File path is not available.");

        if (fileExtension == 'csv') {
          final input = File(filePath).openRead();
          rows = await input
              .transform(utf8.decoder)
              .transform(const CsvToListConverter(shouldParseNumbers: false))
              .toList();
        } else if (fileExtension == 'xlsx') {
          final bytes = File(filePath).readAsBytesSync();
          final excel = Excel.decodeBytes(bytes);
          final sheet = excel.tables[excel.tables.keys.first];
          if (sheet == null)
            throw Exception('No sheet found in the Excel file.');
          rows = sheet.rows
              .map((row) => row.map((cell) => cell?.value).toList())
              .toList();
        } else {
          throw Exception('Unsupported file type: $fileExtension');
        }
      }

      if (rows.length < 2) {
        throw Exception('File is empty or has no data rows.');
      }

      // Find column indices for 'LRN' and 'Name' from the header row.
      final headerRow =
          rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
      final lrnColumnIndex = headerRow.indexOf('lrn');
      // Be flexible with the name column header
      int nameColumnIndex = headerRow.indexOf('name');
      if (nameColumnIndex == -1) {
        nameColumnIndex = headerRow.indexOf('full_name');
      }

      if (lrnColumnIndex == -1) {
        throw Exception('Could not find a column named "LRN" in the file.');
      }
      if (nameColumnIndex == -1) {
        throw Exception('Could not find a column named "Name" or "full_name".');
      }

      // Get data rows (all rows except the header)
      final dataRows = rows.sublist(1);

      final List<BulkQRItem> bulkQrItems = dataRows
          .map((row) {
            // Ensure row has enough columns before accessing
            final id =
                (row.length > lrnColumnIndex && row[lrnColumnIndex] != null)
                    ? row[lrnColumnIndex].toString().trim()
                    : '';
            final name =
                (row.length > nameColumnIndex && row[nameColumnIndex] != null)
                    ? row[nameColumnIndex].toString().trim()
                    : '';

            if (id.isEmpty) return null; // Skip rows with no LRN

            final qrData =
                'S-$id${name.isNotEmpty ? '|$name' : ''}'; // Format QR data
            return BulkQRItem(id: id, name: name, qrData: qrData);
          })
          .whereType<BulkQRItem>()
          .toList();

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BulkQRDisplayScreen(items: bulkQrItems),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImportDialog(BuildContext context) {
    final isDark = ThemeService().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(
          'Import Students',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Import student data from a CSV or Excel (.xlsx) file to generate QR codes in bulk.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMedium),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _importFile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import File'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    final selectedUser = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _UserSearchDialog(),
    );

    if (selectedUser != null && mounted) {
      setState(() {
        _studentIdController.text = (selectedUser['lrn'] ?? '').toString();
        _studentNameController.text =
            (selectedUser['full_name'] ?? '').toString();
        _generatedQRData = null; // Clear previous QR code
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showImportDialog(context), // This now calls _importFile
        label: const Text('Import File'),
        icon: const Icon(Icons.upload_file),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        tooltip: 'Import Students from CSV',
        elevation: 4,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 90.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1C1C1E), const Color(0xFF1C1C1E)]
                      : [Colors.white, const Color(0xFFFAFAFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Generate QR',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      bottom: 50,
                      child: Text(
                        'Create Student QR Codes',
                        style: TextStyle(
                          color:
                              isDark ? Colors.grey[400] : AppColors.textMedium,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputForm(),
                  if (_generatedQRData != null) ...[
                    const SizedBox(height: 30),
                    _buildQRDisplay(),
                  ],
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: _showSearchDialog,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Search User'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _studentIdController,
            label: 'Student ID',
            hint: 'e.g., 123456789',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _studentNameController,
            label: 'Student Name (Optional)',
            hint: 'e.g., Juan Dela Cruz',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateQRCode,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.qr_code),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate QR Code',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_studentIdController.text.isNotEmpty ||
                  _studentNameController.text.isNotEmpty) ...[
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Clear Form',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                    foregroundColor:
                        isDark ? Colors.grey[400] : Colors.grey[600],
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: Icon(icon, color: AppColors.accent),
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRDisplay() {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              'QR Code Ready',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(
                  child: Text(
                    'SCAN ME',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Colors.white, // QR Code always needs white background
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: _generatedQRData!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black, // Always black for contrast
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black, // Always black for contrast
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Text(
                      _generatedQRData!.split('|').first,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_generatedQRData!.contains('|')) ...[
                      const SizedBox(height: 4),
                      Text(
                        _generatedQRData!.split('|').last,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isDark ? Colors.grey[400] : AppColors.textMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Divider(
                        height: 1,
                        color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.print_outlined,
                          label: 'Print',
                          onTap: _printQRCode,
                        ),
                        Container(
                            width: 1,
                            height: 24,
                            color:
                                isDark ? Colors.grey[800] : Colors.grey[300]),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: _shareQRCode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSearchDialog extends StatefulWidget {
  const _UserSearchDialog();

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final results = await SupabaseService.searchUsers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService().isDarkMode;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      title: Text(
        'Search for User',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Type a name to search...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                suffixIcon:
                    _isLoading ? const CircularProgressIndicator() : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48,
                              color:
                                  isDark ? Colors.grey[700] : Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            'No users found',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.accent.withValues(alpha: 0.1),
                            child: Text(
                              (user['full_name'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            user['full_name'] ?? 'No Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${user['lrn'] ?? 'N/A'}',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600]),
                          ),
                          onTap: () => Navigator.of(context).pop(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textMedium),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
