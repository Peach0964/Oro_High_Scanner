# Migration Guide - From Monolithic to Clean Architecture

## Overview
This guide explains the changes made to transform the Oro High Scanner from a monolithic structure to a clean 4-layer architecture.

## What Changed

### File Structure

#### Before:
```
lib/
├── main.dart
└── screens/
    └── login_screen.dart (1 large file with everything)
```

#### After:
```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_routes.dart
│   ├── utils/
│   │   └── validators.dart
│   └── error/
│       ├── failures.dart
│       └── exceptions.dart
├── domain/
│   └── entities/
│       └── user.dart
└── presentation/
    ├── screens/
    │   └── auth/
    │       └── login_screen.dart
    ├── widgets/
    │   ├── common/
    │   │   ├── custom_button.dart
    │   │   ├── custom_text_field.dart
    │   │   └── loading_indicator.dart
    │   └── auth/
    │       └── login_illustration.dart
    └── bloc/
        └── auth/
            ├── auth_bloc.dart
            ├── auth_event.dart
            └── auth_state.dart
```

## Breaking Changes

### 1. Import Paths Changed

#### Before:
```dart
import 'screens/login_screen.dart';
```

#### After:
```dart
import 'presentation/screens/auth/login_screen.dart';
```

### 2. Color Usage

#### Before:
```dart
color: Color(0xFF6C63FF)
```

#### After:
```dart
import 'package:oro_high_scanner/core/constants/app_colors.dart';

color: AppColors.primary
```

### 3. String Usage

#### Before:
```dart
Text('Welcome to')
```

#### After:
```dart
import 'package:oro_high_scanner/core/constants/app_strings.dart';

Text(AppStrings.welcomeTo)
```

### 4. Validation

#### Before:
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  if (!value.contains('@')) {
    return 'Please enter a valid email';
  }
  return null;
}
```

#### After:
```dart
import 'package:oro_high_scanner/core/utils/validators.dart';

validator: Validators.validateEmail
```

## New Features

### 1. Reusable Components

#### CustomButton
```dart
CustomButton(
  text: 'LOGIN',
  onPressed: _handleLogin,
  isLoading: _isLoading,
)
```

#### CustomTextField
```dart
CustomTextField(
  controller: _emailController,
  label: AppStrings.email,
  hintText: AppStrings.emailPlaceholder,
  validator: Validators.validateEmail,
)
```

#### LoadingIndicator
```dart
LoadingIndicator(
  size: 40,
  color: AppColors.primary,
)
```

### 2. User Entity

```dart
import 'package:oro_high_scanner/domain/entities/user.dart';

const user = User(
  id: '1',
  email: 'admin@orohigh.com',
  name: 'Admin User',
  role: UserRole.admin,
  createdAt: DateTime.now(),
);
```

### 3. Error Handling

```dart
import 'package:oro_high_scanner/core/error/failures.dart';

// Use specific failure types
const failure = AuthenticationFailure('Invalid credentials');
const networkFailure = NetworkFailure('No internet connection');
```

## Migration Steps

### Step 1: Update Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  equatable: ^2.0.5
```

Run:
```bash
flutter pub get
```

### Step 2: Update Imports
Replace old imports with new paths:
```dart
// Old
import 'screens/login_screen.dart';

// New
import 'presentation/screens/auth/login_screen.dart';
```

### Step 3: Replace Hardcoded Values
Replace colors:
```dart
// Old
Color(0xFF6C63FF)

// New
AppColors.primary
```

Replace strings:
```dart
// Old
'Welcome to'

// New
AppStrings.welcomeTo
```

### Step 4: Use Reusable Components
Replace custom widgets with reusable components:

```dart
// Old
ElevatedButton(
  onPressed: _handleLogin,
  child: Text('LOGIN'),
)

// New
CustomButton(
  text: AppStrings.login,
  onPressed: _handleLogin,
)
```

### Step 5: Implement Validators
Replace inline validation with centralized validators:

```dart
// Old
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  return null;
}

// New
validator: Validators.validateEmail
```

## Testing the Migration

### 1. Run the App
```bash
flutter run
```

### 2. Verify Features
- [ ] Login screen displays correctly
- [ ] Email validation works
- [ ] Password validation works
- [ ] Password visibility toggle works
- [ ] Loading state shows during login
- [ ] Responsive design works (desktop and mobile)
- [ ] Colors match the design
- [ ] Illustration displays correctly

### 3. Check for Errors
```bash
flutter analyze
```

## Common Issues and Solutions

### Issue 1: Import Errors
**Error:** `Target of URI doesn't exist`

**Solution:** Update import paths to match new structure
```dart
import 'presentation/screens/auth/login_screen.dart';
```

### Issue 2: Missing Dependencies
**Error:** `Package not found: equatable`

**Solution:** Run `flutter pub get`

### Issue 3: Color Not Found
**Error:** `Undefined name 'AppColors'`

**Solution:** Import the constants
```dart
import 'package:oro_high_scanner/core/constants/app_colors.dart';
```

## Benefits After Migration

### 1. Maintainability
- ✅ Easy to find and update colors
- ✅ Easy to update text strings
- ✅ Clear separation of concerns

### 2. Reusability
- ✅ Reusable button component
- ✅ Reusable text field component
- ✅ Reusable validation logic

### 3. Testability
- ✅ Easy to test validators
- ✅ Easy to test widgets
- ✅ Easy to mock dependencies

### 4. Scalability
- ✅ Easy to add new screens
- ✅ Easy to add new features
- ✅ Clear structure for team collaboration

### 5. Consistency
- ✅ Consistent colors across app
- ✅ Consistent text styles
- ✅ Consistent validation messages

## Next Steps

### 1. Add State Management
Install flutter_bloc:
```yaml
dependencies:
  flutter_bloc: ^8.1.3
```

Uncomment the AuthBloc implementation in:
`lib/presentation/bloc/auth/auth_bloc.dart`

### 2. Implement Use Cases
Create login use case:
```dart
// lib/domain/usecases/auth/login_usecase.dart
class LoginUseCase {
  final AuthRepository repository;
  
  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  });
}
```

### 3. Implement Repositories
Create auth repository:
```dart
// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, void>> logout();
}
```

### 4. Implement Data Sources
Create remote data source:
```dart
// lib/data/datasources/remote/auth_remote_datasource.dart
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
}
```

### 5. Set Up Dependency Injection
Install get_it:
```yaml
dependencies:
  get_it: ^7.6.4
```

Create injection container:
```dart
// lib/core/di/injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(() => AuthBloc(loginUseCase: sl()));
  
  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  
  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
}
```

## Rollback Plan

If you need to rollback to the old structure:

1. Restore the old `lib/screens/login_screen.dart` file
2. Update `main.dart` to import from old path
3. Remove new directories (core, domain, presentation)
4. Run `flutter pub get`

## Support

For questions or issues:
1. Check the ARCHITECTURE_README.md
2. Review the 4_LAYER_STRUCTURE.md
3. Examine example implementations in the code

## Conclusion

The migration to clean architecture provides a solid foundation for:
- Building the QR scanner feature
- Implementing CSV import
- Adding role-based access control
- Creating admin dashboard
- Scaling the application

The initial investment in structure will pay off as the application grows.
