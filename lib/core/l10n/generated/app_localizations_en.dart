// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CricketMate';

  @override
  String get sessionsTab => 'Sessions';

  @override
  String get playersTab => 'Players';

  @override
  String get settingsTab => 'Settings';

  @override
  String get weatherAttribution => 'Weather data by Open-Meteo.com';

  @override
  String get weatherAttributionFull =>
      'Weather data provided by Open-Meteo.com (CC BY 4.0)';

  @override
  String get errorNetworkConnection =>
      'Unable to connect to the server. Please check your internet connection.';

  @override
  String get errorRequestTimeout => 'The request timed out. Please try again.';

  @override
  String get errorServer =>
      'The server encountered an error. Please try again later.';

  @override
  String get errorParsingFailed => 'Failed to process server response data.';

  @override
  String get errorGeneric => 'An unexpected error occurred.';

  @override
  String get retry => 'Retry';

  @override
  String get searchHint => 'Search cricket ground / city...';

  @override
  String get searchNoResults => 'No cricket grounds or cities found';

  @override
  String get searchPrompt => 'Choose a Cricket Ground';

  @override
  String get searchPromptSubtitle =>
      'Use the search bar above to search for your local cricket ground or city to check conditions.';

  @override
  String get searchLocationButton => 'Search Location';

  @override
  String get unableToLoadWeather => 'Unable to Load Weather';

  @override
  String get bestTimeToPlay => 'BEST TIME TO PLAY';

  @override
  String get viewSessionDetails => 'View Session Details';

  @override
  String get noViableSessionsTitle => 'No Sessions Planned';

  @override
  String get noViableSessionsSubtitle =>
      'Add players or adjust match settings to find optimal playing windows.';

  @override
  String get addPlayersButton => 'Add Players';

  @override
  String get liveForecast => 'Live Forecast';

  @override
  String offlineCache(String timeAgo) {
    return 'Offline (Updated $timeAgo)';
  }

  @override
  String get updating => 'Updating...';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mins ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get otherSessionsTitle => 'Other Candidate Windows';

  @override
  String rankBadge(int rank) {
    return '#$rank';
  }

  @override
  String get ballTypeLabel => 'Ball';

  @override
  String get durationLabel => 'Duration';

  @override
  String get minPlayersLabel => 'Min Players';

  @override
  String get sortByLabel => 'Sort By';

  @override
  String get sortScore => 'Best Score';

  @override
  String get sortTime => 'Earliest Time';

  @override
  String get sortAttendance => 'Highest Attendance';

  @override
  String get ballTypeTennis => 'Tennis';

  @override
  String get ballTypeTennisDesc =>
      'Standard light tennis ball. High dew & wind tolerance.';

  @override
  String get ballTypeLeather => 'Leather';

  @override
  String get ballTypeLeatherDesc =>
      'Traditional red cricket ball. Strictly requires daylight.';

  @override
  String get ballTypeBox => 'Box';

  @override
  String get ballTypeBoxDesc =>
      'Enclosed turf cricket ball. Weather resilient.';

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationHoursShort(String count) {
    return '${count}h';
  }

  @override
  String get ratingExceptional => 'Exceptional';

  @override
  String get ratingGreat => 'Great';

  @override
  String get ratingGood => 'Good';

  @override
  String get ratingFair => 'Fair';

  @override
  String get ratingPoor => 'Poor';

  @override
  String get scoreWeatherLabel => 'Weather';

  @override
  String get scoreAvailabilityLabel => 'Squad Availability';

  @override
  String get scoreConditionsLabel => 'Outfield Conditions';

  @override
  String get whyThisTime => 'Why this time?';

  @override
  String get vetoBannerTitle => 'Session Viability Veto Triggered';

  @override
  String get reasonThunderstorm => 'Thunderstorm hazard (lightning danger)';

  @override
  String reasonRainRisk(int percent) {
    return 'High rain probability ($percent%)';
  }

  @override
  String reasonBelowQuorum(int count, int quorum) {
    return 'Below squad quorum ($count/$quorum required players)';
  }

  @override
  String get reasonLeatherDaylight => 'Leather ball requires natural daylight';

  @override
  String get reasonLowRain => 'Low rain chance';

  @override
  String get reasonIdealTemp => 'Ideal cricket temperature';

  @override
  String get reasonChillyTemp => 'Chilly temperature';

  @override
  String get reasonGentleBreeze => 'Gentle breeze';

  @override
  String get reasonGustyWind => 'Gusty wind conditions';

  @override
  String reasonWetGround(String mm) {
    return 'Wet ground from last night\'s rain (${mm}mm)';
  }

  @override
  String get reasonDryOutfield => 'Dry outfield';

  @override
  String get reasonDewRisk => 'Evening dew risk (slippery ball)';

  @override
  String reasonQuorumReached(int count, int quorum) {
    return 'Squad quorum reached ($count/$quorum players)';
  }

  @override
  String get squadAttendanceTitle => 'Squad Attendance';

  @override
  String confirmedPlayersCount(int count) {
    return 'Confirmed ($count)';
  }

  @override
  String missingPlayersCount(int count) {
    return 'Missing ($count)';
  }

  @override
  String get allSquadAvailable => 'All squad members available!';

  @override
  String get noPlayersAvailable =>
      'No squad members available for this window.';

  @override
  String playerCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
      zero: 'No players',
    );
    return '$_temp0';
  }

  @override
  String playersAvailableOutOf(int available, int total) {
    return '$available/$total players available';
  }

  @override
  String get hourlyConditionsTitle => 'Hourly Conditions';

  @override
  String get hourlyConditionsSubtitle => 'Match Window ± 2h';

  @override
  String get legendRainProb => 'Rain %';

  @override
  String get legendTemperature => 'Temp (°C)';

  @override
  String get legendSunset => 'Sunset';

  @override
  String get legendMatchWindow => 'Match Window';

  @override
  String get shareInviteButton => 'Share Invite via WhatsApp';

  @override
  String get shareInviteTooltip => 'Share Invite';

  @override
  String get inviteTitle => '🏏 *Cricket Session Invitation*';

  @override
  String get inviteVenue => '📍 *Venue:*';

  @override
  String get inviteDate => '📅 *Date:*';

  @override
  String get inviteTime => '⏰ *Time:*';

  @override
  String get inviteBall => '🏏 *Ball:*';

  @override
  String get inviteScore => '⭐ *Session Score:*';

  @override
  String get inviteKeyReasons => '📋 *Key Conditions:*';

  @override
  String get inviteConfirmedLineup => '👥 *Confirmed Lineup:*';

  @override
  String get inviteFooter => 'Let\'s play cricket! Scheduled via CricketMate.';

  @override
  String get squadScreenTitle => 'Squad & Availability';

  @override
  String get addPlayerTooltip => 'Add Player';

  @override
  String get addPlayerButton => 'Add Player';

  @override
  String get addFirstPlayerButton => 'Add First Player';

  @override
  String get noPlayersYetTitle => 'No players added yet';

  @override
  String get noPlayersYetSubtitle =>
      'Add your cricket squad members to find the best match time.';

  @override
  String get bestSquadOverlap => 'BEST SQUAD OVERLAP';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get tomorrowShort => 'Tmrw';

  @override
  String get noCommonOverlap => 'No common overlap found';

  @override
  String get noCommonOverlapSubtitle =>
      'Adjust player availability to create an overlapping match window.';

  @override
  String get addPlayersToCalculate => 'Add players to calculate overlap';

  @override
  String editAvailabilityTooltip(String name) {
    return 'Edit availability for $name';
  }

  @override
  String removePlayerTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String get noSlotsScheduled => 'No slots scheduled';

  @override
  String playerRemovedSnackbar(String name) {
    return 'Player $name removed';
  }

  @override
  String get undo => 'Undo';

  @override
  String get addPlayerDialogTitle => 'Add Player';

  @override
  String get playerNameLabel => 'Player Name';

  @override
  String get playerNameHint => 'e.g. Virat Kohli';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get nameCannotBeEmpty => 'Player name cannot be empty';

  @override
  String get nameAlreadyExists => 'A player with this name already exists';

  @override
  String get nameTooLong => 'Name cannot exceed 50 characters';

  @override
  String get editAvailabilityTitle => 'Edit Availability';

  @override
  String get quickPresetsTitle => 'Quick Presets (Tap to Add)';

  @override
  String get presetEvening => 'Evening 5-8';

  @override
  String get presetWeekendMorning => 'Weekend morning';

  @override
  String get presetMorning => 'Morning 7-10';

  @override
  String get presetAfternoon => 'Afternoon 2-5';

  @override
  String get customRangeTitle => 'Custom Range Picker (30-min steps)';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get endTimeLabel => 'End Time';

  @override
  String get addSlotButton => 'Add Time Slot';

  @override
  String scheduledSlotsTitle(String day) {
    return 'Scheduled Slots for $day';
  }

  @override
  String get noSlotsForDay => 'No slots scheduled for this day yet.';

  @override
  String get saveAvailabilityButton => 'Save Availability';

  @override
  String get slotEndMustBeAfterStart => 'End time must be after start time';

  @override
  String get midnight => 'Midnight (12:00 AM)';

  @override
  String get settingsScreenTitle => 'Settings & Preferences';

  @override
  String get matchSettingsSection => 'Match Preferences';

  @override
  String get defaultBallType => 'Default Ball Type';

  @override
  String get defaultDuration => 'Default Match Duration';

  @override
  String get squadQuorum => 'Minimum Squad Quorum';

  @override
  String quorumDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players required for a valid session',
      one: '1 player required for a valid session',
    );
    return '$_temp0';
  }

  @override
  String get appPreferencesSection => 'App Preferences';

  @override
  String get appTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get aboutSection => 'About & Data Sources';

  @override
  String get dataAttribution => 'Data Attribution';

  @override
  String get dataAttributionSubtitle =>
      'Weather forecasts provided by Open-Meteo.com under CC BY 4.0 license';

  @override
  String get openMeteoWebsite => 'Open-Meteo.com';

  @override
  String get homePitch => 'Default Ground / Location';

  @override
  String homePitchSubtitle(String name) {
    return 'Currently using: $name';
  }

  @override
  String get versionInfo => 'CricketMate Version 1.0.0';
}
