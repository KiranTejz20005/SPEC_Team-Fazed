# Phone Checklist - What to Check on Your Phone

## ✅ Things to Check/Allow on Your Phone

### 1. USB Debugging Authorization (Most Important!)

**If this is the first time connecting:**
- You should see a popup on your phone: **"Allow USB debugging?"**
- Check the box: **"Always allow from this computer"**
- Tap **"Allow"** or **"OK"**

**If you don't see this popup:**
- Disconnect and reconnect the USB cable
- Or go to: **Settings → Developer Options → Revoke USB debugging authorizations**
- Then reconnect the USB cable

---

### 2. Allow App Installation (If Prompted)

**When Flutter installs the app:**
- You might see: **"Install from unknown source?"** or **"Install this app?"**
- Tap **"Allow"** or **"Install"**
- This is safe - Flutter is installing the debug version of your app

---

### 3. Check USB Connection Mode

**Make sure USB is in File Transfer mode:**
- Swipe down from top of phone → Check USB notification
- Should say **"File Transfer"** or **"MTP"**
- If it says "Charging only", tap it and select **"File Transfer"**

---

### 4. Keep Phone Unlocked

- Keep your phone screen **unlocked** during installation
- Some phones lock and stop the installation process

---

### 5. Check Developer Options Are Enabled

**If USB debugging isn't working:**
- Go to: **Settings → About Phone**
- Tap **"Build Number"** 7 times (until you see "You are now a developer")
- Go back to: **Settings → Developer Options**
- Make sure **"USB Debugging"** is **ON**

---

## 🔍 What to Look For

### On Your Phone Screen:
- ✅ USB debugging authorization popup → **Tap "Allow"**
- ✅ App installation prompt → **Tap "Install"**
- ✅ USB notification → Should say **"File Transfer"**

### In Terminal:
- ✅ Should see: `Running Gradle task 'assembleDebug'...`
- ✅ Should see: `Installing APK...`
- ✅ Should see: `Launching lib/main.dart on A001...`

---

## 🆘 Troubleshooting

### If Nothing Happens:

1. **Check USB connection:**
   ```bash
   flutter devices
   ```
   Should show your phone: `A001 (mobile)`

2. **Check ADB connection:**
   ```bash
   adb devices
   ```
   Should show: `00195658T001904    device` (not "unauthorized")

3. **Restart ADB:**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

### If You See "Unauthorized":

- Check your phone for the USB debugging popup
- Tap "Allow" and check "Always allow from this computer"

---

## 📱 Quick Phone Checklist

- [ ] USB cable connected
- [ ] USB debugging enabled (Settings → Developer Options)
- [ ] USB debugging authorization popup → Tap "Allow"
- [ ] USB mode set to "File Transfer" (not "Charging only")
- [ ] Phone screen unlocked
- [ ] App installation prompt → Tap "Install" (if appears)

---

**Most likely you just need to tap "Allow" on the USB debugging popup!** 📱

