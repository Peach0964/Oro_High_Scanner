# Oro High Scanner - Login UI

## Overview
A beautiful, modern login screen has been created for the Oro High Scanner system, inspired by the provided design reference. This is a time in/time out QR code scanning system for public schools with DepEd.

## Features Implemented

### Login Screen
- **Responsive Design**: Works on both desktop and mobile devices
  - Desktop: Split-screen layout with form on left and illustration on right
  - Mobile: Stacked layout optimized for smaller screens

- **Modern UI Elements**:
  - Clean, minimalist design with purple gradient theme
  - Email and password input fields with validation
  - Password visibility toggle
  - Rounded login button with hover effects
  - "Sign up" link for new users

- **Visual Design**:
  - Custom gradient backgrounds
  - Animated illustration with:
    - Night sky with stars and moon
    - Mountain landscape
    - School buildings with windows and doors
    - Trees and ground elements
  - Professional color scheme matching the reference image

## File Structure
```
lib/
├── main.dart                 # App entry point
└── screens/
    └── login_screen.dart     # Login UI implementation
```

## Color Scheme
- Primary Purple: `#6C63FF`
- Secondary Purple: `#5A52D5`
- Dark Purple: `#4A42B8`
- Orange Accent: `#FFB347`
- Text Dark: `#2D3748`
- Text Light: `#718096`

## How to Run
1. Ensure Flutter is installed and configured
2. Navigate to the project directory
3. Run: `flutter pub get`
4. Run: `flutter run`

## Next Steps (Based on PLAN_SYSTEM.MD)
The system will include:
1. **CSV Receiver**: Import student data via CSV/Excel
2. **QR Code Generation**: Bulk generation for students
3. **Scanner Interface**: For security guards to scan student IDs
4. **Admin Dashboard**: View all time in/time out records
5. **User Types**: Visitors, Students, Teachers, Faculty Staff

## Form Validation
- Email: Checks for valid email format
- Password: Minimum 6 characters required

## Customization
You can easily customize:
- Colors in the `login_screen.dart` file
- Logo/branding in the top-left corner
- Illustration elements
- Form fields and validation rules

## Notes
- The login functionality is currently a placeholder
- Sign-up navigation is prepared but not yet implemented
- The UI is fully responsive and adapts to different screen sizes
