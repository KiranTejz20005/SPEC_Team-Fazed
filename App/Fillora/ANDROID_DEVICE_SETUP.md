# Testing Flutter App on Android Device via USB

## ✅ Prerequisites (You've Already Done)
- ✅ USB debugging enabled on phone
- ✅ Phone connected to laptop via USB

---

## Step 1: Verify Device Connection

### Check if Flutter can see your device:

```bash
flutter devices
```

**You should see something like:**
```
2 connected devices:
SM-G991B (mobile) • R58M90ABCDE • android-arm64 • Android 13
Chrome (web) • chrome • web-javascript • Google Chrome 120.0.0.0
```

If you see your device listed, you're good! If not, continue to Step 2.

---

## Step 2: Install Android USB Drivers (Windows Only)

**If you're on Windows and device is not detected:**

1. **Download Android USB Drivers:**
   - Go to your phone manufacturer's website
   - Search for "USB drivers" for your phone model
   - Or use Google USB Driver: https://developer.android.com/studio/run/win-usb

2. **Install the drivers**
3. **Restart your computer** (sometimes required)

---

## Step 3: Enable USB Debugging Authorization

**On your phone:**
1. When you connect via USB, you might see a popup: **"Allow USB debugging?"**
2. Check **"Always allow from this computer"**
3. Tap **"Allow"** or **"OK"**

If you don't see this popup:
- Disconnect and reconnect the USB cable
- Or revoke USB debugging authorizations and reconnect:
  - Go to: **Settings → Developer Options → Revoke USB debugging authorizations**

---

## Step 4: Verify ADB Connection

**Check if ADB (Android Debug Bridge) can see your device:**

```bash
adb devices
```

**You should see:**
```
List of devices attached
R58M90ABCDE    device
```

**If you see "unauthorized":**
- Check your phone for the USB debugging authorization popup
- Tap "Allow"

**If you see nothing:**
- Make sure USB debugging is enabled
- Try a different USB cable (some cables are charge-only)
- Try a different USB port
- Install USB drivers (Step 2)

---

## Step 5: Run Flutter App on Your Device

**Once your device is detected, run:**

```bash
flutter run
```

**Or to specify your device explicitly:**

```bash
flutter run -d <device-id>
```

**To see available devices:**
```bash
flutter devices
```

**Example:**
```bash
flutter run -d R58M90ABCDE
```

---

## Step 6: For Google Sign-In on Android

**Important:** Since you're testing on Android, you need the **Android OAuth Client ID** from Google Cloud Console.

### If you haven't created it yet:

1. Go back to Google Cloud Console
2. Create OAuth Client ID → Select **"Android"**
3. Package name: `com.fillora.app` (or check your actual package name)
4. SHA-1 fingerprint: Get it using:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
5. Copy the SHA-1 and paste in Google Cloud Console
6. Create the Android Client ID

**The Flutter app will automatically use the Android Client ID when running on Android!**

---

## Troubleshooting

### Device Not Detected?

1. **Check USB connection:**
   - Unplug and replug USB cable
   - Try different USB port
   - Try different USB cable

2. **Check USB debugging:**
   - Settings → Developer Options → USB debugging (should be ON)
   - Settings → Developer Options → USB configuration → Select "File Transfer" or "MTP"

3. **Check ADB:**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

4. **Check phone manufacturer:**
   - Some manufacturers require additional drivers
   - Samsung: Samsung USB Drivers
   - Huawei: HiSuite
   - Xiaomi: Mi USB Drivers

### "unauthorized" in ADB?

- Check your phone for the authorization popup
- Tap "Allow" and check "Always allow from this computer"

### Flutter says "No devices found"?

```bash
# Restart ADB
adb kill-server
adb start-server

# Check devices
flutter devices
```

### App installs but crashes on launch?

- Check if you have the Android OAuth Client ID configured
- Check device logs:
  ```bash
  adb logcat | grep flutter
  ```

---

## Quick Commands Reference

```bash
# List all connected devices
flutter devices

# List ADB devices
adb devices

# Run app on specific device
flutter run -d <device-id>

# Run app (Flutter will auto-select device)
flutter run

# Check device logs
adb logcat

# Restart ADB
adb kill-server
adb start-server

# Get SHA-1 for Android OAuth
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

## Next Steps

1. ✅ Verify device connection: `flutter devices`
2. ✅ Run app: `flutter run`
3. ✅ Test Google Sign-In (make sure Android Client ID is configured)
4. ✅ Test Facebook Sign-In

---

**That's it!** Once your device is detected, just run `flutter run` and it will install and launch on your phone! 🚀

