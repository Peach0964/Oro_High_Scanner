class ServerException implements Exception {
  final String message;
  
  ServerException([this.message = 'Server error occurred']);
  
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  
  CacheException([this.message = 'Cache error occurred']);
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException([this.message = 'Network connection failed']);
  
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  
  AuthenticationException([this.message = 'Authentication failed']);
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  
  ValidationException([this.message = 'Validation failed']);
  
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException([this.message = 'Unauthorized access']);
  
  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  
  NotFoundException([this.message = 'Resource not found']);
  
  @override
  String toString() => message;
}

class DatabaseException implements Exception {
  final String message;
  
  DatabaseException([this.message = 'Database error occurred']);
  
  @override
  String toString() => message;
}

class FileException implements Exception {
  final String message;
  
  FileException([this.message = 'File operation failed']);
  
  @override
  String toString() => message;
}

class PermissionException implements Exception {
  final String message;
  
  PermissionException([this.message = 'Permission denied']);
  
  @override
  String toString() => message;
}
