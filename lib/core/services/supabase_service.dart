import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple, centralized Supabase access for the app
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Returns true when Supabase was initialized (via Supabase.initialize in main)
  static bool get isConfigured {
    try {
      // Touching the client/auth accessor without throwing implies initialize() ran
      client.auth;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sign in using either:
  /// - Email (when [identifier] contains '@')
  /// - Student ID (looks up email in 'users' table by 'student_id' column)
  static Future<void> signInWithStudentIdOrEmail({
    required String identifier,
    required String password,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Supabase is not configured. Add SUPABASE_URL and a valid SUPABASE_ANON_KEY to .env, then restart the app.',
      );
    }

    try {
      if (identifier.contains('@')) {
        // Treat as email
        await client.auth.signInWithPassword(
          email: identifier,
          password: password,
        );
        return;
      }

      // Treat as Student ID: map lrn -> email in your 'users' table
      // This is the flow for signing in with an LRN:
      // 1. Use the LRN (which is the primary key) to find the user in the public.users table.
      final row = await client
          .from('users')
          .select('email')
          .eq('lrn', identifier)
          .limit(1)
          .maybeSingle();

      // 2. Retrieve the email from that user's record.
      //    This requires an 'email' column in your 'public.users' table.
      final email = (row != null) ? (row['email'] as String?) : null;
      if (email == null || email.isEmpty) {
        throw Exception('No account found for Student ID "$identifier".');
      }

      await client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      // 3. Use the retrieved email and the provided password to authenticate against Supabase Auth.
      final msg = e.toString();
      final msgLower = msg.toLowerCase();

      // Normalize common misconfiguration errors to a friendly message
      final looksLikeInvalidKey = msgLower.contains('invalid api key') ||
          msgLower.contains('code: 401') ||
          msgLower.contains('unauthorized');

      if (looksLikeInvalidKey) {
        throw Exception(
          'Supabase rejected the API key. Ensure SUPABASE_ANON_KEY in .env is correct, then fully restart the app.',
        );
      }

      // Pass through other messages (e.g., wrong password)
      rethrow;
    }
  }

  static Future<void> signOut() async {
    if (!isConfigured) return;
    await client.auth.signOut();
  }

  /// Helper to check current session
  static bool get hasSession {
    try {
      return client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  /// Log a scan into Supabase (table: scans)
  /// Columns expected: student_id (text), name (text), scan_type ('Entry'|'Exit'), scanned_at (timestamptz)
  static Future<void> logScan({
    required String studentId,
    String? name,
    required String scanType,
    DateTime? scannedAt,
  }) async {
    if (!isConfigured) return;
    try {
      await client.from('scans').insert({
        'student_id': studentId,
        'name': name,
        'scan_type': scanType,
        'scanned_at': (scannedAt ?? DateTime.now()).toIso8601String(),
      });
    } catch (e) {
      // Don't swallow errors. Let the caller handle them to provide user feedback.
      rethrow;
    }
  }

  /// Fetch scans (optionally filtered by a specific date), newest first.
  /// To keep compatibility across postgrest versions, we fetch and filter in Dart.
  static Future<List<Map<String, dynamic>>> fetchScans({
    DateTime? forDate,
    int limit = 200,
  }) async {
    if (!isConfigured) return [];
    try {
      final rows = await client
          .from('scans')
          .select('*')
          .order('scanned_at', ascending: false)
          .limit(limit);

      if (rows is! List) return [];
      List<Map<String, dynamic>> list = rows.cast<Map<String, dynamic>>();

      if (forDate != null) {
        final start = DateTime(forDate.year, forDate.month, forDate.day);
        final end = start.add(const Duration(days: 1));
        list = list.where((r) {
          final iso = (r['scanned_at'] ?? '') as String;
          try {
            final ts = DateTime.parse(iso);
            return (ts.isAtSameMomentAs(start) || ts.isAfter(start)) &&
                ts.isBefore(end);
          } catch (_) {
            return false;
          }
        }).toList();
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// Fetch students from Supabase to power multiple screens.
  /// Expected table: public.students with columns:
  ///   lrn (text), full_name (text), and other optional fields.
  /// Fallback: if 'students' table is missing or query fails, returns [].
  static Future<List<Map<String, dynamic>>> fetchStudents() async {
    if (!isConfigured) return [];
    try {
      final rows = await client.from('students').select('*').limit(1000);
      if (rows is List) {
        return rows.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      // If table doesn't exist or any error occurs, return empty list gracefully
      return [];
    }
  }

  /// Get the last scan record for a specific student on the current day.
  static Future<Map<String, dynamic>?> getLastScanForStudentToday(
      String studentId) async {
    if (!isConfigured) return null;

    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day).toIso8601String();
    final endOfDay =
        DateTime.utc(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    try {
      final data = await client
          .from('scans')
          .select('scan_type')
          .eq('student_id', studentId)
          .gte('scanned_at', startOfDay)
          .lte('scanned_at', endOfDay)
          .order('scanned_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Quick helper to get the current auth user's email (if any)
  static String? getCurrentEmail() {
    try {
      return client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  /// Get a single user by their ID, checking both students and teachers tables.
  static Future<Map<String, dynamic>?> getUserById(String id) async {
    if (!isConfigured) return null;
    try {
      final trimmedId = id.trim();

      // 1. Check for the user in the students table first.
      final studentData = await client
          .from('students_scanner')
          .select('*')
          .eq('lrn', trimmedId)
          .maybeSingle();

      if (studentData != null) {
        return studentData; // Found a student, return their data.
      }

      // 2. If not found, check for the user in the teachers table.
      final teacherData = await client
          .from('teachers')
          .select('employee_id, first_name, middle_name, last_name')
          .eq('employee_id', trimmedId)
          .maybeSingle();

      if (teacherData != null) {
        // Standardize the teacher data to match the student format for the UI.
        final firstName = teacherData['first_name'] ?? '';
        final middleName = teacherData['middle_name'] ?? '';
        final lastName = teacherData['last_name'] ?? '';
        final fullName = [firstName, middleName, lastName]
            .where((name) => name.isNotEmpty)
            .join(' ');

        return {
          'lrn': teacherData['employee_id'], // Map 'employee_id' to 'lrn'
          'full_name': fullName,
        };
      }

      return null; // User not found in either table.
    } catch (_) {
      return null;
    }
  }

  /// Search for users across both 'students_scanner' and 'teachers' tables.
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (!isConfigured || query.isEmpty) return [];
    try {
      // Define the two search futures to run in parallel.
      final searchFutures = [
        // Search students
        client
            .from('students_scanner')
            .select('lrn, full_name')
            .ilike('full_name', '%$query%')
            .limit(10),

        // Search teachers and standardize the data structure
        client
            .from('teachers')
            .select('employee_id, first_name, middle_name, last_name') // Use correct teacher columns
            // Search across first, middle, and last names
            .or('first_name.ilike.%$query%,middle_name.ilike.%$query%,last_name.ilike.%$query%')
            .limit(10)
            .then((teacherData) {
          // Map teacher data to the consistent format used by the UI.
          return teacherData.map((teacher) {
            // Combine name parts into a single full name string.
            final firstName = teacher['first_name'] ?? '';
            final middleName = teacher['middle_name'] ?? '';
            final lastName = teacher['last_name'] ?? '';
            final fullName = [firstName, middleName, lastName]
                .where((name) => name.isNotEmpty)
                .join(' ');

            return {
              'lrn': teacher['employee_id'], // Map 'employee_id' to 'lrn'
              'full_name': fullName,
            };
          }).toList();
        }),
      ];

      // Wait for both searches to complete.
      final results = await Future.wait(searchFutures);

      // Combine the results from both lists and sort them by name.
      final combinedList = results.expand((list) => list).toList();
      combinedList.sort((a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String));

      return combinedList;
    } catch (_) {
      // If any search fails (e.g., table doesn't exist), return an empty list.
      return [];
    }
  }
}
