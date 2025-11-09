# Flutter OAuth Setup - Multiple Platforms Guide

## 🎯 Important: Flutter Needs Multiple Client IDs!

Since Flutter can run on **Web, Android, and iOS**, you need **3 separate OAuth Client IDs**:

1. ✅ **Web application** - For web builds
2. ✅ **Android** - For Android builds
3. ✅ **iOS** - For iOS builds

**Don't worry!** You'll create them one by one. Let's start with what you see now.

---

## 📱 Step-by-Step: Create All Three Client IDs

### Part 1: Create Web Application Client ID (You're Here Now!)

**You're currently on the "Create OAuth client ID" page with "Web application" selected.**

#### Complete the Web Application Setup:

1. **Application type:** 
   - ✅ Should already show "Web application" (keep it selected)

2. **Name:**
   - Enter: `Fillora Web Client`

3. **Authorized JavaScript origins:**
   - Click **"+ ADD URI"**
   - Add these URIs (one at a time):
     - `http://localhost:3000`
     - `http://localhost:8080`
     - `http://localhost`
     - `https://yourdomain.com` (if you have a domain)
   - Click **"+ ADD URI"** for each

4. **Authorized redirect URIs:**
   - Click **"+ ADD URI"**
   - Add the same URIs as above:
     - `http://localhost:3000`
     - `http://localhost:8080`
     - `http://localhost`
     - `https://yourdomain.com`

5. **Click "CREATE"**

6. **Copy the Web Client ID:**
   - A popup will show your Client ID
   - **Copy it** and save it as: `WEB_CLIENT_ID`
   - It looks like: `123456789-abc...apps.googleusercontent.com`
   - Click "OK"

✅ **Web Client ID Done!** Save this for your `signin.html` and `auth.js` files.

---

### Part 2: Create Android Client ID

**After completing the Web one, create the Android Client ID:**

1. Click **"+ CREATE CREDENTIALS"** again (at the top)
2. Select **"OAuth client ID"**

3. **Application type:**
   - Select **"Android"** from the dropdown

4. **Name:**
   - Enter: `Fillora Android Client`

5. **Package name:**
   - Enter: `com.fillora.app`
   - ⚠️ **Important:** This must match your Flutter app's package name
   - To check your package name, look in `android/app/build.gradle`:
     ```gradle
     android {
         defaultConfig {
             applicationId "com.fillora.app"  // <-- This is your package name
         }
     }
     ```

6. **SHA-1 certificate fingerprint:**
   - You need to get this from your debug keystore
   - **For Windows**, run this command in PowerShell:
     ```powershell
     keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```
   - **For Mac/Linux**, run:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Look for the line that says **"SHA1:"**
   - Copy the SHA-1 value (looks like: `AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE`)
   - Paste it in the "SHA-1 certificate fingerprint" field

7. **Click "CREATE"**

8. **Copy the Android Client ID:**
   - Copy it and save it as: `ANDROID_CLIENT_ID`
   - Click "OK"

✅ **Android Client ID Done!**

---

### Part 3: Create iOS Client ID

**After completing the Android one, create the iOS Client ID:**

1. Click **"+ CREATE CREDENTIALS"** again
2. Select **"OAuth client ID"**

3. **Application type:**
   - Select **"iOS"** from the dropdown

4. **Name:**
   - Enter: `Fillora iOS Client`

5. **Bundle ID:**
   - Enter: `com.fillora.app`
   - ⚠️ **Important:** This must match your Flutter app's bundle ID
   - To check your bundle ID, look in `ios/Runner/Info.plist`:
     ```xml
     <key>CFBundleIdentifier</key>
     <string>com.fillora.app</string>  <!-- <-- This is your bundle ID -->
     ```

6. **Click "CREATE"**

7. **Copy the iOS Client ID:**
   - Copy it and save it as: `IOS_CLIENT_ID`
   - Click "OK"

✅ **iOS Client ID Done!**

---

## 📋 Summary: What You'll Have

After completing all three, you'll have:

| Platform | Client ID Name | Where to Use It |
|----------|---------------|-----------------|
| **Web** | `Fillora Web Client` | `signin.html` and `auth.js` |
| **Android** | `Fillora Android Client` | Flutter Android builds (automatic) |
| **iOS** | `Fillora iOS Client` | Flutter iOS builds (automatic) |

---

## 🎯 What to Do Right Now

**Since you're already on the Web application setup:**

1. ✅ **Complete the Web application setup** (follow Part 1 above)
2. ✅ **Save the Web Client ID** - you'll need it for your web files
3. ✅ **Then create Android Client ID** (follow Part 2)
4. ✅ **Then create iOS Client ID** (follow Part 3)

---

## 💡 Why Do You Need All Three?

- **Web Client ID:** Used when you run `flutter run -d chrome` or build for web
- **Android Client ID:** Used when you run on Android device/emulator
- **iOS Client ID:** Used when you run on iOS device/simulator

The Flutter packages (`google_sign_in` and `flutter_facebook_auth`) will automatically use the correct Client ID based on which platform you're running on.

---

## 🔧 Quick Commands to Get Package Info

**Check Android Package Name:**
```bash
# Windows PowerShell
Get-Content android\app\build.gradle | Select-String "applicationId"

# Mac/Linux
grep "applicationId" android/app/build.gradle
```

**Get SHA-1 for Android:**
```powershell
# Windows
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Mac/Linux  
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## ✅ Next Steps After Getting All Client IDs

1. **For Web:** Update `signin.html` and `auth.js` with your Web Client ID
2. **For Android:** The Flutter package will automatically use the Android Client ID (if configured correctly)
3. **For iOS:** The Flutter package will automatically use the iOS Client ID (if configured correctly)

---

**Don't worry about creating all three right now!** Just complete the Web one first, then come back to create the Android and iOS ones when you're ready to test on mobile devices.

