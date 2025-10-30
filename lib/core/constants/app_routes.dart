class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Main Routes
  static const String dashboard = '/dashboard';
  static const String home = '/home';

  // Scanner Routes
  static const String scanner = '/scanner';
  static const String scanHistory = '/scan-history';

  // Student Management Routes
  static const String students = '/students';
  static const String studentDetails = '/student-details';
  static const String importStudents = '/import-students';
  static const String generateQRCodes = '/generate-qr-codes';

  // Admin Routes
  static const String adminPanel = '/admin';
  static const String userManagement = '/user-management';
  static const String reports = '/reports';
  static const String settings = '/settings';

  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  // Initial Route
  static const String initial = login;
}
