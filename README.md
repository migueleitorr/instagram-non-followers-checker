# Instagram Non-Followers & Live Account Verifier

> 🌐 **Live Web Version:** Click the website link in the **About** section (top-right sidebar of this repository) to open the app directly in your browser without downloading anything!

A **100% private, zero-login** tool to find who doesn't follow you back on Instagram—and automatically filter out deactivated, renamed, or banned (`404`) accounts so you only see real, active profiles.

---

## 🔒 Why Is This Tool Safer Than Other Unfollower Apps?

1. **Zero Login / Zero Passwords:** Most mobile apps and Chrome extensions ask for your Instagram login or session cookies. Meta detects third-party logins and bans accounts immediately. This tool **never connects to your Instagram account**—it reads your official Meta data export `.zip` file locally.
2. **100% Local Processing:** Your `.zip` file is read directly inside your browser's memory. No follower lists, usernames, or personal data are ever uploaded to an external server.
3. **100% Auditable Plain-Text Code:** Unlike compiled `.exe` programs that hide their code inside a binary black box, every file in this repository (`index.html`, `start_app.bat`, `app_engine.ps1`) is **plain text**. You can right-click any file and open it in **Notepad** to inspect every single line before running it.

---

## 🚀 Two Ways to Use It

### Option 1: Instant Web Version (No Download Required)
Use the hosted **GitHub Pages** version right in your browser:
* Drop your Instagram `.zip` export onto the page to immediately see who doesn't follow you back.
* *(Note: Due to web browser CORS security rules, the web-only version cannot automatically ping Instagram to check which accounts are deactivated/404, so you can mark dead links manually with the **🚫 Dead** button).*

### Option 2: Desktop Auto-Verifier (`start_app.bat` — Recommended)
Want the app to **automatically detect and hide all dead/404 accounts** before you start unfollowing?
1. Click the green **`<> Code`** button at the top of this page and select **Download ZIP** (or download the latest release from **Releases**).
2. **Extract** the `.zip` folder on your computer.
3. Double-click **`start_app.bat`**.
4. Drop your Instagram export `.zip` into the app window. It will automatically verify every profile over public HTTP (zero login required) and separate active accounts from dead/404 accounts.

---

## 🛡️ Why Does Windows Ask Permission When Opening `start_app.bat`?

When you download any script (`.bat` or `.ps1`) from the internet, Windows Defender displays a prompt asking if you want to allow it to run (**"Windows protected your PC"** or **"Open File - Security Warning"**).

* **Why this happens:** Microsoft requires developers to purchase a commercial Code Signing Certificate ($300–$500/year) to remove that prompt. Because this is a free, open-source project, Windows treats it as an "unrecognized publisher."
* **How to verify it's 100% safe yourself:**
  1. Right-click **`start_app.bat`** and **`app_engine.ps1`** $
ightarrow$ click **Edit in Notepad**.
  2. You can verify in seconds that `start_app.bat` only starts a local localhost page (`127.0.0.1:8765`) and `app_engine.ps1` only checks public `https://www.instagram.com/<username>/` links using Windows' built-in `curl.exe`.
  3. It creates zero files in your personal folders and requires zero administrator privileges.

---

## 📥 How to Export Your Instagram Follower Data (Official Meta Method)

1. Open **Instagram** $
ightarrow$ **Settings & Privacy** $
ightarrow$ **Accounts Center**.
2. Go to **Your information and permissions** $
ightarrow$ **Download your information**.
3. Click **Download or transfer information** $
ightarrow$ Select your Instagram account.
4. Select **Some of your information** $
ightarrow$ Check **Followers and following**.
5. Choose **Download to device** and set:
   * **Format:** `JSON` *(Important: choose JSON, not HTML)*
   * **Date range:** `All time`
6. Submit the request. Once Meta emails your download link (usually 5–15 minutes), download the `.zip` file and drop it directly into this app—you don't even need to unzip it!

---

## ⚠️ Safe Unfollowing Pacing Guide
To avoid temporary Instagram rate-limit warnings (*"Try again later"*):
* Unfollow a maximum of **20 – 30 accounts per session**.
* Wait **15 – 30 seconds** between unfollows.
* Your progress (**Done ✓**) is automatically saved in your browser per Instagram account, so you can close the window and continue tomorrow right where you left off.

---

## 📄 License
MIT License — Free to use, inspect, and modify.
