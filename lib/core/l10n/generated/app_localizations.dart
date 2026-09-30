import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// Main application title
  ///
  /// In en, this message translates to:
  /// **'CricketMate'**
  String get appTitle;

  /// Label for the Sessions navigation tab
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsTab;

  /// Label for the Players navigation tab
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersTab;

  /// Label for the Settings navigation tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// Short weather attribution notice
  ///
  /// In en, this message translates to:
  /// **'Weather data by Open-Meteo.com'**
  String get weatherAttribution;

  /// Full weather data attribution with license
  ///
  /// In en, this message translates to:
  /// **'Weather data provided by Open-Meteo.com (CC BY 4.0)'**
  String get weatherAttributionFull;

  /// Error message for offline or network connectivity issues
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server. Please check your internet connection.'**
  String get errorNetworkConnection;

  /// Error message for network request timeout
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get errorRequestTimeout;

  /// Error message for server HTTP 5xx errors
  ///
  /// In en, this message translates to:
  /// **'The server encountered an error. Please try again later.'**
  String get errorServer;

  /// Error message for malformed JSON or parsing errors
  ///
  /// In en, this message translates to:
  /// **'Failed to process server response data.'**
  String get errorParsingFailed;

  /// Generic unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorGeneric;

  /// Button label to retry an action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Hint text in the location search bar
  ///
  /// In en, this message translates to:
  /// **'Search cricket ground / city...'**
  String get searchHint;

  /// Message displayed when geocoding search yields zero results
  ///
  /// In en, this message translates to:
  /// **'No cricket grounds or cities found'**
  String get searchNoResults;

  /// Title prompting user to select a location
  ///
  /// In en, this message translates to:
  /// **'Choose a Cricket Ground'**
  String get searchPrompt;

  /// Subtitle prompting user to search a location
  ///
  /// In en, this message translates to:
  /// **'Use the search bar above to search for your local cricket ground or city to check conditions.'**
  String get searchPromptSubtitle;

  /// CTA button to search location
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocationButton;

  /// Title when weather fetching fails
  ///
  /// In en, this message translates to:
  /// **'Unable to Load Weather'**
  String get unableToLoadWeather;

  /// Header title on the top ranked session card
  ///
  /// In en, this message translates to:
  /// **'BEST TIME TO PLAY'**
  String get bestTimeToPlay;

  /// Button to inspect details of a session candidate
  ///
  /// In en, this message translates to:
  /// **'View Session Details'**
  String get viewSessionDetails;

  /// Title when no candidate playing windows match requirements
  ///
  /// In en, this message translates to:
  /// **'No Sessions Planned'**
  String get noViableSessionsTitle;

  /// Subtitle when no candidate sessions match
  ///
  /// In en, this message translates to:
  /// **'Add players or adjust match settings to find optimal playing windows.'**
  String get noViableSessionsSubtitle;

  /// CTA button to navigate to players screen
  ///
  /// In en, this message translates to:
  /// **'Add Players'**
  String get addPlayersButton;

  /// Badge indicating fresh online weather data
  ///
  /// In en, this message translates to:
  /// **'Live Forecast'**
  String get liveForecast;

  /// Badge indicating offline cached weather data
  ///
  /// In en, this message translates to:
  /// **'Offline (Updated {timeAgo})'**
  String offlineCache(String timeAgo);

  /// Status text while updating data
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// Time ago for moments ago
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} mins ago}}'**
  String minutesAgo(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// Header for secondary session recommendations
  ///
  /// In en, this message translates to:
  /// **'Other Candidate Windows'**
  String get otherSessionsTitle;

  /// Rank indicator for session candidate
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String rankBadge(int rank);

  /// Label for ball type filter chip
  ///
  /// In en, this message translates to:
  /// **'Ball'**
  String get ballTypeLabel;

  /// Label for duration filter chip
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// Label for minimum players filter chip
  ///
  /// In en, this message translates to:
  /// **'Min Players'**
  String get minPlayersLabel;

  /// Label for sorting menu
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortByLabel;

  /// Sort option: best overall score
  ///
  /// In en, this message translates to:
  /// **'Best Score'**
  String get sortScore;

  /// Sort option: earliest start time
  ///
  /// In en, this message translates to:
  /// **'Earliest Time'**
  String get sortTime;

  /// Sort option: highest player turnout
  ///
  /// In en, this message translates to:
  /// **'Highest Attendance'**
  String get sortAttendance;

  /// Tennis ball type name
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get ballTypeTennis;

  /// Tennis ball characteristics description
  ///
  /// In en, this message translates to:
  /// **'Standard light tennis ball. High dew & wind tolerance.'**
  String get ballTypeTennisDesc;

  /// Leather ball type name
  ///
  /// In en, this message translates to:
  /// **'Leather'**
  String get ballTypeLeather;

  /// Leather ball characteristics description
  ///
  /// In en, this message translates to:
  /// **'Traditional red cricket ball. Strictly requires daylight.'**
  String get ballTypeLeatherDesc;

  /// Box turf ball type name
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get ballTypeBox;

  /// Box ball characteristics description
  ///
  /// In en, this message translates to:
  /// **'Enclosed turf cricket ball. Weather resilient.'**
  String get ballTypeBoxDesc;

  /// Duration formatted in hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String durationHours(int count);

  /// Short duration in hours
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String durationHoursShort(String count);

  /// Session rating label for scores >= 85
  ///
  /// In en, this message translates to:
  /// **'Exceptional'**
  String get ratingExceptional;

  /// Session rating label for scores 70-84
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get ratingGreat;

  /// Session rating label for scores 55-69
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// Session rating label for scores 40-54
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get ratingFair;

  /// Session rating label for scores < 40
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get ratingPoor;

  /// Label for weather component in score breakdown
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get scoreWeatherLabel;

  /// Label for player availability in score breakdown
  ///
  /// In en, this message translates to:
  /// **'Squad Availability'**
  String get scoreAvailabilityLabel;

  /// Label for ground and dew conditions in score breakdown
  ///
  /// In en, this message translates to:
  /// **'Outfield Conditions'**
  String get scoreConditionsLabel;

  /// Section header explaining session rating
  ///
  /// In en, this message translates to:
  /// **'Why this time?'**
  String get whyThisTime;

  /// Warning banner title when hard veto conditions apply
  ///
  /// In en, this message translates to:
  /// **'Session Viability Veto Triggered'**
  String get vetoBannerTitle;

  /// Veto reason: active thunderstorm
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm hazard (lightning danger)'**
  String get reasonThunderstorm;

  /// Veto reason: rain probability > 70%
  ///
  /// In en, this message translates to:
  /// **'High rain probability ({percent}%)'**
  String reasonRainRisk(int percent);

  /// Veto reason: fewer players than quorum
  ///
  /// In en, this message translates to:
  /// **'Below squad quorum ({count}/{quorum} required players)'**
  String reasonBelowQuorum(int count, int quorum);

  /// Veto reason: leather ball played in darkness
  ///
  /// In en, this message translates to:
  /// **'Leather ball requires natural daylight'**
  String get reasonLeatherDaylight;

  /// Positive reason: favorable low rain
  ///
  /// In en, this message translates to:
  /// **'Low rain chance'**
  String get reasonLowRain;

  /// Positive reason: comfortable temperature
  ///
  /// In en, this message translates to:
  /// **'Ideal cricket temperature'**
  String get reasonIdealTemp;

  /// Warning reason: cold temperature
  ///
  /// In en, this message translates to:
  /// **'Chilly temperature'**
  String get reasonChillyTemp;

  /// Positive reason: mild wind
  ///
  /// In en, this message translates to:
  /// **'Gentle breeze'**
  String get reasonGentleBreeze;

  /// Warning reason: high wind speed or gusts
  ///
  /// In en, this message translates to:
  /// **'Gusty wind conditions'**
  String get reasonGustyWind;

  /// Negative reason: wet outfield from recent rain
  ///
  /// In en, this message translates to:
  /// **'Wet ground from last night\'s rain ({mm}mm)'**
  String reasonWetGround(String mm);

  /// Positive reason: dry playing surface
  ///
  /// In en, this message translates to:
  /// **'Dry outfield'**
  String get reasonDryOutfield;

  /// Warning reason: dew point temperature gap creates moisture
  ///
  /// In en, this message translates to:
  /// **'Evening dew risk (slippery ball)'**
  String get reasonDewRisk;

  /// Positive reason: quorum satisfied
  ///
  /// In en, this message translates to:
  /// **'Squad quorum reached ({count}/{quorum} players)'**
  String reasonQuorumReached(int count, int quorum);

  /// Title for players attendance section
  ///
  /// In en, this message translates to:
  /// **'Squad Attendance'**
  String get squadAttendanceTitle;

  /// Header for confirmed available players
  ///
  /// In en, this message translates to:
  /// **'Confirmed ({count})'**
  String confirmedPlayersCount(int count);

  /// Header for missing/unavailable squad members
  ///
  /// In en, this message translates to:
  /// **'Missing ({count})'**
  String missingPlayersCount(int count);

  /// Notice when entire registered squad is confirmed
  ///
  /// In en, this message translates to:
  /// **'All squad members available!'**
  String get allSquadAvailable;

  /// Notice when zero squad members can play
  ///
  /// In en, this message translates to:
  /// **'No squad members available for this window.'**
  String get noPlayersAvailable;

  /// ICU plural for player count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No players} =1{1 player} other{{count} players}}'**
  String playerCountPlural(int count);

  /// Format for turnout fraction
  ///
  /// In en, this message translates to:
  /// **'{available}/{total} players available'**
  String playersAvailableOutOf(int available, int total);

  /// Title for hourly weather forecast strip
  ///
  /// In en, this message translates to:
  /// **'Hourly Conditions'**
  String get hourlyConditionsTitle;

  /// Subtitle indicating hourly chart span
  ///
  /// In en, this message translates to:
  /// **'Match Window ± 2h'**
  String get hourlyConditionsSubtitle;

  /// Legend label for rain probability bars
  ///
  /// In en, this message translates to:
  /// **'Rain %'**
  String get legendRainProb;

  /// Legend label for temperature curve
  ///
  /// In en, this message translates to:
  /// **'Temp (°C)'**
  String get legendTemperature;

  /// Legend label for sunset dashed marker
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get legendSunset;

  /// Legend label for highlighted match window band
  ///
  /// In en, this message translates to:
  /// **'Match Window'**
  String get legendMatchWindow;

  /// Button label to share match invitation
  ///
  /// In en, this message translates to:
  /// **'Share Invite via WhatsApp'**
  String get shareInviteButton;

  /// Tooltip for share button
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get shareInviteTooltip;

  /// WhatsApp invite markdown title
  ///
  /// In en, this message translates to:
  /// **'🏏 *Cricket Session Invitation*'**
  String get inviteTitle;

  /// WhatsApp invite venue label
  ///
  /// In en, this message translates to:
  /// **'📍 *Venue:*'**
  String get inviteVenue;

  /// WhatsApp invite date label
  ///
  /// In en, this message translates to:
  /// **'📅 *Date:*'**
  String get inviteDate;

  /// WhatsApp invite time label
  ///
  /// In en, this message translates to:
  /// **'⏰ *Time:*'**
  String get inviteTime;

  /// WhatsApp invite ball type label
  ///
  /// In en, this message translates to:
  /// **'🏏 *Ball:*'**
  String get inviteBall;

  /// WhatsApp invite score label
  ///
  /// In en, this message translates to:
  /// **'⭐ *Session Score:*'**
  String get inviteScore;

  /// WhatsApp invite conditions label
  ///
  /// In en, this message translates to:
  /// **'📋 *Key Conditions:*'**
  String get inviteKeyReasons;

  /// WhatsApp invite lineup label
  ///
  /// In en, this message translates to:
  /// **'👥 *Confirmed Lineup:*'**
  String get inviteConfirmedLineup;

  /// WhatsApp invite closing greeting
  ///
  /// In en, this message translates to:
  /// **'Let\'s play cricket! Scheduled via CricketMate.'**
  String get inviteFooter;

  /// Title of the Players & Availability screen
  ///
  /// In en, this message translates to:
  /// **'Squad & Availability'**
  String get squadScreenTitle;

  /// Tooltip for add player icon
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get addPlayerTooltip;

  /// Button label to add a new player
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get addPlayerButton;

  /// Button label on empty squad screen
  ///
  /// In en, this message translates to:
  /// **'Add First Player'**
  String get addFirstPlayerButton;

  /// Empty state title when squad has 0 players
  ///
  /// In en, this message translates to:
  /// **'No players added yet'**
  String get noPlayersYetTitle;

  /// Empty state subtitle for players screen
  ///
  /// In en, this message translates to:
  /// **'Add your cricket squad members to find the best match time.'**
  String get noPlayersYetSubtitle;

  /// Header title on the live squad overlap preview card
  ///
  /// In en, this message translates to:
  /// **'BEST SQUAD OVERLAP'**
  String get bestSquadOverlap;

  /// Label for Today day tab/selector
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for Tomorrow day tab/selector
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Short chip label for tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tmrw'**
  String get tomorrowShort;

  /// Message when squad members have no overlapping availability
  ///
  /// In en, this message translates to:
  /// **'No common overlap found'**
  String get noCommonOverlap;

  /// Subtitle when no overlap exists
  ///
  /// In en, this message translates to:
  /// **'Adjust player availability to create an overlapping match window.'**
  String get noCommonOverlapSubtitle;

  /// Prompt when squad is empty in overlap card
  ///
  /// In en, this message translates to:
  /// **'Add players to calculate overlap'**
  String get addPlayersToCalculate;

  /// Tooltip for editing player availability
  ///
  /// In en, this message translates to:
  /// **'Edit availability for {name}'**
  String editAvailabilityTooltip(String name);

  /// Tooltip for removing a player
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removePlayerTooltip(String name);

  /// Label shown when a player has no slots set
  ///
  /// In en, this message translates to:
  /// **'No slots scheduled'**
  String get noSlotsScheduled;

  /// Snackbar text after deleting a player
  ///
  /// In en, this message translates to:
  /// **'Player {name} removed'**
  String playerRemovedSnackbar(String name);

  /// Action label to undo an action in snackbar
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Title of add player dialog
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get addPlayerDialogTitle;

  /// Label for player name text field
  ///
  /// In en, this message translates to:
  /// **'Player Name'**
  String get playerNameLabel;

  /// Placeholder hint in player name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Virat Kohli'**
  String get playerNameHint;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Validation error for empty player name
  ///
  /// In en, this message translates to:
  /// **'Player name cannot be empty'**
  String get nameCannotBeEmpty;

  /// Validation error for duplicate player name
  ///
  /// In en, this message translates to:
  /// **'A player with this name already exists'**
  String get nameAlreadyExists;

  /// Validation error when player name exceeds length
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed 50 characters'**
  String get nameTooLong;

  /// Title of availability bottom sheet modal
  ///
  /// In en, this message translates to:
  /// **'Edit Availability'**
  String get editAvailabilityTitle;

  /// Header for quick tap presets
  ///
  /// In en, this message translates to:
  /// **'Quick Presets (Tap to Add)'**
  String get quickPresetsTitle;

  /// Preset name: Evening 5pm to 8pm
  ///
  /// In en, this message translates to:
  /// **'Evening 5-8'**
  String get presetEvening;

  /// Preset name: Weekend morning 8am to 11am
  ///
  /// In en, this message translates to:
  /// **'Weekend morning'**
  String get presetWeekendMorning;

  /// Preset name: Morning 7am to 10am
  ///
  /// In en, this message translates to:
  /// **'Morning 7-10'**
  String get presetMorning;

  /// Preset name: Afternoon 2pm to 5pm
  ///
  /// In en, this message translates to:
  /// **'Afternoon 2-5'**
  String get presetAfternoon;

  /// Header for manual start/end dropdowns
  ///
  /// In en, this message translates to:
  /// **'Custom Range Picker (30-min steps)'**
  String get customRangeTitle;

  /// Label for start time dropdown
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// Label for end time dropdown
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeLabel;

  /// Button to add selected start/end range
  ///
  /// In en, this message translates to:
  /// **'Add Time Slot'**
  String get addSlotButton;

  /// Header for scheduled slots list
  ///
  /// In en, this message translates to:
  /// **'Scheduled Slots for {day}'**
  String scheduledSlotsTitle(String day);

  /// Message when day has 0 availability slots
  ///
  /// In en, this message translates to:
  /// **'No slots scheduled for this day yet.'**
  String get noSlotsForDay;

  /// Primary action button to commit availability
  ///
  /// In en, this message translates to:
  /// **'Save Availability'**
  String get saveAvailabilityButton;

  /// Validation error when end time is before or equal to start
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get slotEndMustBeAfterStart;

  /// Time label for midnight
  ///
  /// In en, this message translates to:
  /// **'Midnight (12:00 AM)'**
  String get midnight;

  /// Title of settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings & Preferences'**
  String get settingsScreenTitle;

  /// Section header for match rules and defaults
  ///
  /// In en, this message translates to:
  /// **'Match Preferences'**
  String get matchSettingsSection;

  /// Title for ball type setting
  ///
  /// In en, this message translates to:
  /// **'Default Ball Type'**
  String get defaultBallType;

  /// Title for match duration setting
  ///
  /// In en, this message translates to:
  /// **'Default Match Duration'**
  String get defaultDuration;

  /// Title for squad quorum setting
  ///
  /// In en, this message translates to:
  /// **'Minimum Squad Quorum'**
  String get squadQuorum;

  /// Description of active quorum requirement
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player required for a valid session} other{{count} players required for a valid session}}'**
  String quorumDescription(int count);

  /// Section header for theme and language
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferencesSection;

  /// Title for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appTheme;

  /// System default theme mode option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme mode option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Title for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Hindi language option
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// Section header for data attribution and version
  ///
  /// In en, this message translates to:
  /// **'About & Data Sources'**
  String get aboutSection;

  /// Title for data attribution tile
  ///
  /// In en, this message translates to:
  /// **'Data Attribution'**
  String get dataAttribution;

  /// Subtitle describing Open-Meteo data license
  ///
  /// In en, this message translates to:
  /// **'Weather forecasts provided by Open-Meteo.com under CC BY 4.0 license'**
  String get dataAttributionSubtitle;

  /// Link text for Open-Meteo website
  ///
  /// In en, this message translates to:
  /// **'Open-Meteo.com'**
  String get openMeteoWebsite;

  /// Title for default ground tile
  ///
  /// In en, this message translates to:
  /// **'Default Ground / Location'**
  String get homePitch;

  /// Subtitle showing active selected cricket ground
  ///
  /// In en, this message translates to:
  /// **'Currently using: {name}'**
  String homePitchSubtitle(String name);

  /// Application version information
  ///
  /// In en, this message translates to:
  /// **'CricketMate Version 1.0.0'**
  String get versionInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
