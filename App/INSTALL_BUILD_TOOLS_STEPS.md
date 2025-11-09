# Step-by-Step: Install Android SDK Build-Tools 35

## 📋 Complete Installation Guide

### Step 1: Open Android Studio

1. **On your laptop**, open **Android Studio**
2. If it's not open, find it in:
   - **Windows Start Menu** → Search "Android Studio"
   - Or click the **Android Studio icon** on your desktop

---

### Step 2: Open SDK Manager

**You have 3 ways to open SDK Manager:**

**Method 1: Via Menu**
1. Click **"Tools"** in the top menu bar
2. Click **"SDK Manager"**

**Method 2: Via Keyboard Shortcut**
- Press **Ctrl+Alt+S** (Windows/Linux)

**Method 3: Via Welcome Screen**
- If you see the welcome screen, click **"More Actions"** → **"SDK Manager"**

---

### Step 3: Navigate to SDK Tools Tab

1. In the SDK Manager window, you'll see **3 tabs** at the top:
   - **SDK Platforms** (default)
   - **SDK Tools** ← **Click this one!**
   - **SDK Update Sites**

2. **Click on "SDK Tools" tab**

---

### Step 4: Find and Check Build Tools

1. **Scroll down** in the list
2. **Look for:** "Android SDK Build-Tools"
3. **You'll see options like:**
   - Android SDK Build-Tools 34
   - **Android SDK Build-Tools 35** ← **Check this one!**
   - Android SDK Build-Tools (other versions)

4. **Check the box** next to **"Android SDK Build-Tools 35"**
   - You can also check "Show Package Details" to see sub-options
   - Make sure **35.0.0** is selected

---

### Step 5: Install

1. **Click the "Apply" button** (at the bottom right)
   - Or click **"OK"** button

2. **A confirmation dialog will appear:**
   - It will show what will be installed
   - Click **"OK"** to confirm

3. **Wait for installation:**
   - You'll see a progress bar
   - It may take **2-5 minutes** depending on your internet speed
   - Don't close Android Studio during installation

---

### Step 6: Verify Installation

1. **Wait for the "Finished" message**
2. **Click "Finish"**
3. **Click "OK"** to close SDK Manager

---

### Step 7: Accept Licenses (If Needed)

If you see any license prompts:

1. **In terminal**, run:
   ```bash
   flutter doctor --android-licenses
   ```

2. **Type `y`** and press Enter for each license
3. **Keep typing `y`** until all licenses are accepted

---

## ✅ After Installation

Once Build-Tools 35 is installed, you can run your app:

```bash
flutter run -d 00195658T001904
```

Or simply:
```bash
flutter run
```

---

## 🎯 Visual Guide Summary

```
Android Studio
    ↓
Tools → SDK Manager
    ↓
Click "SDK Tools" tab
    ↓
Scroll down → Find "Android SDK Build-Tools"
    ↓
Check "Android SDK Build-Tools 35"
    ↓
Click "Apply" → Wait → Done!
```

---

## ⚠️ Troubleshooting

### Can't find SDK Manager?
- Make sure Android Studio is fully open (not just the welcome screen)
- Try: File → Settings → Appearance & Behavior → System Settings → Android SDK

### Build-Tools 35 not showing?
- Make sure you're on the **"SDK Tools" tab**, not "SDK Platforms"
- Try checking "Show Package Details" to see all versions

### Installation stuck?
- Check your internet connection
- Try closing and reopening Android Studio
- Make sure you have enough disk space

---

## 📝 Quick Checklist

- [ ] Android Studio is open
- [ ] SDK Manager is open (Tools → SDK Manager)
- [ ] "SDK Tools" tab is selected
- [ ] "Android SDK Build-Tools 35" is checked
- [ ] "Apply" button is clicked
- [ ] Installation completed
- [ ] Ready to run `flutter run`!

---

**That's it! Follow these steps and you'll have Build-Tools 35 installed.** 🚀

