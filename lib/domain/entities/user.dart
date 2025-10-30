import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  teacher,
  securityGuard,
  student,
  visitor,
  facultyStaff,
}

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        profileImage,
        createdAt,
        lastLogin,
      ];

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  String get roleString {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.securityGuard:
        return 'Security Guard';
      case UserRole.student:
        return 'Student';
      case UserRole.visitor:
        return 'Visitor';
      case UserRole.facultyStaff:
        return 'Faculty Staff';
    }
  }
}
