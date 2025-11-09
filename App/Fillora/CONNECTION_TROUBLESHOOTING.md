# Fix "Couldn't Connect" to Android Device

## 🔍 Common Issues and Solutions

### Issue 1: USB Debugging Not Authorized

**Solution:**
1. **On your phone:**
   - Disconnect USB cable
   - Go to: **Settings → Developer Options → Revoke USB debugging authorizations**
   - Reconnect USB cable
   - You should see: **"Allow USB debugging?"** popup
   - Check **"Always allow from this computer"**
   - Tap **"Allow"**

---

### Issue 2: USB Mode Not Set Correctly

**Solution:**
1. **On your phone:**
   - Swipe down from top → Check USB notification
   - Tap on USB notification
   - Select **"File Transfer"** or **"MTP"** (NOT "Charging only")

---

### Issue 3: Developer Options Not Enabled

**Solution:**
1. **On your phone:**
   - Go to: **Settings → About Phone**
   - Tap **"Build Number"** 7 times (until you see "You are now a developer")
   - Go back to: **Settings → Developer Options**
   - Make sure **"USB Debugging"** is **ON**

---

### Issue 4: Wrong USB Cable or Port

**Solution:**
1. Try a **different USB cable** (some cables are charge-only)
2. Try a **different USB port** on your laptop
3. Make sure it's a **data cable**, not just a charging cable

---

### Issue 5: Driver Issues (Windows)

**Solution:**
1. **Install Android USB Drivers:**
   - Go to your phone manufacturer's website
   - Download USB drivers for your phone model
   - Or download Google USB Driver: https://developer.android.com/studio/run/win-usb
   - Install the drivers
   - Restart your computer

---

### Issue 6: Multiple ADB Servers Running

**Solution:**
1. **Close Android Studio** (if open) - it might have its own ADB server
2. **Close any other tools** using ADB
3. **Restart your terminal** and try again

---

## ✅ Quick Fix Steps (Try These First)

### Step 1: Check Phone Settings
- [ ] USB Debugging is ON
- [ ] USB mode is "File Transfer" (not "Charging only")
- [ ] Phone screen is unlocked

### Step 2: Reconnect USB
1. **Unplug USB cable** from phone
2. **Wait 5 seconds**
3. **Plug it back in**
4. **Check phone** for "Allow USB debugging?" popup
5. **Tap "Allow"**

### Step 3: Verify Connection
```bash
flutter devices
```
Should show your phone: `A001 (mobile)`

### Step 4: If Still Not Working
```bash
# Close Android Studio if open
# Then in terminal:
flutter clean
flutter pub get
flutter devices
```

---

## 🔧 Alternative: Use Wireless Debugging (Android 11+)

If USB keeps having issues, try wireless debugging:

1. **On your phone:**
   - Go to: **Settings → Developer Options**
   - Enable **"Wireless debugging"**
   - Tap **"Wireless debugging"** → **"Pair device with pairing code"**
   - Note the **IP address and port** (e.g., 192.168.1.100:12345)

2. **On your laptop:**
   ```bash
   adb pair <IP>:<PORT>
   # Enter the pairing code when prompted
   adb connect <IP>:<PORT>
   ```

---

## 📱 Phone-Specific Troubleshooting

### Samsung:
- May need **Samsung USB Drivers**
- Try **Samsung Smart Switch** or **Samsung Kies**

### Huawei/Xiaomi:
- May need **HiSuite** (Huawei) or **Mi USB Drivers** (Xiaomi)
- Check manufacturer's website for specific drivers

### OnePlus:
- May need **OnePlus USB Drivers**
- Check OnePlus support website

---

## 🆘 Still Not Working?

**Try this step-by-step:**

1. **Close everything** (Android Studio, VS Code, etc.)
2. **Unplug USB cable**
3. **On phone:** Settings → Developer Options → Revoke USB debugging authorizations
4. **Restart your laptop**
5. **Reconnect USB cable**
6. **Allow USB debugging** on phone
7. **Set USB mode to "File Transfer"**
8. **Run:** `flutter devices`

---

## ✅ Success Indicators

When everything is working:
- ✅ `flutter devices` shows your phone
- ✅ No "unauthorized" message
- ✅ Phone shows "USB debugging connected" in notification
- ✅ Can run `flutter run` successfully

---

**Most common fix: Revoke USB debugging, reconnect, and tap "Allow" on the popup!** 📱

