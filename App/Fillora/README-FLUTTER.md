# Fillora.in - Flutter Mobile Application

A complete Flutter mobile application for Fillora.in - AI-powered form assistant.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # Theme configuration
├── widgets/
│   ├── bottom_navigation.dart
│   ├── stat_card.dart
│   └── action_card.dart
└── screens/
    ├── onboarding_screen.dart
    ├── dashboard_screen.dart
    ├── signin_screen.dart
    ├── signup_screen.dart
    ├── templates_screen.dart
    ├── history_screen.dart
    ├── settings_screen.dart
    ├── form_selection_screen.dart
    ├── document_upload_screen.dart
    ├── conversational_form_screen.dart
    └── review_screen.dart
```

## Features

- ✅ Complete Flutter implementation of all web screens
- ✅ Multiple theme support (Light, Dark, Green, Purple, Orange, Pink)
- ✅ Bottom navigation with floating action button
- ✅ Form filling with AI chat interface
- ✅ Document upload functionality
- ✅ Settings with theme switcher
- ✅ History and templates screens
- ✅ Responsive design for all screen sizes

## Setup Instructions

1. **Install Flutter**
   ```bash
   # Follow official Flutter installation guide
   # https://flutter.dev/docs/get-started/install
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

## Dependencies

- `go_router` - Navigation and routing
- `shared_preferences` - Theme persistence
- `file_picker` - Document selection
- `image_picker` - Camera functionality
- `flutter_svg` - SVG icons (if needed)

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (optional)

## Theme System

The app supports 6 themes:
- Light (default)
- Dark
- Green
- Purple
- Orange
- Pink

Theme preference is saved using `shared_preferences` and persists across app restarts.

## Navigation

Uses `go_router` for declarative navigation:
- `/onboarding` - Welcome screen
- `/signin` - Sign in page
- `/signup` - Sign up page
- `/dashboard` - Main dashboard
- `/templates` - Form templates
- `/history` - Form history
- `/settings` - Settings page
- `/form-selection` - Start new form
- `/document-upload` - Upload documents
- `/conversational-form` - Form filling interface
- `/review` - Review and submit

## Next Steps

1. **Add App Icons**
   - Create app icons for Android and iOS
   - Update `pubspec.yaml` with icon paths

2. **Add Backend Integration**
   - Connect to API endpoints
   - Implement authentication
   - Add form submission logic

3. **Add Local Storage**
   - Implement form data persistence
   - Add offline support

4. **Testing**
   - Add unit tests
   - Add widget tests
   - Add integration tests

5. **Build for Production**
   ```bash
   flutter build apk        # Android
   flutter build ios        # iOS
   flutter build web        # Web
   ```

## Notes

- All screens are implemented with Material Design 3
- The app uses a consistent design system
- Navigation is handled through `go_router`
- Theme switching requires app restart (can be improved with Provider/Riverpod)

