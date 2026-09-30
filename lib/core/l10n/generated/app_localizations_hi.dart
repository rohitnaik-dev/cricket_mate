// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'क्रिकेटमेट';

  @override
  String get sessionsTab => 'सत्र';

  @override
  String get playersTab => 'खिलाड़ी';

  @override
  String get settingsTab => 'सेटिंग्स';

  @override
  String get weatherAttribution => 'मौसम डेटा Open-Meteo.com द्वारा';

  @override
  String get weatherAttributionFull =>
      'Open-Meteo.com (CC BY 4.0) द्वारा प्रदान किया गया मौसम डेटा';

  @override
  String get errorNetworkConnection =>
      'सर्वर से कनेक्ट करने में असमर्थ। कृपया अपना इंटरनेट कनेक्शन जांचें।';

  @override
  String get errorRequestTimeout =>
      'अनुरोध का समय समाप्त हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get errorServer =>
      'सर्वर में कोई त्रुटि आई। कृपया बाद में पुनः प्रयास करें।';

  @override
  String get errorParsingFailed =>
      'सर्वर प्रतिक्रिया डेटा संसाधित करने में विफल।';

  @override
  String get errorGeneric => 'एक अनपेक्षित त्रुटि हुई।';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get searchHint => 'क्रिकेट मैदान या शहर खोजें...';

  @override
  String get searchNoResults => 'कोई क्रिकेट मैदान या शहर नहीं मिला';

  @override
  String get searchPrompt => 'एक क्रिकेट मैदान चुनें';

  @override
  String get searchPromptSubtitle =>
      'मौसम की स्थिति देखने के लिए ऊपर दिए गए खोज बार का उपयोग करके अपने स्थानीय क्रिकेट मैदान या शहर को खोजें।';

  @override
  String get searchLocationButton => 'स्थान खोजें';

  @override
  String get unableToLoadWeather => 'मौसम लोड करने में असमर्थ';

  @override
  String get bestTimeToPlay => 'खेलने का सबसे अच्छा समय';

  @override
  String get viewSessionDetails => 'सत्र का विवरण देखें';

  @override
  String get noViableSessionsTitle => 'कोई सत्र नियोजित नहीं है';

  @override
  String get noViableSessionsSubtitle =>
      'सर्वोत्तम खेलने का समय खोजने के लिए खिलाड़ियों को जोड़ें या मैच सेटिंग्स समायोजित करें।';

  @override
  String get addPlayersButton => 'खिलाड़ी जोड़ें';

  @override
  String get liveForecast => 'लाइव मौसम';

  @override
  String offlineCache(String timeAgo) {
    return 'ऑफ़लाइन ($timeAgo पहले अपडेट किया गया)';
  }

  @override
  String get updating => 'अपडेट हो रहा है...';

  @override
  String get justNow => 'अभी-अभी';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट पहले',
      one: '1 मिनट पहले',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे पहले',
      one: '1 घंटा पहले',
    );
    return '$_temp0';
  }

  @override
  String get otherSessionsTitle => 'अन्य संभावित समय';

  @override
  String rankBadge(int rank) {
    return '#$rank';
  }

  @override
  String get ballTypeLabel => 'गेंद';

  @override
  String get durationLabel => 'अवधि';

  @override
  String get minPlayersLabel => 'न्यूनतम खिलाड़ी';

  @override
  String get sortByLabel => 'क्रमबद्ध करें';

  @override
  String get sortScore => 'सर्वोत्तम स्कोर';

  @override
  String get sortTime => 'सबसे पहला समय';

  @override
  String get sortAttendance => 'अधिकतम उपस्थिति';

  @override
  String get ballTypeTennis => 'टेनिस';

  @override
  String get ballTypeTennisDesc =>
      'मानक हल्की टेनिस गेंद। ओस और हवा के अनुकूल।';

  @override
  String get ballTypeLeather => 'लेदर';

  @override
  String get ballTypeLeatherDesc =>
      'पारंपरिक लाल क्रिकेट गेंद। केवल दिन के प्राकृतिक उजाले में उपयुक्त।';

  @override
  String get ballTypeBox => 'बॉक्स';

  @override
  String get ballTypeBoxDesc => 'बंद टर्फ क्रिकेट गेंद। मौसम प्रतिरोधी।';

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '1 घंटा',
    );
    return '$_temp0';
  }

  @override
  String durationHoursShort(String count) {
    return '$countघं';
  }

  @override
  String get ratingExceptional => 'उत्कृष्ट';

  @override
  String get ratingGreat => 'बहुत अच्छा';

  @override
  String get ratingGood => 'अच्छा';

  @override
  String get ratingFair => 'ठीक-ठाक';

  @override
  String get ratingPoor => 'खराब';

  @override
  String get scoreWeatherLabel => 'मौसम';

  @override
  String get scoreAvailabilityLabel => 'खिलाड़ियों की उपलब्धता';

  @override
  String get scoreConditionsLabel => 'मैदान की स्थिति';

  @override
  String get whyThisTime => 'यह समय क्यों?';

  @override
  String get vetoBannerTitle => 'उच्च जोखिम / निषेध लागू';

  @override
  String get reasonThunderstorm => 'तूफान का खतरा (बिजली गिरने का जोखिम)';

  @override
  String reasonRainRisk(int percent) {
    return 'बारिश की अधिक संभावना ($percent%)';
  }

  @override
  String reasonBelowQuorum(int count, int quorum) {
    return 'न्यूनतम संख्या से कम ($count/$quorum आवश्यक खिलाड़ी)';
  }

  @override
  String get reasonLeatherDaylight =>
      'लेदर बॉल के लिए प्राकृतिक दिन का उजाला आवश्यक है';

  @override
  String get reasonLowRain => 'बारिश की कम संभावना';

  @override
  String get reasonIdealTemp => 'क्रिकेट के लिए आदर्श तापमान';

  @override
  String get reasonChillyTemp => 'ठंडा तापमान';

  @override
  String get reasonGentleBreeze => 'हल्की सुहावनी हवा';

  @override
  String get reasonGustyWind => 'तेज हवा की स्थिति';

  @override
  String reasonWetGround(String mm) {
    return 'रात की बारिश से गीला मैदान ($mm मिमी)';
  }

  @override
  String get reasonDryOutfield => 'सूखा मैदान';

  @override
  String get reasonDewRisk => 'शाम की ओस का खतरा (फिसलन भरी गेंद)';

  @override
  String reasonQuorumReached(int count, int quorum) {
    return 'खिलाड़ियों का कोरम पूरा ($count/$quorum खिलाड़ी)';
  }

  @override
  String get squadAttendanceTitle => 'टीम की उपस्थिति';

  @override
  String confirmedPlayersCount(int count) {
    return 'उपलब्ध ($count)';
  }

  @override
  String missingPlayersCount(int count) {
    return 'अनुपस्थित ($count)';
  }

  @override
  String get allSquadAvailable => 'टीम के सभी सदस्य उपलब्ध हैं!';

  @override
  String get noPlayersAvailable => 'इस समय के लिए कोई खिलाड़ी उपलब्ध नहीं है।';

  @override
  String playerCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खिलाड़ी',
      one: '1 खिलाड़ी',
      zero: 'कोई खिलाड़ी नहीं',
    );
    return '$_temp0';
  }

  @override
  String playersAvailableOutOf(int available, int total) {
    return '$available/$total खिलाड़ी उपलब्ध';
  }

  @override
  String get hourlyConditionsTitle => 'प्रति घंटे की स्थिति';

  @override
  String get hourlyConditionsSubtitle => 'मैच समय ± 2 घंटे';

  @override
  String get legendRainProb => 'बारिश %';

  @override
  String get legendTemperature => 'तापमान (°C)';

  @override
  String get legendSunset => 'सूर्यास्त';

  @override
  String get legendMatchWindow => 'मैच समय';

  @override
  String get shareInviteButton => 'व्हाट्सएप पर आमंत्रण साझा करें';

  @override
  String get shareInviteTooltip => 'आमंत्रण साझा करें';

  @override
  String get inviteTitle => '🏏 *क्रिकेट मैच आमंत्रण*';

  @override
  String get inviteVenue => '📍 *स्थान:*';

  @override
  String get inviteDate => '📅 *तारीख:*';

  @override
  String get inviteTime => '⏰ *समय:*';

  @override
  String get inviteBall => '🏏 *गेंद:*';

  @override
  String get inviteScore => '⭐ *सत्र स्कोर:*';

  @override
  String get inviteKeyReasons => '📋 *मुख्य स्थितियां:*';

  @override
  String get inviteConfirmedLineup => '👥 *उपलब्ध खिलाड़ी:*';

  @override
  String get inviteFooter =>
      'आइए क्रिकेट खेलें! क्रिकेटमेट के माध्यम से निर्धारित।';

  @override
  String get squadScreenTitle => 'टीम और उपलब्धता';

  @override
  String get addPlayerTooltip => 'खिलाड़ी जोड़ें';

  @override
  String get addPlayerButton => 'खिलाड़ी जोड़ें';

  @override
  String get addFirstPlayerButton => 'पहला खिलाड़ी जोड़ें';

  @override
  String get noPlayersYetTitle => 'अभी तक कोई खिलाड़ी नहीं जोड़ा गया';

  @override
  String get noPlayersYetSubtitle =>
      'सर्वोत्तम मैच समय खोजने के लिए अपनी क्रिकेट टीम के सदस्यों को जोड़ें।';

  @override
  String get bestSquadOverlap => 'सर्वश्रेष्ठ टीम ओवरलैप';

  @override
  String get today => 'आज';

  @override
  String get tomorrow => 'कल';

  @override
  String get tomorrowShort => 'कल';

  @override
  String get noCommonOverlap => 'कोई सामान्य समय नहीं मिला';

  @override
  String get noCommonOverlapSubtitle =>
      'मैच का समय निकालने के लिए खिलाड़ियों की उपलब्धता समायोजित करें।';

  @override
  String get addPlayersToCalculate => 'ओवरलैप की गणना के लिए खिलाड़ी जोड़ें';

  @override
  String editAvailabilityTooltip(String name) {
    return '$name की उपलब्धता संपादित करें';
  }

  @override
  String removePlayerTooltip(String name) {
    return '$name को हटाएं';
  }

  @override
  String get noSlotsScheduled => 'कोई समय निर्धारित नहीं';

  @override
  String playerRemovedSnackbar(String name) {
    return 'खिलाड़ी $name को हटाया गया';
  }

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get addPlayerDialogTitle => 'खिलाड़ी जोड़ें';

  @override
  String get playerNameLabel => 'खिलाड़ी का नाम';

  @override
  String get playerNameHint => 'उदा. विराट कोहली';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get nameCannotBeEmpty => 'खिलाड़ी का नाम खाली नहीं हो सकता';

  @override
  String get nameAlreadyExists => 'इस नाम का खिलाड़ी पहले से मौजूद है';

  @override
  String get nameTooLong => 'नाम 50 अक्षरों से अधिक नहीं हो सकता';

  @override
  String get editAvailabilityTitle => 'उपलब्धता संपादित करें';

  @override
  String get quickPresetsTitle => 'त्वरित प्रीसेट (जोड़ने के लिए टैप करें)';

  @override
  String get presetEvening => 'शाम 5-8';

  @override
  String get presetWeekendMorning => 'वीकेंड सुबह';

  @override
  String get presetMorning => 'सुबह 7-10';

  @override
  String get presetAfternoon => 'दोपहर 2-5';

  @override
  String get customRangeTitle => 'कस्टम समय चुनें (30-मिनट चरण)';

  @override
  String get startTimeLabel => 'प्रारंभ समय';

  @override
  String get endTimeLabel => 'समाप्ति समय';

  @override
  String get addSlotButton => 'समय स्लॉट जोड़ें';

  @override
  String scheduledSlotsTitle(String day) {
    return '$day के लिए निर्धारित स्लॉट';
  }

  @override
  String get noSlotsForDay => 'इस दिन के लिए अभी कोई स्लॉट निर्धारित नहीं है।';

  @override
  String get saveAvailabilityButton => 'उपलब्धता सहेजें';

  @override
  String get slotEndMustBeAfterStart =>
      'समाप्ति समय प्रारंभ समय के बाद होना चाहिए';

  @override
  String get midnight => 'मध्यरात्रि (12:00 AM)';

  @override
  String get settingsScreenTitle => 'सेटिंग्स और प्राथमिकताएं';

  @override
  String get matchSettingsSection => 'मैच प्राथमिकताएं';

  @override
  String get defaultBallType => 'डिफ़ॉल्ट गेंद का प्रकार';

  @override
  String get defaultDuration => 'डिफ़ॉल्ट मैच अवधि';

  @override
  String get squadQuorum => 'न्यूनतम टीम कोरम';

  @override
  String quorumDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'वैध सत्र के लिए $count खिलाड़ी आवश्यक',
      one: 'वैध सत्र के लिए 1 खिलाड़ी आवश्यक',
    );
    return '$_temp0';
  }

  @override
  String get appPreferencesSection => 'ऐप प्राथमिकताएं';

  @override
  String get appTheme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get appLanguage => 'भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get aboutSection => 'ऐप के बारे में और डेटा स्रोत';

  @override
  String get dataAttribution => 'डेटा श्रेय';

  @override
  String get dataAttributionSubtitle =>
      'मौसम डेटा Open-Meteo.com द्वारा CC BY 4.0 लाइसेंस के तहत प्रदान किया गया';

  @override
  String get openMeteoWebsite => 'Open-Meteo.com';

  @override
  String get homePitch => 'डिफ़ॉल्ट मैदान / स्थान';

  @override
  String homePitchSubtitle(String name) {
    return 'वर्तमान स्थान: $name';
  }

  @override
  String get versionInfo => 'क्रिकेटमेट संस्करण 1.0.0';
}
