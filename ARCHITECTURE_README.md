# Oro High Scanner - Architecture Documentation

## Overview
The Oro High Scanner application has been refactored to follow a **4-Layer Clean Architecture** pattern, ensuring separation of concerns, testability, and maintainability.

## Architecture Enhancements

### What Was Implemented

#### 1. **Core Layer** (`lib/core/`)
Shared utilities, constants, and configurations used across the application.

**Files Created:**
- `core/constants/app_colors.dart` - Centralized color definitions
- `core/constants/app_strings.dart` - All text strings for internationalization readiness
- `core/utils/validators.dart` - Reusable form validation logic

**Benefits:**
- Single source of truth for colors and strings
- Easy to maintain and update
- Prepared for internationalization (i18n)
- Consistent validation across the app

#### 2. **Domain Layer** (`lib/domain/`)
Contains business logic and entities, independent of frameworks.

**Files Created:**
- `domain/entities/user.dart` - User entity with role-based access

**Features:**
- Immutable entity using Equatable
- Support for 6 user roles: Admin, Teacher, Security Guard, Student, Visitor, Faculty Staff
- Type-safe role management
- Ready for business logic implementation

#### 3. **Presentation Layer** (`lib/presentation/`)
UI components organized by feature and reusability.

**Files Created:**
- `presentation/screens/auth/login_screen.dart` - Refactored login screen
- `presentation/widgets/common/custom_button.dart` - Reusable button component
- `presentation/widgets/common/custom_text_field.dart` - Reusable text field component
- `presentation/widgets/auth/login_illustration.dart` - Separated illustration logic

**Improvements:**
- Component-based architecture
- Reusable widgets for consistency
- Separated concerns (UI logic vs presentation logic)
- Loading states and error handling
- Responsive design (desktop and mobile)

#### 4. **Data Layer** (Ready for Implementation)
Structure prepared for repositories and data sources.

## Project Structure

```
lib/
├── main.dart                                    # App entry point
├── core/                                        # Core utilities and constants
│   ├── constants/
│   │   ├── app_colors.dart                     # Color palette
│   │   └── app_strings.dart                    # Text strings
│   └── utils/
│       └── validators.dart                     # Form validators
├── domain/                                      # Business logic layer
│   └── entities/
│       └── user.dart                           # User entity
└── presentation/                                # UI layer
    ├── screens/
    │   └── auth/
    │       └── login_screen.dart               # Login screen
    └── widgets/
        ├── common/
        │   ├── custom_button.dart              # Reusable button
        │   └── custom_text_field.dart          # Reusable text field
        └── auth/
            └── login_illustration.dart         # Login illustration
```

## Key Features

### 1. Reusable Components

#### CustomButton
```dart
CustomButton(
  text: 'LOGIN',
  onPressed: _handleLogin,
  isLoading: _isLoading,
  backgroundColor: AppColors.primary,
)
```

Features:
- Loading state with spinner
- Customizable colors and sizes
- Optional icon support
- Disabled state handling

#### CustomTextField
```dart
CustomTextField(
  controller: _emailController,
  label: 'Email',
  hintText: 'your.email@example.com',
  validator: Validators.validateEmail,
)
```

Features:
- Consistent styling
- Built-in validation
- Password visibility toggle
- Focus states
- Error handling

### 2. Centralized Constants

#### Colors
All colors are defined in `AppColors`:
- Primary colors (purple gradient)
- Accent colors (orange)
- Text colors (dark, medium, light)
- Status colors (success, error, warning, info)
- Illustration colors

#### Strings
All text is defined in `AppStrings`:
- Screen titles
- Labels and placeholders
- Validation messages
- Error messages
- User role names

### 3. Validation System

Centralized validators in `Validators` class:
- Email validation with regex
- Password validation (min 6 characters)
- Phone number validation
- Required field validation
- Name validation

### 4. User Entity

Type-safe user management:
```dart
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
  // ... more fields
}
```

## Design Improvements

### Before (Monolithic)
- All code in single file
- Hardcoded colors and strings
- Duplicate validation logic
- Difficult to test
- Hard to maintain

### After (Clean Architecture)
- Separated concerns
- Reusable components
- Centralized constants
- Easy to test
- Maintainable and scalable

## Responsive Design

### Desktop Layout (> 800px)
- Split-screen design
- Form on left (40%)
- Illustration on right (60%)

### Mobile Layout (≤ 800px)
- Stacked layout
- Scrollable content
- Optimized spacing

## Next Steps for Full Implementation

### 1. State Management (BLoC Pattern)
```
presentation/bloc/
├── auth/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
```

### 2. Use Cases
```
domain/usecases/
├── auth/
│   ├── login_usecase.dart
│   └── logout_usecase.dart
```

### 3. Repositories
```
domain/repositories/
└── auth_repository.dart

data/repositories/
└── auth_repository_impl.dart
```

### 4. Data Sources
```
data/datasources/
├── remote/
│   └── auth_remote_datasource.dart
└── local/
    └── auth_local_datasource.dart
```

### 5. Dependency Injection
```
core/di/
└── injection_container.dart
```

## Required Packages

Current:
- `equatable: ^2.0.5` - Value equality for entities

Recommended for full implementation:
- `flutter_bloc: ^8.1.3` - State management
- `get_it: ^7.6.4` - Dependency injection
- `dartz: ^0.10.1` - Functional programming (Either type)
- `dio: ^5.3.3` - HTTP client
- `sqflite: ^2.3.0` - Local database
- `shared_preferences: ^2.2.2` - Local storage
- `qr_code_scanner: ^1.0.1` - QR scanning
- `qr_flutter: ^4.1.0` - QR generation
- `excel: ^4.0.2` - Excel file handling
- `file_picker: ^6.1.1` - File selection

## Running the Application

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

3. For web:
```bash
flutter run -d chrome
```

## Testing Strategy

### Unit Tests
- Validators
- Entities
- Use cases
- Repositories

### Widget Tests
- Custom widgets
- Screens
- Form validation

### Integration Tests
- Login flow
- QR scanning
- Data import

## Benefits of This Architecture

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Easy to write unit tests for each component
3. **Maintainability**: Changes in one layer don't affect others
4. **Scalability**: Easy to add new features
5. **Reusability**: Components can be reused across the app
6. **Team Collaboration**: Multiple developers can work on different layers
7. **Code Quality**: Consistent patterns and practices

## Color Scheme

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #6C63FF | Buttons, links, focus states |
| Primary Dark | #5A52D5 | Gradients, hover states |
| Accent | #FFB347 | Logo, highlights |
| Text Dark | #2D3748 | Headings, important text |
| Text Medium | #718096 | Body text, labels |
| Success | #48BB78 | Success messages |
| Error | #F56565 | Error messages |

## Conclusion

The login UI has been successfully enhanced with a clean architecture approach. The application is now:
- More maintainable
- Easier to test
- Scalable for future features
- Following industry best practices
- Ready for team collaboration

The foundation is set for implementing the complete time in/time out system with QR code scanning, CSV import, and role-based access control as outlined in PLAN_SYSTEM.md.
