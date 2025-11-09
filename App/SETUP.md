# Flutter App Setup Guide

## Quick Start

1. **Install Flutter**
   - Download from https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Run `flutter doctor` to verify installation

2. **Navigate to Project Directory**
   ```bash
   cd /path/to/Fillora
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

```
Fillora/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── theme/
│   │   └── app_theme.dart          # Theme configuration
│   ├── widgets/                     # Reusable widgets
│   │   ├── bottom_navigation.dart
│   │   ├── stat_card.dart
│   │   └── action_card.dart
│   └── screens/                     # All app screens
│       ├── onboarding_screen.dart
│       ├── dashboard_screen.dart
│       ├── signin_screen.dart
│       ├── signup_screen.dart
│       ├── templates_screen.dart
│       ├── history_screen.dart
│       ├── settings_screen.dart
│       ├── form_selection_screen.dart
│       ├── document_upload_screen.dart
│       ├── conversational_form_screen.dart
│       └── review_screen.dart
├── pubspec.yaml                     # Dependencies
├── analysis_options.yaml           # Linter rules
└── README-FLUTTER.md               # Detailed documentation
```

## Running on Different Platforms

### Android
```bash
flutter run -d android
# or
flutter build apk
```

### iOS
```bash
flutter run -d ios
# or
flutter build ios
```

### Web
```bash
flutter run -d chrome
# or
flutter build web
```

## Features Implemented

✅ All web screens converted to Flutter
✅ Theme system (6 themes)
✅ Navigation with go_router
✅ Bottom navigation bar
✅ Form filling interface
✅ Document upload
✅ Settings with theme switcher
✅ History and templates
✅ Responsive design

## Next Steps

1. Add backend API integration
2. Implement authentication
3. Add local database for offline support
4. Add app icons and splash screen
5. Write unit and widget tests
6. Build for production

## Troubleshooting

### Dependencies not installing
```bash
flutter clean
flutter pub get
```

### Build errors
```bash
flutter doctor
flutter upgrade
```

### Theme not applying
- Restart the app after changing theme
- Theme is saved in SharedPreferences

## Support

For issues or questions, refer to:
- Flutter documentation: https://flutter.dev/docs
- Go Router: https://pub.dev/packages/go_router
- Shared Preferences: https://pub.dev/packages/shared_preferences

