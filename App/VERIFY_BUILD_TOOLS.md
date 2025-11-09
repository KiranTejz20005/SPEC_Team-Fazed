# Verify Build-Tools 35 is Installed

## 🔍 Check Which Version is Installed

### Step 1: Check Package Details

1. **Look at the bottom of the window**
2. **Find the checkbox:** "Show Package Details"
3. **Check this box** (put a checkmark in it)
4. **This will expand** the "Android SDK Build-Tools" entry to show all versions

### Step 2: Verify Build-Tools 35

After checking "Show Package Details", you'll see:
- Android SDK Build-Tools
  - 34.0.0 (might be installed)
  - **35.0.0** ← **Make sure this is checked!**
  - 36.0.0 (if available)

### Step 3: If Build-Tools 35 is NOT Checked

1. **Check the box** next to **"35.0.0"**
2. **Click "Apply"** button (bottom right)
3. **Wait for installation** (2-5 minutes)
4. **Click "OK"** when done

### Step 4: If Build-Tools 35 IS Already Checked

1. **Click "OK"** to close the window
2. **Try running your app again!**

---

## ✅ After Verifying

Once Build-Tools 35 is confirmed installed:

1. **Click "OK"** to close SDK Manager
2. **Go back to your terminal**
3. **Run:**
   ```bash
   flutter run -d 00195658T001904
   ```

---

## 🎯 Quick Checklist

- [ ] Checked "Show Package Details"
- [ ] Verified "Android SDK Build-Tools 35.0.0" is checked
- [ ] Clicked "Apply" if needed to install 35.0.0
- [ ] Clicked "OK" to close SDK Manager
- [ ] Ready to run the app!

---

**Check "Show Package Details" first to see which version is actually installed!** 🔍

