# Quick Start Guide - Oro High Scanner

## Prerequisites
- Flutter SDK (3.11.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

## Installation

### 1. Clone the Repository (if applicable)
```bash
git clone <repository-url>
cd oro_high_scanner
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the Application
```bash
flutter run
```

For specific platforms:
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## Project Structure Overview

```
oro_high_scanner/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/                        # Shared utilities
│   │   ├── constants/              # Colors, strings, routes
│   │   ├── utils/                  # Validators, helpers
│   │   └── error/                  # Error handling
│   ├── domain/                      # Business logic
│   │   └── entities/               # Core entities
│   └── presentation/                # UI layer
│       ├── screens/                # App screens
│       ├── widgets/                # Reusable widgets
│       └── bloc/                   # State management
├── asset/                           # Images and assets
├── android/                         # Android config
├── ios/                            # iOS config
├── web/                            # Web config
└── test/                           # Tests
```

## Key Features

### 1. Login Screen ✅
- Email and password authentication
- Form validation
- Responsive design (desktop & mobile)
- Beautiful illustration
- Loading states

### 2. User Roles (Prepared)
- Admin
- Teacher
- Security Guard
- Student
- Visitor
- Faculty Staff

### 3. Architecture
- Clean 4-layer architecture
- Separation of concerns
- Reusable components
- Easy to test and maintain

## Common Commands

### Development
```bash
# Run in debug mode
flutter run

# Run with hot reload
# (Press 'r' in terminal after making changes)

# Run in release mode
flutter run --release
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android)
flutter build appbundle

# Build iOS
flutter build ios

# Build Web
flutter build web

# Build Windows
flutter build windows
```

## Configuration

### 1. App Name
Update in `pubspec.yaml`:
```yaml
name: oro_high_scanner
description: "Time In/Time Out QR Code Scanner for DepEd Schools"
```

### 2. App Icon
Replace icons in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### 3. Colors
Edit `lib/core/constants/app_colors.dart`:
```dart
static const Color primary = Color(0xFF6C63FF);
```

### 4. Strings
Edit `lib/core/constants/app_strings.dart`:
```dart
static const String appName = 'OroHigh Scanner';
```

## Using Reusable Components

### CustomButton
```dart
import 'package:oro_high_scanner/presentation/widgets/common/custom_button.dart';

CustomButton(
  text: 'Click Me',
  onPressed: () {
    // Handle click
  },
  isLoading: false,
)
```

### CustomTextField
```dart
import 'package:oro_high_scanner/presentation/widgets/common/custom_text_field.dart';
import 'package:oro_high_scanner/core/utils/validators.dart';

CustomTextField(
  controller: _controller,
  label: 'Email',
  hintText: 'Enter your email',
  validator: Validators.validateEmail,
)
```

### LoadingIndicator
```dart
import 'package:oro_high_scanner/presentation/widgets/common/loading_indicator.dart';

LoadingIndicator(
  size: 40,
  color: AppColors.primary,
)
```

## Adding New Screens

### 1. Create Screen File
```dart
// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: Text('Dashboard Content'),
      ),
    );
  }
}
```

### 2. Add Route
In `lib/core/constants/app_routes.dart`:
```dart
static const String dashboard = '/dashboard';
```

### 3. Navigate
```dart
Navigator.pushNamed(context, AppRoutes.dashboard);
```

## Troubleshooting

### Issue: Dependencies not found
```bash
flutter pub get
flutter clean
flutter pub get
```

### Issue: Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Hot reload not working
```bash
# Press 'R' (capital R) for hot restart
# Or restart the app completely
```

### Issue: Emulator not detected
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Development Workflow

### 1. Create Feature Branch
```bash
git checkout -b feature/scanner-screen
```

### 2. Make Changes
- Edit files
- Test changes with hot reload
- Run `flutter analyze`

### 3. Test
```bash
flutter test
```

### 4. Commit
```bash
git add .
git commit -m "Add scanner screen"
```

### 5. Push
```bash
git push origin feature/scanner-screen
```

## Next Features to Implement

### Phase 1: Authentication
- [ ] Connect to backend API
- [ ] Implement login logic
- [ ] Add sign up screen
- [ ] Add forgot password
- [ ] Store auth token

### Phase 2: QR Scanner
- [ ] Add camera permission
- [ ] Implement QR scanner
- [ ] Save scan records
- [ ] Display scan history

### Phase 3: Student Management
- [ ] CSV import screen
- [ ] Student list screen
- [ ] QR code generation
- [ ] Bulk operations

### Phase 4: Admin Dashboard
- [ ] Time in/out reports
- [ ] User management
- [ ] Analytics
- [ ] Settings

## Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)

### Packages Used
- `equatable` - Value equality
- `cupertino_icons` - iOS style icons

### Recommended Packages
- `flutter_bloc` - State management
- `dio` - HTTP client
- `get_it` - Dependency injection
- `qr_code_scanner` - QR scanning
- `qr_flutter` - QR generation
- `excel` - Excel file handling

## Support

### Getting Help
1. Check documentation files:
   - `ARCHITECTURE_README.md`
   - `4_LAYER_STRUCTURE.md`
   - `MIGRATION_GUIDE.md`

2. Review code examples in `lib/presentation/`

3. Check Flutter documentation

## Tips

### Performance
- Use `const` constructors when possible
- Avoid rebuilding widgets unnecessarily
- Use `ListView.builder` for long lists

### Code Quality
- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused

### Testing
- Write unit tests for business logic
- Write widget tests for UI components
- Write integration tests for user flows

## Conclusion

You're now ready to start developing with Oro High Scanner! The foundation is set with:
- ✅ Clean architecture
- ✅ Reusable components
- ✅ Beautiful UI
- ✅ Proper structure

Start by exploring the login screen and then move on to implementing the next features according to PLAN_SYSTEM.md.

Happy coding! 🚀
