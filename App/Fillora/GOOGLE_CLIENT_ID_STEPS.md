# Step-by-Step: Get Google Client ID from Google Cloud Console

## 🎯 You're Currently At: Google Cloud Console Welcome Page

Follow these exact steps to get your Client ID:

---

## Step 1: Open the Navigation Menu

1. Look at the **top-left corner** of the page
2. Click the **hamburger menu icon** (☰) - three horizontal lines
3. This will open the left sidebar navigation menu

---

## Step 2: Navigate to APIs & Services

1. In the left sidebar menu, scroll down to find **"APIs & Services"**
2. Click on **"APIs & Services"** to expand it
3. You'll see a submenu with options like:
   - Library
   - Dashboard
   - Credentials
   - OAuth consent screen
   - etc.

---

## Step 3: Configure OAuth Consent Screen (First Time Only)

**⚠️ IMPORTANT:** You must do this BEFORE creating credentials!

1. Still in the **"APIs & Services"** menu, click on **"OAuth consent screen"**
2. You'll see a form. Fill it out:

   **User Type:**
   - Select **"External"** (unless you have Google Workspace)
   - Click **"CREATE"**

   **App Information:**
   - **App name:** `Fillora` or `Fillora.in`
   - **User support email:** Select your email from dropdown
   - **App logo:** (Optional - skip for now)
   - **App domain:** (Optional - skip for now)
   - **Developer contact information:** Enter your email
   - Click **"SAVE AND CONTINUE"**

   **Scopes:**
   - Click **"ADD OR REMOVE SCOPES"**
   - Check these scopes:
     - ✅ `.../auth/userinfo.email`
     - ✅ `.../auth/userinfo.profile`
     - ✅ `openid`
   - Click **"UPDATE"**
   - Click **"SAVE AND CONTINUE"**

   **Test Users (if app is in Testing mode):**
   - Click **"ADD USERS"**
   - Add your email address (and any test users)
   - Click **"ADD"**
   - Click **"SAVE AND CONTINUE"**

   **Summary:**
   - Review everything
   - Click **"BACK TO DASHBOARD"**

---

## Step 4: Go to Credentials Page

1. In the left sidebar, under **"APIs & Services"**, click on **"Credentials"**
2. You'll see a page showing all your API credentials

---

## Step 5: Create OAuth Client ID

1. At the **top of the page**, click the **"+ CREATE CREDENTIALS"** button
2. A dropdown menu will appear
3. Click on **"OAuth client ID"**

---

## Step 6: Configure OAuth Client ID

You'll see a form to configure your OAuth client:

### For Web Application (Do This First):

1. **Application type:**
   - Select **"Web application"** from the dropdown

2. **Name:**
   - Enter: `Fillora Web Client` (or any name you prefer)

3. **Authorized JavaScript origins:**
   - Click **"+ ADD URI"**
   - Add these URIs (one at a time):
     - `http://localhost:3000`
     - `http://localhost:8080`
     - `http://localhost` (if you're using default port)
     - `https://yourdomain.com` (replace with your actual domain if you have one)
   - Click **"+ ADD URI"** for each one

4. **Authorized redirect URIs:**
   - Click **"+ ADD URI"**
   - Add these URIs:
     - `http://localhost:3000`
     - `http://localhost:8080`
     - `http://localhost`
     - `https://yourdomain.com` (replace with your actual domain)
   - Click **"+ ADD URI"** for each one

5. Click **"CREATE"**

6. **Copy Your Client ID:**
   - A popup will appear showing:
     - **Client ID:** (a long string like `123456789-abcdefghijklmnop.apps.googleusercontent.com`)
     - **Client secret:** (you can ignore this for now)
   - **Click the copy icon** next to the Client ID to copy it
   - **Save this somewhere safe!** You'll need it for your code
   - Click **"OK"**

### For Android (If Using Flutter Android):

1. Click **"+ CREATE CREDENTIALS"** again
2. Select **"OAuth client ID"**
3. **Application type:** Select **"Android"**
4. **Name:** `Fillora Android Client`
5. **Package name:** `com.fillora.app` (or your actual package name)
6. **SHA-1 certificate fingerprint:**
   - To get this, run in terminal:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   - Copy the SHA-1 fingerprint (looks like: `AA:BB:CC:DD:EE:FF:...`)
   - Paste it in the field
7. Click **"CREATE"**
8. Copy the Client ID (save it separately - different from web)

### For iOS (If Using Flutter iOS):

1. Click **"+ CREATE CREDENTIALS"** again
2. Select **"OAuth client ID"**
3. **Application type:** Select **"iOS"**
4. **Name:** `Fillora iOS Client`
5. **Bundle ID:** `com.fillora.app` (or your actual bundle ID)
6. Click **"CREATE"**
7. Copy the Client ID (save it separately - different from web)

---

## Step 7: Enable Google Sign-In API (If Not Already Enabled)

1. In the left sidebar, under **"APIs & Services"**, click on **"Library"**
2. In the search bar, type: **"Google Sign-In API"**
3. Click on **"Google Sign-In API"** from results
4. Click the **"ENABLE"** button (if not already enabled)
5. Wait for it to enable (takes a few seconds)

---

## ✅ What You Should Have Now

You should have copied:
- ✅ **Web Client ID** (for web version)
- ✅ **Android Client ID** (for Android app - optional)
- ✅ **iOS Client ID** (for iOS app - optional)

Each Client ID looks like:
```
123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com
```

---

## 📝 Next Steps: Use Your Client ID

### For Web Version:

**File: `signin.html`** (Line 110)
```html
<div id="g_id_onload" 
     data-client_id="PASTE_YOUR_WEB_CLIENT_ID_HERE" 
     data-callback="handleGoogleSignIn">
</div>
```

**File: `auth.js`** (Lines 181 and 269)
```javascript
client_id: 'PASTE_YOUR_WEB_CLIENT_ID_HERE',
```

### For Flutter:

The Flutter app will automatically use the credentials you configured. Just make sure:
- Android: You added the SHA-1 fingerprint and created Android OAuth client
- iOS: You created iOS OAuth client and updated Info.plist

---

## 🎯 Quick Reference

**Where to find your Client IDs later:**
- Go to: **APIs & Services** → **Credentials**
- You'll see all your OAuth 2.0 Client IDs listed
- Click on any one to see/edit it

---

## ⚠️ Important Notes

1. **Keep your Client IDs secure** - Don't share them publicly
2. **Web Client ID** is different from **Android Client ID** and **iOS Client ID**
3. You need **at least the Web Client ID** for the web version to work
4. For Flutter, you can use the Web Client ID for web builds, but you'll need platform-specific IDs for Android/iOS builds

---

## 🆘 Troubleshooting

**Can't find "APIs & Services"?**
- Make sure you're in the correct project (check top bar - should show "My First Project")
- The hamburger menu (☰) should be in the top-left

**"OAuth client ID" option is grayed out?**
- You need to configure the OAuth consent screen first (Step 3)

**Getting errors when signing in?**
- Make sure you added the correct redirect URIs
- Check that the Google Sign-In API is enabled
- Verify your Client ID is correct (no extra spaces)

---

**That's it!** You now have your Google Client ID. Next, get your Facebook App ID from Facebook Developers.

