# Install Android SDK Build-Tools

## 🔧 Fix: Install Android SDK Build-Tools

The build is failing because Android SDK Build-Tools 35 is missing. Here's how to fix it:

---

## ✅ Solution: Install via Android Studio

### Step 1: Open Android Studio

1. **Open Android Studio** (if not already open)

### Step 2: Open SDK Manager

1. **Click:** Tools → SDK Manager
   - Or click the **SDK Manager icon** (looks like a phone with a down arrow)
   - Or press **Ctrl+Alt+S** (Windows/Linux) or **Cmd+,** (Mac)

### Step 3: Install Build Tools

1. **Click on "SDK Tools" tab** (at the top)
2. **Scroll down** and find **"Android SDK Build-Tools"**
3. **Check the box** for **"Android SDK Build-Tools 35"** (or the latest version)
4. **Click "Apply"** or **"OK"**
5. **Click "OK"** in the confirmation dialog
6. **Wait for installation** (this may take a few minutes)

### Step 4: Accept Licenses

After installation, you may need to accept licenses:
1. In SDK Manager, click **"SDK Platforms" tab**
2. Look for any warnings about licenses
3. Or run in terminal: `flutter doctor --android-licenses`
4. Type `y` for each license

---

## 🚀 After Installation

Once Build-Tools are installed, try running again:

```bash
flutter run -d 00195658T001904
```

---

## 📱 Alternative: Try Running Directly

While installing build tools, you can also try:

```bash
flutter run -d 00195658T001904
```

Sometimes `flutter run` works even if `flutter build apk` doesn't.

---

## ⚠️ Note

- The app name on your phone will be **"fillora"** (lowercase, from your `pubspec.yaml`)
- The package name is `com.fillora.app`
- Look for the app icon in your app drawer

---

**Install Build-Tools 35 in Android Studio, then try running the app again!** 🛠️

