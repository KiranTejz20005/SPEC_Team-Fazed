# Where to Find SHA-1 Fingerprint Field in Google Cloud Console

## 🔍 You're Currently on the Wrong Page!

**You're on the "Web application" page** - SHA-1 fingerprint field doesn't appear here!

---

## ✅ Solution: Select "Android" Application Type

### Step 1: Change Application Type

1. Look at the top of the form where it says **"Application type"**
2. Click the dropdown that currently shows **"Web application"**
3. Select **"Android"** from the dropdown

### Step 2: SHA-1 Field Will Appear

Once you select **"Android"**, the form will change and you'll see:
- **Package name** field
- **SHA-1 certificate fingerprint** field ← **This is what you need!**

---

## 📋 Complete Steps to Create Android Client ID

### If you're creating a new one:

1. **Go to Credentials page:**
   - Click hamburger menu (☰) → **APIs & Services** → **Credentials**

2. **Click "+ CREATE CREDENTIALS"**
   - Select **"OAuth client ID"**

3. **Select Application Type:**
   - Click the dropdown
   - Select **"Android"** (NOT "Web application")

4. **Fill in the form:**
   - **Name:** `Fillora Android Client`
   - **Package name:** `com.fillora.app`
   - **SHA-1 certificate fingerprint:** Paste this:
     ```
     28:70:EA:81:48:9A:76:47:72:B2:58:75:CD:60:2D:86:5D:C3:8B:81
     ```

5. **Click "CREATE"**

---

## 🎯 Your SHA-1 Fingerprint (Copy This)

```
28:70:EA:81:48:9A:76:47:72:B2:58:75:CD:60:2D:86:5D:C3:8B:81
```

---

## 📝 What Each Application Type Shows

| Application Type | Fields Shown |
|-----------------|--------------|
| **Web application** | JavaScript origins, Redirect URIs |
| **Android** | Package name, **SHA-1 fingerprint** ← You need this! |
| **iOS** | Bundle ID |
| **Desktop app** | Custom URI scheme |

---

## ✅ Summary

1. **Change "Application type" to "Android"**
2. **SHA-1 field will appear**
3. **Paste:** `28:70:EA:81:48:9A:76:47:72:B2:58:75:CD:60:2D:86:5D:C3:8B:81`
4. **Fill package name:** `com.fillora.app`
5. **Click CREATE**

---

**The SHA-1 field only appears when you select "Android" as the application type!** 🔑

