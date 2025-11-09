# How to Get SHA-1 Fingerprint for Android OAuth

## 🔍 Problem: Debug Keystore Doesn't Exist Yet

The debug keystore is created automatically when you first build/run a Flutter Android app. Let's generate it first.

---

## ✅ Solution 1: Generate Keystore by Running Flutter App (Easiest)

**The keystore will be created automatically when Flutter builds the Android app.**

### Step 1: Make sure your phone is connected
```bash
flutter devices
```
You should see your device: `A001 (mobile)`

### Step 2: Run the app (this will create the keystore)
```bash
flutter run -d 00195658T001904
```

Wait for the app to build and install. This will create the debug keystore automatically.

### Step 3: After the app runs, get SHA-1
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

## ✅ Solution 2: Create Keystore Manually (If Solution 1 Doesn't Work)

### Step 1: Create the .android directory
```powershell
mkdir "$env:USERPROFILE\.android"
```

### Step 2: Generate the debug keystore manually
```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
```

### Step 3: Get SHA-1 fingerprint
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

## ✅ Solution 3: Get SHA-1 from Gradle (Alternative Method)

If you're already running the app, you can also get SHA-1 from Gradle:

### Step 1: Navigate to Android directory
```powershell
cd android
```

### Step 2: Run Gradle task to get signing report
```powershell
.\gradlew signingReport
```

This will show you the SHA-1 fingerprint in the output.

---

## 📋 What to Look For in the Output

When you run the keytool command, look for a line that says:

```
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
```

**Copy the entire SHA-1 value** (the part after "SHA1: ")

---

## 🎯 Quickest Solution Right Now

Since you're already running the app, try this:

1. **Wait for the app to finish building** (if it's still building)
2. **Then run this command:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

If it still says "file does not exist", use Solution 2 to create it manually.

---

## 🔧 Alternative: Use Gradle Signing Report

If you're in the project directory, try:

```powershell
cd android
.\gradlew signingReport
```

Look for the SHA-1 in the output under "Variant: debug" → "SHA1".

---

## 📝 After You Get SHA-1

1. Copy the SHA-1 fingerprint (the long string after "SHA1: ")
2. Go to Google Cloud Console
3. Create OAuth Client ID → Android
4. Package name: `com.fillora.app` (or check your actual package name)
5. Paste the SHA-1 fingerprint
6. Create the Android Client ID

---

**Try Solution 1 first - it's the easiest!** The keystore will be created automatically when Flutter builds the app.

