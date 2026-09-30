# CricketMate 🏏 — Mobile Installation & Comprehensive Testing Guide

Welcome to the hands-on testing guide for **CricketMate**. This document explains in plain language how to get the application onto your personal Android phone and provides a step-by-step checklist to test every feature.

---

## Part 1: How to Install on Your Mobile Phone

The application is already compiled as an Android APK on your machine. You do not need to install complex developer tools on your phone to run it.

### APK File Location on Your Computer
```text
C:\Users\rohit\Desktop\majhe-test\cricket_mate\build\app\outputs\flutter-apk\app-debug.apk
```

---

### Option A: Send the APK File Directly (Easiest — No USB Cable Needed)

1. **Send the File to Your Phone**:
   - **WhatsApp Web / Telegram**: Drag and drop `app-debug.apk` into a chat with yourself or a private group.
   - **Google Drive / Dropbox**: Upload `app-debug.apk` to Google Drive and download it from the Drive app on your phone.
   - **Email**: Attach the APK and email it to yourself.
2. **Install on Your Phone**:
   - Tap the downloaded `app-debug.apk` file on your phone.
   - If prompted: **"For your security, your phone is not allowed to install unknown apps from this source"**, tap **Settings** $\to$ toggle **Allow from this source** (or "Install Unknown Apps").
   - Tap **Install** and then **Open**.

---

### Option B: Install via USB Cable (If You Have Developer Options Enabled)

If you connect your Android phone to your PC via a USB cable:
1. Ensure **USB Debugging** is turned on in your phone's *Settings $\to$ Developer options*.
2. Open PowerShell in the project directory and run:
   ```powershell
   flutter devices
   ```
   *(Find your phone's device identifier)*
3. Install and run directly:
   ```powershell
   flutter run -d <your-phone-device-id>
   ```
   Or install the built APK with ADB:
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

---

## Part 2: Feature Tour — What the App Does

CricketMate is designed to answer one question: *"When should our group play cricket today?"*

1. **Intelligent Session Recommendation Engine**:
   - Sweeps 30-minute time intervals across the day.
   - Evaluates rain risk, temperature comfort (optimal 20–28°C), wind speed, humidity, and UV index.
   - Evaluates cricket-specific ground conditions:
     - **Evening Dew Risk**: Measures the gap between temperature and dew point; when the gap narrows, dew makes the ball slick and impossible to bowl or grip.
     - **Wet Outfield Penalty**: Detects rain from the prior 12–24 hours (`past_days=1`) that leaves waterlogged turf.
     - **Ball-Type Daylight Rules**: Leather balls require 100% daylight for player safety. Tennis and box cricket are twilight-tolerant.
   - Automatically **vetoes** unplayable slots (capping score at 30 for thunderstorms, $>70\%$ rain probability, or missing quorum).

2. **Squad & Player Availability**:
   - Add/remove players with input validation (no duplicates, trimmed names).
   - 30-minute range picker for **Today** and **Tomorrow**.
   - One-tap quick presets: *"Evening 5–8 PM"*, *"Weekend Morning 7–10 AM"*.
   - Live **Overlap Preview Card** at the top showing the best window for the selected day.
   - Delete player with **Undo Snackbar**.

3. **Sessions Home Screen**:
   - **Hero "Best Time to Play" Card**: Shows top score (0–100), time window, weather summary, player count, and positive checkmark reasons.
   - **Filter Chips**: Filter by Ball Type (Tennis, Leather, Box), Duration (60m–180m), Min Players, and Min Score.
   - **Sort Options**: Sort by Session Score, Start Time, or Player Attendance.
   - **Ranked Candidates List**: Displays alternative time slots with ratings.
   - **Offline Badge**: Shows `"Offline • Updated X ago"` when viewing cached weather.
   - **Pull to Refresh**: Refreshes both weather and player roster.

4. **Session Detail Screen**:
   - Hero card animation transition.
   - **Score Breakdown Bars**: Labeled visual breakdown for Weather, Squad Availability, and Ground Conditions.
   - **Reason Chips**: Highlight why a session is great or vetoed (e.g., *"Comfortable 24°C"*, *"Dry Outfield"*, *"Missing Quorum"*).
   - **Who is In / Who is Missing**: Instant breakdown of available vs unavailable squad members.
   - **Hourly Conditions Graph**: Custom-painted visual strip showing rain probability bars, temperature curve, and sunset line.
   - **WhatsApp Match Invite**: Formats a WhatsApp-friendly match invite and opens the native system share sheet.

5. **Settings & Customization**:
   - Ball type, default duration, and squad quorum preferences (persisted locally).
   - **Theme Selector**: System, Light, and Dark mode (cricket-green seed palette with WCAG AA $\ge 4.5:1$ contrast).
   - **Language Toggle**: Instant switch between **English** and **Hindi (हिन्दी)** covering all screens, dialogs, reasons, and plurals.
   - **Open-Meteo Attribution**: CC BY 4.0 data attribution.

---

## Part 3: Step-by-Step Hands-On Testing Script

Follow these 12 guided steps on your phone to test the entire application from start to finish:

```
[Step 1] Initial Launch & Empty State
   │
   ▼
[Step 2] Search a Venue / City (e.g., Mumbai, Bengaluru, London)
   │
   ▼
[Step 3] Add Squad Members in Players Tab
   │
   ▼
[Step 4] Set Availability with Quick Presets & Sliders
   │
   ▼
[Step 5] Observe Live Overlap Preview
   │
   ▼
[Step 6] View the Hero "Best Time to Play" Card
   │
   ▼
[Step 7] Test Ball Type & Duration Filters
   │
   ▼
[Step 8] Open Session Detail & Examine Hourly Graph
   │
   ▼
[Step 9] Share WhatsApp Match Invite
   │
   ▼
[Step 10] Switch Language to Hindi (हिन्दी) & Dark Mode
   │
   ▼
[Step 11] Test Offline Caching (Airplane Mode)
   │
   ▼
[Step 12] Test Player Deletion & Undo
```

---

### Step 1: Initial Launch & Empty State
- Open the app.
- Notice the clean cricket-green Material 3 interface and the bottom navigation bar with 3 tabs: **Sessions**, **Players**, **Settings**.
- On the **Sessions** tab, you will see a friendly empty state prompting you to add players to find a session.
- Tap **Add Squad Members**. The app automatically navigates you to the **Players** tab.

---

### Step 2: Search a Cricket Venue / City
- Look at the top App Bar on the Sessions tab.
- Tap the location search bar (magnifying glass).
- Type a cricket city or ground (e.g., `Mumbai`, `London`, `Bengaluru`, `Sydney`, `Delhi`).
- Notice the **400ms debounce** (it smoothly waits until you stop typing before querying Open-Meteo).
- Tap a search result (e.g., `Mumbai, India`).
- The app instantly fetches Open-Meteo hourly weather, caches it in `SharedPreferences`, and saves Mumbai as your default venue.

---

### Step 3: Add Squad Members
- Switch to the **Players** tab (center icon on bottom bar).
- Tap the **(+) Add Player** button (or the top-right icon).
- Add 6 to 8 friends (e.g., *Rohit*, *Virat*, *Jasprit*, *Hardik*, *Surya*, *Shubman*, *Axar*).
- **Edge-case check**: Try typing a duplicate name or an empty name. Notice the inline error message preventing invalid entries.

---

### Step 4: Set Player Availability
- Tap on any player's card (e.g., *Rohit*). A bottom sheet modal opens.
- Notice the **Day Selector** at the top (**Today** vs **Tomorrow**).
- **Try Quick Presets**: Tap **Evening 5–8 PM**. The sliders automatically set to 17:00 – 20:00!
- Tap **Save Availability**.
- Now open another player (e.g., *Virat*) and drag the 30-minute sliders manually to `17:30` – `19:30`.
- Set 5 or 6 players to have overlapping availability in the late afternoon / evening (e.g. 5:00 PM – 8:00 PM).

---

### Step 5: Check Live Overlap Preview
- Look at the **top card** on the Players tab (*Overlap Preview*).
- Notice how it automatically recalculated:
  > *"Best Overlap: 5:30 PM – 7:30 PM (6/6 Players Available)"*
- Tap the **Tomorrow** pill on that card to see availability change for tomorrow.

---

### Step 6: Review Ranked Sessions & Hero Card
- Tap the **Sessions** tab.
- The **"BEST TIME TO PLAY"** Hero card now appears at the top!
  - **Score Ring**: Large circular score (e.g., `85`, labeled `EXCELLENT` or `GREAT`).
  - **Match Window**: E.g., `5:30 PM – 7:30 PM`.
  - **Weather Metrics**: Temperature (e.g. `27°C`), rain probability (e.g. `10%`), wind speed.
  - **Positive Reasons**: Checkmarks like `Optimal temperature`, `No rain expected`, `Good squad turnout`.
- Scroll down to view the **Other Candidate Windows** ranked in order.

---

### Step 7: Test Filter Chips & Ball Types
- On the Sessions tab, tap the filter bar chips:
  - **Ball Type**:
    - Select **Leather Ball**: Watch evening/night slots drop in score or trigger daylight vetoes (hard leather balls require sunlight).
    - Select **Tennis Ball** or **Box Cricket**: Notice evening slots rebound because tennis balls are twilight/floodlight tolerant!
  - **Duration**: Switch between `60m`, `90m`, and `120m` to see candidate windows adapt.
  - **Sort Menu**: Tap Sort $\to$ change to **Time** (earliest first) or **Attendance** (most players first).

---

### Step 8: Open Session Details Screen
- On the Hero card, tap **View Session**.
- Experience the smooth **Hero transition** animation.
- Notice the details screen layout:
  1. **Score Breakdown**:
     - *Weather Score* (60% weight).
     - *Availability Score* (30% weight).
     - *Pitch & Conditions* (10% weight).
  2. **Reason Chips**: Highlighted badges explaining the algorithm's decisions.
  3. **Players Section**:
     - Green chips for **Who is In** (available).
     - Grey/muted chips for **Who is Missing** (unavailable).
  4. **Hourly Conditions Strip**:
     - Drawn with a custom painter.
     - Blue vertical bars for rain probability.
     - Connected line for temperature trend.
     - Vertical dashed line indicating **Sunset** time!

---

### Step 9: Test WhatsApp Match Invite Sharing
- At the bottom of the Session Detail screen, tap the **Share Invite** button.
- The native Android system share sheet pops up.
- Select **WhatsApp**, **Telegram**, or **Messages**.
- Notice the formatted message ready to send:
  ```text
  🏏 CRICKET SESSION INVITE 🏏
  📍 Mumbai
  📅 Wednesday, 30 Sep
  ⏰ 5:30 PM - 7:30 PM (2h)
  ⭐ Session Score: 85/100 (EXCELLENT)

  🌤 Conditions:
  • 26°C (Comfortable)
  • Rain Risk: 5% (0.0mm)
  • Wind: 14 km/h

  👥 Squad (6 confirmed):
  ✅ Rohit, Virat, Jasprit, Hardik, Surya, Shubman

  Sent via CricketMate 🏏
  ```

---

### Step 10: Test Language Toggle (Hindi) & Dark Mode
- Tap the **Settings** tab.
- **Switch Language**:
  - Tap **हिन्दी**.
  - Notice the **entire application** immediately translates into Hindi (Navigation tabs: *सत्र*, *खिलाड़ी*, *सेटिंग्स*; score ratings: *उत्कृष्ट*, *बहुत अच्छा*; reason badges and dialogs).
  - Switch back to **English** (or keep Hindi if you prefer!).
- **Switch Theme**:
  - Tap **Dark** mode.
  - Notice the deep dark cricket-green aesthetic, crisp white text, and high contrast.
  - Tap **System** or **Light** to switch back.
- **Squad Quorum**:
  - Tap **(+)** or **(-)** on Squad Quorum.
  - Notice the accessible 48dp buttons and live plural description.

---

### Step 11: Test Offline Caching (Airplane Mode)
- While the app is open with weather loaded, turn on **Airplane Mode** on your phone (disconnect Wi-Fi and mobile data).
- Close and reopen the app, or swipe down to **Pull-to-refresh**.
- **Result**:
  - The app does not crash or show a blank screen.
  - It loads the stored forecast from `SharedPreferences`.
  - An amber badge appears: **"Offline • Updated 2m ago"** with an offline cloud icon.
  - All scoring and recommendations remain fully functional!
- Turn Airplane mode back off.

---

### Step 12: Test Player Deletion & Undo
- Go to the **Players** tab.
- Tap the **Trash** icon next to any player.
- The player disappears, and a Snackbar appears: *"Player removed — UNDO"*.
- Tap **UNDO**.
- The player and their availability are restored immediately.

---

## Part 4: Frequently Asked Questions & Troubleshooting

### Q: Why does Android say "App not installed" or "Blocked by Play Protect"?
**A**: Because this is a development debug build signed with a standard debug key rather than a Google Play Store certificate:
1. Tap **More details** on the Play Protect pop-up.
2. Tap **Install anyway**.

### Q: Does CricketMate track my GPS location?
**A**: No. CricketMate deliberately avoids tracking background GPS to protect player privacy and battery life. It uses Open-Meteo's geocoding search so you can search any city, local ground, or turf in the world.

### Q: How do I test the Thunderstorm / Veto feature?
**A**: Search for a city currently experiencing bad weather (e.g. during monsoon season, search a city with active rain), or reduce the squad size below your configured quorum in Settings. You will see the score capped at 30 and an alert badge reading *"Session Viability Veto Triggered"*.

---

*Enjoy testing CricketMate on your phone! 🏏*
