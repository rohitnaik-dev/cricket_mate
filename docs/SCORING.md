# CricketMate Session Scoring Formula & Architectural Rationale

This document details the mathematical models, weighting rationale, sub-score calibrations, and hard veto constraints implemented in `CricketMate`'s pure Dart session scoring engine (`lib/features/sessions/domain/`).

---

## 1. Overall Session Score

$$\text{Session Score} = 0.60 \cdot \text{WeatherScore} + 0.30 \cdot \text{AvailabilityScore} + 0.10 \cdot \text{ConditionsScore}$$

### Why this 60 / 30 / 10 weighting?

| Component | Weight | Rationale |
| :--- | :---: | :--- |
| **Weather** | **60%** | Weather is the primary existential hazard for cricket. Rain immediately halts play; extreme cold, excessive heat, or gale-force winds make bowling and batting virtually impossible and physically uncomfortable. Even with 22 players present, if it pours, no cricket can happen. |
| **Player Availability** | **30%** | Cricket is fundamentally a team sport requiring two sides. A sunny afternoon without sufficient players (quorum) is futile. It carries the second largest weight to prioritize windows where the squad can field complete, competitive teams. |
| **Ground & Ambient Conditions** | **10%** | Wet turf from overnight rain, evening dew on the grass, or diminishing natural light are crucial secondary variables that turn an apparently dry day into a slippery, hazardous match or ruin the match ball. |

---

## 2. Weather Sub-Scores & Weights (`WeatherScorer`)

Every hour within a session window is evaluated across 5 meteorological dimensions:

$$\text{WeatherScore} = 0.40 \cdot \text{Rain} + 0.25 \cdot \text{Temperature} + 0.15 \cdot \text{Wind} + 0.10 \cdot \text{Humidity} + 0.10 \cdot \text{UV}$$

### Dimension Weight Breakdown:

1. **Rain ($40\%$)**:
   - **Formula**: $\max(0, 100 - P) \times \max\left(0, 1 - \frac{\text{precipitation}}{2.0\text{ mm}}\right)$
   - **Rationale**: Rain is cricket's #1 disrupter. Unlike football, cricket cannot be played on wet wickets due to safety and ball damage. High probability ($> 70\%$) also triggers an immediate hard veto.

2. **Temperature Comfort ($25\%$)**:
   - **Formula**: Uses apparent ("feels-like") temperature.
     - **Optimal zone ($20^\circ\text{C} - 28^\circ\text{C}$)**: $100.0$
     - **Below $20^\circ\text{C}$**: Linear deduction ($100 - (20 - T) \times 5.0$). At $10^\circ\text{C} \rightarrow 50$, $< 0^\circ\text{C} \rightarrow 0$.
     - **Above $28^\circ\text{C}$**: Linear deduction ($100 - (T - 28) \times 6.0$). At $38^\circ\text{C} \rightarrow 40$, $> 44^\circ\text{C} \rightarrow 0$.
   - **Rationale**: Cricket sessions last $1.5$ to $4$ hours. Extreme temperatures induce either stiff joints and numbed fingers or rapid dehydration and heat exhaustion.

3. **Wind ($15\%$)**:
   - **Formula**: Effective wind $= 0.70 \times \text{sustained} + 0.30 \times \text{gusts}$. Adjusted by `BallType.windToleranceFactor`.
     - $\le 15\text{ km/h} \rightarrow 100.0$.
     - $\ge 55\text{ km/h} \rightarrow 0.0$.
   - **Rationale**: High winds alter ball trajectory in the air, dislodge bails from stumps, blow away hats, and make high catching dangerous. Tennis balls are heavily affected; leather balls cut through moderate wind much better.

4. **Humidity & Heat-Index ($10\%$)**:
   - **Formula**: Optimal at $40\% - 65\%$ ($100$). Humidity $> 65\%$ incurs $(rh - 65) \times 3.0$ penalty.
   - **Rationale**: High humidity combined with direct sun severely impedes sweat evaporation for fast bowlers and batsmen wearing pads and helmets.

5. **UV Radiation Index ($10\%$)**:
   - **Formula**: Evaluated **only during daylight hours** (`isDay == true`). Night/evening automatically receives $100.0$.
     - $\text{UV} \le 2.5 \rightarrow 100$; $\text{UV} \le 5.5 \rightarrow 85$; $\text{UV} \le 7.5 \rightarrow 65$; $\text{UV} \le 10.5 \rightarrow 40$; $\text{UV} > 10.5 \rightarrow 20$.
   - **Rationale**: Protects amateur players from severe sunburn and heat fatigue during peak afternoon midday hours.

---

## 3. Ground & Ambient Conditions (`ConditionsScorer`)

Evaluates ambient variables across the playing window:

$$\text{ConditionsScore} = 0.40 \cdot \text{WetOutfield} + 0.30 \cdot \text{DewRisk} + 0.30 \cdot \text{Daylight}$$

1. **Wet Outfield ($40\%$)**:
   - **Source**: Cumulative rainfall in the **previous 12–24 hours** prior to the session start.
   - **Formula**: $100.0 - (\text{pastRainMm} \times 10.0)$, clamped to $[0.0, 100.0]$.
   - **Rationale**: Even under sunny skies, prior downpours leave standing water, mud, and waterlogged grass that lead to groin/knee slips and waterlogged balls.

2. **Dew Risk ($30\%$)**:
   - **Source**: Dew point depression $\Delta T = T_{\text{air}} - T_{\text{dew}}$ during late afternoon/evening/night.
   - **Formula**: Baseline $\left(\frac{\Delta T}{6.0}\right) \times 100.0$, scaled by `BallType.dewSensitivityFactor`.
   - **Rationale**: In the evening, when air temperature drops near the dew point ($\Delta T \le 2^\circ\text{C}$), dew condenses rapidly on grass. Leather balls become soaked, slippery to grip, and impossible to spin or seam.

3. **Daylight Coverage ($30\%$)**:
   - **Source**: Percentage of window occurring in natural daylight (`isDay == true`).
   - **Rationale**:
     - **Leather Ball**: Strictly requires natural daylight ($100\%$ daylight $= 100$, $0\%$ daylight $= 0$ and triggers a **hard veto**).
     - **Tennis & Box Cricket**: Highly daylight-tolerant ($85.0 + \text{fraction} \times 15.0$) as they are frequently played under park floodlights or streetlights.

---

## 4. Player Availability & Quorum (`AvailabilityScorer`)

- **Default Quorum**: 6 players (configurable).
- **Below Quorum**:
  $$\text{Score} = \left(\frac{\text{attending}}{\text{quorum}}\right) \times 50.0 \quad (\le 50.0)$$
- **Quorum Met ($\ge \text{quorum}$)**:
  $$\text{Score} = 75.0 + \left(\frac{\text{attending} - \text{quorum}}{\text{totalSquad} - \text{quorum}}\right) \times 25.0 \quad (75.0 - 100.0)$$

---

## 5. Hard Vetoes (Capped at $\le 30.0$)

If any safety or game-breaking condition occurs, the final session score is unconditionally capped at $\mathbf{30.0}$ ("Poor" / "Not recommended"), regardless of other sub-scores:

1. **Thunderstorm Hazard**: Any hour with WMO code $95, 96, 99$ (lightning strikes pose lethal danger in open fields).
2. **High Rain Probability**: Any hour with precipitation probability $> 70\%$.
3. **Below Quorum**: Fewer players than the quorum available for the entire window duration.
4. **Leather Ball in Darkness**: Playing with a hard leather ball in $0\%$ daylight (severe injury risk).

---

## 6. Categorical Labels & Reason Chips

| Score Range | Label | Recommendation |
| :---: | :---: | :--- |
| **85 – 100** | **Excellent** | Optimal match conditions, ideal temperature, full squad, dry pitch. |
| **70 – 84** | **Good** | Solid conditions with minor compromises (e.g. slight breeze or moderate turnout). |
| **50 – 69** | **Fair** | Playable but sub-optimal (e.g. chilly, damp outfield, or tight quorum). |
| **30 – 49** | **Poor** | Problematic conditions (e.g. rain likely, cold, or high dew). |
| **0 – 29** | **Not recommended** | Hard veto triggered or unplayable weather. |
