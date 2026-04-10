import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// UI strings — Kurdish Sorani is default ([locale] `ckb`).
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';

  String get loginTitle => isEnglish ? 'Welcome back' : 'بەخێربێیت';
  String get loginSubtitle =>
      isEnglish ? 'Enter your access code to continue' : 'کۆدی دەستپێگەیشتن بنووسە بۆ بەردەوامبوون';
  String get loginHint => isEnglish ? 'Code (letters or numbers)' : 'کۆد (پیت یان ژمارە)';
  String get loginButton => isEnglish ? 'Continue' : 'بەرەو پێشەوە';
  String get loginErrorEmpty => isEnglish ? 'Enter a code' : 'تکایە کۆدێک بنووسە';
  String get loginErrorInvalid =>
      isEnglish ? 'Code not recognized' : 'کۆدەکە نەناسراوە';
  String get loginErrorNetwork =>
      isEnglish ? 'Check connection and try again' : 'پەیوەندی ئینتەرنێت بپشکنە';

  String get appBrand => isEnglish ? 'OPTIC TV' : 'ئۆptic TV';
  String get appTagline => isEnglish ? 'Premium entertainment' : 'ڤیدیۆی بەرز';
  String get noChannels => isEnglish ? 'No channels yet' : 'هیچ کەناڵێک نییە';
  String get noChannelsHint =>
      isEnglish ? 'They appear when your library syncs.' : 'دوای هاوکاتبوون دەردەکەون.';
  String get nowPlaying => isEnglish ? 'Featured' : 'ئێستا';
  String get watchNow => isEnglish ? 'Watch' : 'سەیر بکە';
  String get channelLoadError => isEnglish ? 'Could not load channels' : 'کەناڵەکان نەهاتن';
  String get settingsTooltip => isEnglish ? 'Settings' : 'ڕێکخستنەکان';

  String get settingsTitle => isEnglish ? 'Settings' : 'ڕێکخستنەکان';
  String get sectionPlayback => isEnglish ? 'Playback' : 'پەخشکردن';
  String get sectionVideo => isEnglish ? 'Video fit' : 'قەبارەی وێنە';
  String get sectionInterface => isEnglish ? 'Interface' : 'ڕووکار';
  String get sectionAccount => isEnglish ? 'Account' : 'هەژمار';
  String get sectionAbout => isEnglish ? 'About' : 'دەربارە';

  String get keepScreenOnTitle =>
      isEnglish ? 'Keep screen on' : 'شاشەکە بێدەنگ مەکە';
  String get keepScreenOnSub =>
      isEnglish ? 'While video is playing' : 'لە کاتی پەخشدا';
  String get autoHideTitle => isEnglish ? 'Hide controls' : 'شاردنەوەی کۆنتڕۆڵ';
  String get autoHideSub =>
      isEnglish ? 'Fade player bars; tap to show' : 'شریتی کۆنتڕۆڵ شارەوە؛ دەست لێدانی شاشە';
  String get clockTitle => isEnglish ? 'Clock in player' : 'کاتژمێر لە پلەیەر';
  String get clockSub => isEnglish ? 'Time in top bar' : 'کات لە سەرەوە';
  String get videoFitCaption =>
      isEnglish ? 'How video fills the screen' : 'چۆنیەتی پڕبوونی شاشە';
  String get languageTitle => isEnglish ? 'Language' : 'زمان';
  String get languageCkb => 'کوردی (سۆرانی)';
  String get languageEn => 'English';
  String get tvLayoutTitle =>
      isEnglish ? 'TV-friendly spacing' : 'بۆ تەلەڤزیۆن گونجاو';
  String get tvLayoutSub =>
      isEnglish ? 'Larger rows for remote / D-pad' : 'ڕیزە گەورەتر بۆ کۆنترۆڵی دوور';
  String get reduceMotionTitle =>
      isEnglish ? 'Reduce motion' : 'کەمکردنەوەی جوڵە';
  String get reduceMotionSub =>
      isEnglish ? 'Shorter animations' : 'ئەنیمەیشن کورتتر';
  String get logoutTitle => isEnglish ? 'Sign out' : 'دەرچوون';
  String get logoutSub =>
      isEnglish ? 'Clear login on this device' : 'چوونەژوورەوە بسڕەوە لەم ئامێرە';
  String get logoutButton => isEnglish ? 'Sign out' : 'دەرچوون';

  String get aboutTitle => isEnglish ? 'Optic TV' : 'ئۆptic TV';
  String get aboutSub =>
      isEnglish ? 'Version 1.0.0 · IPTV' : 'وەشان ١.٠.٠ · تیڤی ئینتەرنێت';

  String fitLabel(BoxFit fit) {
    if (isEnglish) return AppSettingsData.labelForFit(fit);
    return switch (fit) {
      BoxFit.contain => 'تەواو (لێتر بۆکس)',
      BoxFit.cover => 'پڕ (بڕین)',
      BoxFit.fill => 'کشاندن',
      BoxFit.fitWidth => 'پانی شاشە',
      BoxFit.fitHeight => 'بەرزی شاشە',
      BoxFit.scaleDown => 'بچوککردنەوە',
      BoxFit.none => 'قەبارەی رەسەن',
    };
  }

  String get fullscreenTooltip => isEnglish ? 'Fullscreen' : 'پڕی شاشە';

  String get navHome => isEnglish ? 'Home' : 'سەرەکی';
  String get navMovies => isEnglish ? 'Movies' : 'فیلم';
  String get navSport => isEnglish ? 'Sport' : 'وەرزش';
  String get searchHint => isEnglish ? 'Search channels…' : 'گەڕان بە کەناڵ…';
  String get filterAll => isEnglish ? 'All' : 'هەموو';
  String get categoriesTitle => isEnglish ? 'Categories' : 'هاوپۆلەکان';
  String get channelListTitle => isEnglish ? 'Channel list' : 'لیستی کەناڵەکان';
  String get noChannelsInSection =>
      isEnglish ? 'No channels in this section' : 'لەم بەشەدا کەناڵ نییە';
}
