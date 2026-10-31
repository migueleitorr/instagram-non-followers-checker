# Instagram Non-Followers & Live Account Verifier

A **100% private, zero-login** tool to find who doesn't follow you back on Instagram—and automatically filter out deactivated, renamed, or banned (`404`) accounts so you only see real, active profiles.

---

## 🌐 How to Open the Live Web Version

You can use the application directly inside your browser on any phone, tablet, or computer without installing anything:

* 📱 **On Mobile Devices (iPhone / Android):**  
  Look at the **very top of this GitHub page** (right below the project title). The live website link is displayed at the top of the interface. Simply tap that link to open the app directly in Safari, Chrome, or your default browser.
* 💻 **On Desktop Computers (PC / Mac):**  
  Look at the **top-right sidebar** of this page. Under the **"About"** section, click the website link next to the 🌐 icon (or under **Deployments → github-pages**).

---

## ⚠️ MANDATORY PREREQUISITE: Export Your Instagram Data

> ### 🛑 READ THIS BEFORE USING THE APP
> This tool **DOES NOT ASK FOR YOUR INSTAGRAM USERNAME OR PASSWORD** and never connects to your personal account. Because of this zero-login privacy architecture, **the app cannot inspect your account without your official Instagram data export file**.
> 
> **You MUST download your Instagram export ZIP file first.** Without this file, the application has no data to analyze and will not work.

Follow these simple, step-by-step instructions to request your official data export directly from Instagram (takes about 2 minutes to request):

### Step-by-Step Export Guide:

1. **Open Instagram** on your phone or computer.
2. Go to your **Profile** (tap your picture in the bottom right corner).
3. Tap the **Menu icon (☰ three horizontal lines)** in the top right $\rightarrow$ tap **Meta Account** (Accounts Center).
4. Under *Meta Account*, select **Your information and permissions**.
5. Tap **Export your information** (or *Download your information*).
6. Select **Create export**.
7. Choose your Instagram profile.
8. Choose where to export: select **Export to device**.
9. In the **Customize information** tab, check the box for **Connections** (which includes contacts, followers, and following). Deselect the rest of the categories, as they are not necessary.
10. **Change the format to JSON (CRITICAL):**
    * **Format:** Select **JSON** *(⚠️ MANDATORY: Do NOT select HTML. The app can only read JSON data)*.
    * **Date range:** Ensure it is set to **All time** *(to check everyone you have ever followed)*.
11. Then hit **Start export**.
12. **Download the file:** You will receive an email confirming the export task was initiated, and a second email once it is ready. Once completed, open the link or return to Instagram and download the `.zip` file to your device.

> **💡 Do you need to unzip it?**  
> * **On Desktop (or modern mobile browsers):** You do NOT need to extract the ZIP! You can drag and drop (or select) the raw `.zip` file directly into the app.  
> * **Alternative for mobile:** If your mobile browser only allows selecting individual files, extract the ZIP and simply select `following.json` and `followers_1.json`.

---

## 🚀 Two Ways to Use the Application

### Option 1: Instant Web Version (No Installation Required)
* Open the live web link (see the guide at the top of this document).
* Drop or select your Instagram `.zip` export (or select `following.json` and `followers_1.json`).
* Immediately see everyone who does not follow you back.
* **Sort your list:** Sort chronologically by **Follow Date** (Oldest First / Newest First) or **Alphabetically (A–Z)**.
* **Mark progress:** Use the **Mark Done ✓** button to keep track of accounts you've unfollowed.
* **Manual 404 Tagging:** Because web browsers have security restrictions (CORS) preventing external websites from silently checking Instagram links, you can tag dead/unavailable profiles manually using the **🚫 Dead** button.

---

### Option 2: Desktop Auto-Verifier (Windows & Mac — Recommended)
Want the app to **automatically detect and hide all dead/404 accounts** and **rank non-followers by their follower count**?

1. Download the app folder by clicking the green **`<> Code`** button at the top of this repository $\rightarrow$ **Download ZIP** (or download the packaged ZIP from **Releases**).
2. **Extract** the downloaded `.zip` file to a folder on your computer.
3. Launch the app:
   * **On Windows:** Double-click **`start_app.bat`**.
   * **On Mac:** Double-click **`start_app.command`** (or right-click $\rightarrow$ **Open** the first time).
4. Drop your Instagram export `.zip` into the application window.
5. The local engine will automatically verify every profile over public HTTP (zero login required), fetch live follower counts (e.g. `1.5K`, `50K`), separate active accounts from dead/404 profiles, and let you sort by **Followers: Most to Fewest**.

---

## 🔒 Shared Computer & Privacy Controls

If you are using a public or shared computer and want to ensure nobody else sees your follower lists or account details:
* Click **🗑️ Delete Session** in the top action bar (or **🗑️ Delete Saved Session** on the home screen).
* A confirmation prompt (*"Are you sure...?"*) will ask you to confirm before deleting.
* Confirming immediately wipes all stored lists, review progress (`Done` / `Dead`), follower counts, and account session markers from the browser's local cache.

---

## ⚠️ Safe Unfollowing Pacing Guide

To keep your Instagram account 100% safe from temporary action blocks or rate limits (*"Action blocked"* or *"Try again later"*):
* Unfollow a maximum of **20 – 30 accounts per session**.
* Wait **15 – 30 seconds** between unfollow clicks in your Instagram tabs.
* Your progress (**Done ✓**) is automatically saved in your browser per account, so you can close the window and resume tomorrow right where you left off.

---

## 🛡️ Why Is This Tool 100% Safe?

1. **Zero Login / Zero Passwords:** Mobile apps and browser extensions that ask for your Instagram password or cookies violate Meta's terms and cause immediate account bans. This tool **never asks for credentials** and never touches your active session.
2. **100% Local Processing:** Your data files are processed solely inside your device's memory. No usernames, follower lists, or personal details are ever sent to an external server.
3. **100% Auditable Plain-Text Code:** Every file in this project (`index.html`, `start_app.bat`, `app_engine.ps1`, `start_app.command`, `app_mac.py`) is written in human-readable plain text. You can open any file in **Notepad** or **TextEdit** to verify every line of code yourself.

---

### Why Does Windows Defender Show a Warning for `start_app.bat`?
When opening `.bat` or `.ps1` scripts downloaded from the internet, Windows Defender displays a standard prompt (**"Windows protected your PC"** or **"Open File - Security Warning"**).
* **Why this happens:** Microsoft requires developers to purchase an expensive commercial Code Signing Certificate ($300–$500/year) to remove that prompt. Because this is a free, non-commercial open-source project, Windows displays a default warning.
* **How to verify it yourself:** Right-click `start_app.bat` or `app_engine.ps1` $\rightarrow$ click **Edit in Notepad**. You can see that it only starts a local localhost web server (`127.0.0.1:8765`) and uses Windows' built-in `curl.exe` to check public profile availability. It writes zero files to your disk and requires zero administrator privileges.

---

## 📄 License
MIT License — Free to use, inspect, and modify.
