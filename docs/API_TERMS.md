# Open-Meteo API Terms, Limits, and Attribution Guide

This document records the official terms of use, usage limits, licensing conditions, and attribution requirements for the Open-Meteo APIs utilized by **CricketMate**, as well as the architectural mechanisms implemented to respect them.

---

## 1. API Endpoints Utilized

CricketMate interacts with two primary Open-Meteo endpoints:

### A. Weather Forecast API
- **Endpoint URL**: `https://api.open-meteo.com/v1/forecast`
- **Authentication**: None required (Free/Open-Access tier).
- **Core Parameters**:
  - `latitude`, `longitude`: Float coordinates of the pitch or playing venue.
  - `hourly`: Comma-separated list of hourly variables needed for cricket playability analysis:
    - `temperature_2m`: Surface air temperature (default °C).
    - `relative_humidity_2m`: Humidity percentage for ball swing & comfort assessment.
    - `apparent_temperature`: "Feels-like" temperature.
    - `precipitation_probability`: Probability of rain (%).
    - `precipitation`: Expected rain amount (mm).
    - `weather_code`: WMO weather interpretation code (0 = clear sky, 51–67 = rain, 80–82 = rain showers, 95–99 = thunderstorm).
    - `wind_speed_10m`: Wind speed at 10m (default km/h).
    - `wind_gusts_10m`: Peak gust speeds.
    - `is_day`: Day (1) or night (0) flag.
  - `daily`: Comma-separated daily aggregates:
    - `sunrise`, `sunset`: Essential for daylight match scheduling and determining match cutoff times.
    - `weather_code`, `temperature_2m_max`, `temperature_2m_min`.
  - `past_days`: Integer (0–92). Enables retrieval of recent historical weather (e.g., past 1 day) to evaluate pitch moisture and ground saturation from prior rain.
  - `forecast_days`: Integer (1–16, default 7). Typically set to 1–3 for immediate and near-term cricket session planning.
  - `timezone`: Recommended `auto` so that all returned timestamps align with the venue's local solar/clock time.

### B. Geocoding API
- **Endpoint URL**: `https://geocoding-api.open-meteo.com/v1/search`
- **Authentication**: None required (Free/Open-Access tier).
- **Core Parameters**:
  - `name`: Ground, city, or locality name to resolve (string, min 2 chars).
  - `count`: Maximum number of search results to return (default 10, max 100).
  - `language`: Result naming language (e.g., `en`).
  - `format`: Output format (`json`).
- **Response Structure**: Array of matching geographic entries containing `id`, `name`, `latitude`, `longitude`, `elevation`, `country_code`, `country`, `admin1` (state/province), and `timezone`.

---

## 2. Usage Limits (Free / Open-Access Tier)

Open-Meteo applies fair-use limits enforced on an IP address basis:

| Metric | Free Tier Limit |
|---|---|
| **Minutely Rate Limit** | **600 calls / minute** |
| **Hourly Rate Limit** | **5,000 calls / hour** |
| **Daily Rate Limit** | **10,000 calls / day** |
| **Monthly Rate Limit** | **300,000 calls / month** |
| **Commercial Use** | ❌ Not permitted on Free tier (Requires API Standard/Enterprise) |
| **SLA / Uptime Guarantee**| None; provided "as is" on a best-effort basis |

*Note: Complex multi-location queries or long historical spans may count as multiple API calls. Exceeding limits results in HTTP `429 Too Many Requests`.*

---

## 3. Non-Commercial Terms

Open-Meteo defines non-commercial use in alignment with the Creative Commons NonCommercial guidelines:
- **Permitted Non-Commercial Use**:
  - Private, hobbyist, or non-profit applications that do not incorporate subscriptions, paywalls, or advertisements.
  - Educational projects and coursework / take-home assignments.
  - Public academic research.
  - Personal home automation.
- **Commercial Use (Prohibited on Free Tier)**:
  - Operating applications or websites that display advertisements or require subscriptions/fees.
  - Integrating into commercial products, services, or promotional marketing activities.
  - Undisclosed commercial entity research.

> **CricketMate Qualification**: CricketMate is developed as an educational take-home application and open-source project without monetization, advertisements, or paid features, strictly adhering to Open-Meteo's non-commercial terms.

---

## 4. Licensing & Attribution Requirements

### Licenses
- **Data License**: **Creative Commons Attribution 4.0 International (CC BY 4.0)**.
- **Open-Meteo Server Code**: GNU AGPLv3.
- **Underlying Sources**: Open-Meteo integrates open meteorological data from national weather services (e.g., DWD, ECMWF, NOAA NCEP, Météo-France, Met Norway, JMA) and geographical data from GeoNames.

### Mandatory Attribution
Under CC BY 4.0, any display of Open-Meteo data must include clear attribution and a link back to Open-Meteo without implying endorsement.

- **Required Link Text**:
  ```html
  <a href="https://open-meteo.com/">Weather data by Open-Meteo.com</a>
  ```
- **App Requirement**: A visible attribution link must be displayed on any screen presenting weather forecasts, as well as in the app's About/Settings screen. For location searches derived from the Geocoding API, credit to GeoNames should also be noted.

---

## 5. How CricketMate Respects API Terms & Limits

To ensure strict compliance with Open-Meteo's fair-usage policies and conserve network resources, CricketMate implements four architectural safeguards:

### 1. Search Debouncing (Geocoding API)
- Real-time location search fields are debounced with a minimum delay of **400 ms**.
- Requests are only dispatched after the user pauses typing and the query contains at least 3 characters.
- In-flight requests are cancelled when a new query is entered.

### 2. Intelligent Multi-Tier Caching (Forecast & Geocoding)
- **Forecast Caching**: Weather forecasts for a given coordinate are cached with a **Time-To-Live (TTL) of 30 minutes**. Subsequent views or session recalculations within this window read from the repository cache, eliminating redundant network calls.
- **Geocoding Caching**: Frequently searched venues or recent locations are cached locally, eliminating repeat network calls for identical queries.
- **Stale-While-Revalidate / Offline Mode**: If a network request fails or is rate-limited, cached data is surfaced with a clear timestamp warning rather than crashing.

### 3. Requesting Only Essential Variables
- The application queries strictly the parameters necessary for cricket viability calculations (`temperature_2m`, `precipitation_probability`, `precipitation`, `weather_code`, `wind_speed_10m`, `sunrise`, `sunset`, `past_days=1`, and `forecast_days=2`).
- Unnecessary bulk atmospheric parameters (e.g. soil temperature, radiation, air pressure at multiple isobar levels) are explicitly omitted to keep payloads lightweight and minimize server computational load.

### 4. Visible UI Attribution
- Every weather card and the planner results view includes a clean, non-intrusive footer element:
  *"Weather data by Open-Meteo.com (CC BY 4.0)"* linking directly to `https://open-meteo.com/`.
- An "About & Licenses" dialog/screen lists Open-Meteo, CC BY 4.0, and GeoNames data source attributions with clickable links.
