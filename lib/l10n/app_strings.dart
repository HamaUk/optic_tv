import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// UI strings driven by [locale] from [appLocaleProvider], not [Localizations.localeOf]
/// (MaterialApp stays on English for delegate stability).
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';

  String get loginTitle => isEnglish ? 'Welcome back' : 'بەخێربێیت';
  String get loginSubtitle =>
      isEnglish ? 'Enter your access code to continue' : 'کۆدی دەستپێگەیشتن بنووسە بۆ بەردەوام بوون';
  String get loginHint => '☆☆☆☆☆☆';
  String get loginButton => isEnglish ? 'Continue' : 'بەردەوام بوون';
  String get loginErrorEmpty => isEnglish ? 'Enter a code' : 'کۆد بنووسە';
  String get loginErrorInvalid => isEnglish ? 'Code not recognized' : 'کۆد نەناسراوە';
  String get loginErrorNetwork =>
      isEnglish ? 'Check connection and try again' : 'پەیوەندی بپشکنە و دووبارە هەوڵ بدەوە';

  String get appBrand => 'OPTIC TV';
  String get appTagline => isEnglish ? 'Premium entertainment' : 'کات بەسەری بە باش';
  String get noChannels => isEnglish ? 'No channels yet' : 'هیچ کەناڵێک نییە';
  String get noChannelsHint =>
      isEnglish ? 'They appear when your library syncs.' : 'دوای هاوکاتکردنی پەڕگەکەت دەردەکەون.';
  String get nowPlaying => isEnglish ? 'Featured' : 'تایبەت';
  String get watchNow => isEnglish ? 'Watch' : 'بینین';
  String get channelLoadError => isEnglish ? 'Could not load channels' : 'نەتوانرا کەناڵەکان بخوێنرێتەوە';
  String get settingsTooltip => isEnglish ? 'Settings' : 'ڕێکخستن';

  String get settingsTitle => isEnglish ? 'Settings' : 'ڕێکخستن';
  String get sectionPlayback => isEnglish ? 'Playback' : 'پەخشکردن';
  String get sectionVideo => isEnglish ? 'Video fit' : 'گونجاندنی ڤیدیۆ';
  String get sectionInterface => isEnglish ? 'Interface' : 'ڕووکار';
  String get sectionLanguage => isEnglish ? 'Language' : 'زمان';
  String get sectionAccount => isEnglish ? 'Account' : 'هەژمار';
  String get sectionAbout => isEnglish ? 'About' : 'دەربارە';

  String get keepScreenOnTitle => isEnglish ? 'Keep screen on' : 'شاشەکە بێدەستەوە';
  String get keepScreenOnSub =>
      isEnglish ? 'While video is playing' : 'کاتێک ڤیدیۆ پەخش دەکرێت';
  String get autoHideTitle => isEnglish ? 'Hide controls' : 'شاردنەوەی کۆنترۆڵ';
  String get autoHideSub =>
      isEnglish ? 'Fade player bars; tap to show' : 'شریتی پلەیەر دەشارێتەوە؛ دەست لێ بدە بۆ پیشاندان';
  String get clockTitle => isEnglish ? 'Clock in player' : 'کاتژمێر لە پلەیەر';
  String get clockSub => isEnglish ? 'Time in top bar' : 'کات لە شریتی سەرەوە';
  String get videoFitCaption =>
      isEnglish ? 'How video fills the screen' : 'چۆنیەتی پڕکردنەوەی شاشە بە ڤیدیۆ';
  String get tvLayoutTitle => isEnglish ? 'TV-friendly spacing' : 'بۆشایی گونجاو بۆ تەلەڤیزیۆن';
  String get tvLayoutSub =>
      isEnglish ? 'Larger rows for remote / D-pad' : 'ڕیزە گەورەتر بۆ دوورکەوتنەوە / D-pad';
  String get reduceMotionTitle => isEnglish ? 'Reduce motion' : 'کەمکردنەوەی جوڵە';
  String get reduceMotionSub => isEnglish ? 'Shorter animations' : 'ئەنیمەیشنە کورتەکان';
  String get logoutTitle => isEnglish ? 'Sign out' : 'چوونەدەرەوە';
  String get logoutSub =>
      isEnglish ? 'Clear login on this device' : 'چوونەژوورەوە لەسەر ئەم ئامێرە بسڕەوە';
  String get logoutButton => isEnglish ? 'Sign out' : 'چوونەدەرەوە';

  String get aboutTitle => isEnglish ? 'Optic TV' : 'Optic TV';
  String get aboutSub => isEnglish ? 'Version 1.0.0 · IPTV' : 'وەشان ١٫٠٫٠ · IPTV';

  String get langEnglish => 'English';
  String get langKurdishSorani => 'کوردی (سۆرانی)';

  String get cancel => isEnglish ? 'Cancel' : 'هەڵوەشاندنەوە';
  String get password => isEnglish ? 'Password' : 'وشەی نهێنی';
  String get enter => isEnglish ? 'Enter' : 'چوونەژوورەوە';

  String get fullscreenTooltip => isEnglish ? 'Fullscreen' : 'پڕ بە شاشە';

  String get navHome => isEnglish ? 'Home' : 'سەرەکی';
  String get navMovies => isEnglish ? 'Movies' : 'فیلم';
  String get navSport => isEnglish ? 'Sport' : 'وەرزش';
  String get navFavorites => isEnglish ? 'Favorites' : 'دڵخوازەکان';
  String get navRecent => isEnglish ? 'Recent' : 'دواتر';
  String get searchHint => isEnglish ? 'Search channels…' : 'گەڕان بە کەناڵ…';
  String get categoriesTitle => isEnglish ? 'Categories' : 'پۆلەکان';
  String get channelListTitle => isEnglish ? 'Channel list' : 'لیستی کەناڵەکان';
  String get noChannelsInSection =>
      isEnglish ? 'No channels in this section' : 'لەم بەشەدا کەناڵ نییە';
  String get noFavorites => isEnglish ? 'No favorites yet' : 'هیچ دڵخوازێک نییە';
  String get noFavoritesHint =>
      isEnglish ? 'Long-press a channel on the home grid or tap the star in the player.' : 'کەناڵێک بە درێژی دەست دابگرە لە تۆڕ یان ئەستێرە لە پلەیەر.';
  String get noRecent => isEnglish ? 'Nothing played yet' : 'هیچ شتێک نەبینراوە';
  String get noRecentHint =>
      isEnglish ? 'Channels you open appear here for quick return.' : 'کەناڵەکانی کردووەتەوە لێرە دەردەکەون.';

  String get sectionLibrary => isEnglish ? 'Library' : 'کتێبخانە';
  String get clearFavoritesTitle => isEnglish ? 'Clear favorites' : 'سڕینەوەی دڵخوازەکان';
  String get clearFavoritesSub =>
      isEnglish ? 'Remove all starred channels on this device' : 'هەموو کەناڵە دڵخوازەکان لەسەر ئەم ئامێرە بسڕەوە';
  String get clearRecentTitle => isEnglish ? 'Clear watch history' : 'سڕینەوەی مێژووی بینین';
  String get clearRecentSub =>
      isEnglish ? 'Forget recently opened channels on this device' : 'کەناڵە دواترەکان لەسەر ئەم ئامێرە بسڕەوە';
  String get clearLibraryConfirmBody =>
      isEnglish ? 'This cannot be undone.' : 'ناتوانرێت هەڵوەشێنرێتەوە.';
  String get clearButton => isEnglish ? 'Clear' : 'سڕینەوە';

  String get favoriteChannel => isEnglish ? 'Add to favorites' : 'زیادکردن بۆ دڵخواز';
  String get unfavoriteChannel => isEnglish ? 'Remove from favorites' : 'لابردن لە دڵخواز';
  String get shareChannel => isEnglish ? 'Share link' : 'هاوبەشکردنی بەستەر';

  String fitLabel(BoxFit fit) {
    if (isEnglish) return AppSettingsData.labelForFit(fit);
    return switch (fit) {
      BoxFit.contain => 'تەواو (letterbox)',
      BoxFit.cover => 'داپۆشین (بڕین)',
      BoxFit.fill => 'کێشان',
      BoxFit.fitWidth => 'پانی گونجاو',
      BoxFit.fitHeight => 'درێژی گونجاو',
      BoxFit.scaleDown => 'کەمکردنەوەی قەبارە',
      BoxFit.none => 'هیچ (قەبارەی ڕەسەن)',
    };
  }
}
