import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred'])
      : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network connection failed'])
      : super(message);
}

// Auth failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Authentication failed'])
      : super(message);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure(
      [String message = 'Invalid email or password'])
      : super(message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Unauthorized access'])
      : super(message);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation failed'])
      : super(message);
}

// QR Code failures
class QRCodeGenerationFailure extends Failure {
  const QRCodeGenerationFailure([String message = 'Failed to generate QR code'])
      : super(message);
}

class QRCodeScanFailure extends Failure {
  const QRCodeScanFailure([String message = 'Failed to scan QR code'])
      : super(message);
}

// File handling failures
class FileImportFailure extends Failure {
  const FileImportFailure([String message = 'Failed to import file'])
      : super(message);
}

class FileExportFailure extends Failure {
  const FileExportFailure([String message = 'Failed to export file'])
      : super(message);
}

// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure([String message = 'Database error occurred'])
      : super(message);
}

// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permission denied'])
      : super(message);
}
