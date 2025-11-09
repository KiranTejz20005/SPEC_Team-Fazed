# Authentication Setup Guide - Google & Facebook Sign-In

This guide will walk you through setting up Google and Facebook authentication for Fillora.in.

## 📋 Table of Contents
1. [Google Sign-In Setup](#google-sign-in-setup)
2. [Facebook Sign-In Setup](#facebook-sign-in-setup)
3. [Flutter Configuration](#flutter-configuration)
4. [Web Configuration](#web-configuration)
5. [Testing](#testing)

---

## 🔵 Google Sign-In Setup

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click on the project dropdown and select **"New Project"**
3. Enter project name: `Fillora` (or your preferred name)
4. Click **"Create"**

### Step 2: Enable Google Sign-In API

1. In the Google Cloud Console, go to **"APIs & Services" > "Library"**
2. Search for **"Google Sign-In API"** or **"Google+ API"**
3. Click on it and press **"Enable"**

### Step 3: Create OAuth 2.0 Credentials

1. Go to **"APIs & Services" > "Credentials"**
2. Click **"Create Credentials" > "OAuth client ID"**
3. If prompted, configure the OAuth consent screen:
   - Choose **"External"** (unless you have a Google Workspace)
   - Fill in the required fields:
     - App name: `Fillora.in`
     - User support email: Your email
     - Developer contact: Your email
   - Add scopes: `email`, `profile`
   - Add test users (if in testing mode)
   - Save and continue

4. Create OAuth Client IDs for different platforms:

   **For Web:**
   - Application type: **"Web application"**
   - Name: `Fillora Web`
   - Authorized JavaScript origins:
     - `http://localhost:3000` (for local testing)
     - `https://yourdomain.com` (your production domain)
   - Authorized redirect URIs:
     - `http://localhost:3000` (for local testing)
     - `https://yourdomain.com` (your production domain)
   - Click **"Create"**
   - **Copy the Client ID** (looks like: `123456789-abcdefghijklmnop.apps.googleusercontent.com`)

   **For Android (if needed):**
   - Application type: **"Android"**
   - Name: `Fillora Android`
   - Package name: `com.fillora.app` (or your package name)
   - SHA-1 certificate fingerprint: (Get from your keystore)
   - Click **"Create"**

   **For iOS (if needed):**
   - Application type: **"iOS"**
   - Name: `Fillora iOS`
   - Bundle ID: `com.fillora.app` (or your bundle ID)
   - Click **"Create"**

### Step 4: Get Your Google Client ID

Your Google Client ID will look like:
```
123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
```

---

## 🔷 Facebook Sign-In Setup

### Step 1: Create a Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **"My Apps" > "Create App"**
3. Select **"Consumer"** or **"Business"** as app type
4. Fill in:
   - App Display Name: `Fillora`
   - App Contact Email: Your email
5. Click **"Create App"**

### Step 2: Add Facebook Login Product

1. In your app dashboard, go to **"Add Products"**
2. Find **"Facebook Login"** and click **"Set Up"**
3. Choose **"Web"** as the platform

### Step 3: Configure Facebook Login Settings

1. Go to **"Facebook Login" > "Settings"**
2. Under **"Valid OAuth Redirect URIs"**, add:
   - `http://localhost:3000` (for local testing)
   - `https://yourdomain.com` (your production domain)
   - `https://yourdomain.com/auth/facebook/callback`
3. Click **"Save Changes"**

### Step 4: Get Your Facebook App ID and App Secret

1. Go to **"Settings" > "Basic"**
2. Note down:
   - **App ID** (looks like: `1234567890123456`)
   - **App Secret** (click "Show" to reveal it)

### Step 5: Configure App Domains

1. In **"Settings" > "Basic"**, scroll to **"App Domains"**
2. Add your domain:
   - `yourdomain.com`
   - `localhost` (for testing)

### Step 6: Configure Privacy Policy URL (Required)

1. In **"Settings" > "Basic"**, add:
   - Privacy Policy URL: `https://yourdomain.com/privacy`
   - Terms of Service URL: `https://yourdomain.com/terms`

---

## 📱 Flutter Configuration

### Step 1: Update Android Configuration

**File: `android/app/build.gradle`**

Ensure you have the correct package name and SHA-1 certificate:

```gradle
android {
    defaultConfig {
        applicationId "com.fillora.app" // Your package name
        // ... other config
    }
}
```

**Get SHA-1 Certificate:**
```bash
# For debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

Copy the SHA-1 fingerprint and add it to your Google Cloud Console OAuth credentials.

**File: `android/app/src/main/AndroidManifest.xml`**

Add internet permission (if not already present):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Step 2: Update iOS Configuration

**File: `ios/Runner/Info.plist`**

Add URL schemes for Google Sign-In:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>
```

**File: `ios/Runner/Info.plist`**

Add Facebook App ID:
```xml
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookDisplayName</key>
<string>Fillora</string>
```

### Step 3: Create Configuration File (Optional but Recommended)

Create a file `lib/config/auth_config.dart`:

```dart
class AuthConfig {
  // Google Sign-In
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  
  // Facebook
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
  
  // For web
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
}
```

Then update `lib/services/auth_service.dart` to use these configs.

---

## 🌐 Web Configuration

### Step 1: Update signin.html

Replace the placeholder values in `signin.html`:

```html
<div id="g_id_onload" 
     data-client_id="YOUR_GOOGLE_CLIENT_ID" 
     data-callback="handleGoogleSignIn">
</div>
```

### Step 2: Update auth.js

Replace the placeholder values in `auth.js`:

**Line 171:** Facebook App ID
```javascript
FB.init({
    appId: 'YOUR_FACEBOOK_APP_ID', // Replace with your Facebook App ID
    // ...
});
```

**Line 181:** Google Client ID
```javascript
google.accounts.id.initialize({
    client_id: 'YOUR_GOOGLE_CLIENT_ID', // Replace with your Google Client ID
    // ...
});
```

**Line 269:** Google Client ID (fallback)
```javascript
google.accounts.oauth2.initTokenClient({
    client_id: 'YOUR_GOOGLE_CLIENT_ID',
    // ...
});
```

### Step 3: Update signin.html Google Config

**Line 110:** Update the Google Sign-In div:
```html
<div id="g_id_onload" 
     data-client_id="YOUR_GOOGLE_CLIENT_ID" 
     data-callback="handleGoogleSignIn">
</div>
```

---

## 🔑 Summary of Required API Keys

### Google Sign-In
- **Client ID (Web):** `YOUR_GOOGLE_CLIENT_ID`
- **Client ID (Android):** `YOUR_GOOGLE_ANDROID_CLIENT_ID` (if needed)
- **Client ID (iOS):** `YOUR_GOOGLE_IOS_CLIENT_ID` (if needed)

### Facebook Sign-In
- **App ID:** `YOUR_FACEBOOK_APP_ID`
- **App Secret:** `YOUR_FACEBOOK_APP_SECRET` (for backend verification, not needed in frontend)

---

## 📝 Files to Update

### Flutter Files:
1. `lib/services/auth_service.dart` - Already configured, may need to add config file
2. `lib/screens/signin_screen.dart` - Already configured
3. `android/app/build.gradle` - Verify package name
4. `android/app/src/main/AndroidManifest.xml` - Add permissions
5. `ios/Runner/Info.plist` - Add URL schemes and Facebook config

### Web Files:
1. `signin.html` - Replace `YOUR_GOOGLE_CLIENT_ID` (line 110)
2. `auth.js` - Replace:
   - `YOUR_FACEBOOK_APP_ID` (line 171)
   - `YOUR_GOOGLE_CLIENT_ID` (lines 181, 269)

---

## ✅ Testing

### Test Google Sign-In:
1. **Web:**
   - Open `signin.html` in a browser
   - Click "Google" button
   - Should open Google sign-in popup
   - After signing in, should redirect to dashboard

2. **Flutter:**
   - Run the app
   - Go to sign-in screen
   - Tap Google button
   - Should show Google sign-in dialog
   - After signing in, should navigate to dashboard

### Test Facebook Sign-In:
1. **Web:**
   - Open `signin.html` in a browser
   - Click "Facebook" button
   - Should open Facebook login popup
   - After logging in, should redirect to dashboard

2. **Flutter:**
   - Run the app
   - Go to sign-in screen
   - Tap Facebook button
   - Should show Facebook login dialog
   - After logging in, should navigate to dashboard

---

## 🔒 Security Best Practices

1. **Never commit API keys to version control**
   - Use environment variables
   - Use `.env` files (add to `.gitignore`)
   - Use secure configuration files

2. **Use HTTPS in production**
   - Both Google and Facebook require HTTPS for production

3. **Validate tokens on backend**
   - Always verify tokens on your backend server
   - Don't trust client-side tokens alone

4. **Handle errors gracefully**
   - Show user-friendly error messages
   - Log errors for debugging

---

## 🐛 Troubleshooting

### Google Sign-In Issues:
- **"Error 400: redirect_uri_mismatch"**
  - Check authorized redirect URIs in Google Cloud Console
  - Ensure they match exactly (including http/https)

- **"Error 403: access_denied"**
  - Check OAuth consent screen configuration
  - Ensure app is published or test users are added

### Facebook Sign-In Issues:
- **"App Not Setup"**
  - Ensure Facebook Login product is added
  - Check app is in development mode and add test users

- **"Invalid OAuth Redirect URI"**
  - Verify redirect URIs in Facebook App Settings
  - Check App Domains configuration

---

## 📚 Additional Resources

- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in/web)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login/)
- [Flutter Google Sign-In Package](https://pub.dev/packages/google_sign_in)
- [Flutter Facebook Auth Package](https://pub.dev/packages/flutter_facebook_auth)

---

## 🎯 Quick Start Checklist

- [ ] Google Cloud Project created
- [ ] Google OAuth credentials created (Web, Android, iOS)
- [ ] Google Client ID copied
- [ ] Facebook App created
- [ ] Facebook Login product added
- [ ] Facebook App ID and Secret copied
- [ ] OAuth redirect URIs configured
- [ ] Flutter Android configuration updated
- [ ] Flutter iOS configuration updated
- [ ] Web HTML/JS files updated with API keys
- [ ] Tested Google sign-in (Web)
- [ ] Tested Google sign-in (Flutter)
- [ ] Tested Facebook sign-in (Web)
- [ ] Tested Facebook sign-in (Flutter)

---

**Need Help?** Check the documentation links above or refer to the official provider documentation.

