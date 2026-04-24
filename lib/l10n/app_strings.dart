import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// UI strings driven by [locale] from [appLocaleProvider], not [Localizations.localeOf]
/// (MaterialApp stays on English for delegate stability).
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';

  String get loginTitle => isEnglish ? 'Welcome back' : 'بەخێربێیتەوە';
  String get loginSubtitle =>
      isEnglish ? 'Enter your access code to continue' : 'تکایە کۆدی چوونەژوورەوە بنووسە بۆ بەردەوامبوون';
  String get loginHint => '☆☆☆☆☆☆';
  String get loginButton => isEnglish ? 'Continue' : 'بەردەوامبە';
  String get loginErrorEmpty => isEnglish ? 'Enter a code' : 'کۆدەکە بنووسە';
  String get loginErrorInvalid => isEnglish ? 'Code not recognized' : 'کۆدەکە هەڵەیە';
  String get loginErrorNetwork =>
      isEnglish ? 'Check connection and try again' : 'پەیوەندی ئینتەرنێت بپشکنە و دووبارە هەوڵبدەوە';

  String get appBrand => 'OPTIC TV';
  String get appTagline => isEnglish ? 'Premium entertainment' : 'جیهانێک لە کاتبەسەربردن';
  String get noChannels => isEnglish ? 'No channels yet' : 'هیچ کەناڵێک بەردەست نییە';
  String get noChannelsHint =>
      isEnglish ? 'They appear when your library syncs.' : 'کەناڵەکان دەردەکەون کاتێک لیستەکەت هاوکات دەکرێت.';
  String get nowPlaying => isEnglish ? 'Featured' : 'جێی سەرنج';
  String get featuredNewHint => isEnglish
      ? 'A new channel is available in your lineup. Tap Watch to start playing.'
      : 'کەناڵێکی نوێ بۆ لیستەکەت زیادکراوە، دەست لە «ببینە» بدە بۆ سەیرکردن.';
  String get watchNow => isEnglish ? 'Watch' : 'ببینە';
  String get channelLoadError => isEnglish ? 'Could not load channels' : 'نەتوانرا کەناڵەکان بخوێنرێتەوە';
  String get settingsTooltip => isEnglish ? 'Settings' : 'ڕێکخستنەکان';

  String get settingsTitle => isEnglish ? 'Settings' : 'ڕێکخستنەکان';
  String get sectionPlayback => isEnglish ? 'Playback' : 'پەخشکردن';
  String get sectionVideo => isEnglish ? 'Video fit' : 'قەبارەی ڤیدیۆ';
  String get sectionInterface => isEnglish ? 'Interface' : 'ڕووکار';
  String get sectionGradientTheme => isEnglish ? 'Theme & backdrop' : 'شێوازی ڕەنگ و پاشبنە';
  String get gradientThemeCaption =>
      isEnglish ? 'Gradient look for dashboard and this screen' : 'شێوازی ڕەنگیزە بۆ داشبۆرد و ئەم شاشەیە';
  String get gradientClassic => isEnglish ? 'Midnight (default)' : 'نیوەشەو (بنەڕەتی)';
  String get gradientOcean => isEnglish ? 'Ocean abyss' : 'قووڵایی ئۆقیانوس';
  String get gradientGold => isEnglish ? 'Gold sunset' : 'ئاسۆیی زێڕین';
  String get gradientViolet => isEnglish ? 'Violet haze' : 'تەمومژی مۆر';
  String get gradientEmber => isEnglish ? 'Ember glow' : 'گەشیی پۆلێتی';
  String get sectionLanguage => isEnglish ? 'Language' : 'زمانەکان';
  String get sectionAccount => isEnglish ? 'Account' : 'هەژمار';
  String get sectionAbout => isEnglish ? 'About' : 'دەربارە';

  String get keepScreenOnTitle => isEnglish ? 'Keep screen on' : 'داگیرساندنی شاشە';
  String get keepScreenOnSub =>
      isEnglish ? 'While video is playing' : 'ڕێگری لە کوژانەوەی شاشە لەکاتی پەخشکردندا';
  String get autoHideTitle => isEnglish ? 'Hide controls' : 'شاردنەوەی دوگمەکان';
  String get autoHideSub =>
      isEnglish ? 'Fade player bars; tap to show' : 'شاردنەوەی شریتی پلەیەر، دەست لێ بدە بۆ پیشاندانەوە';
  String get clockTitle => isEnglish ? 'Clock in player' : 'کاتژمێر لە پلەیەر';
  String get clockSub => isEnglish ? 'Time in top bar' : 'پیشاندانی کات لە شریتی سەرەوە';
  
  String get videoFitCaption =>
      isEnglish ? 'How video fills the screen' : 'چۆنیەتی گونجاندنی ڤیدیۆ لەسەر شاشە';
  String get reduceMotionTitle => isEnglish ? 'Reduce motion' : 'کەمکردنەوەی جوڵە';
  String get reduceMotionSub => isEnglish ? 'Shorter animations' : 'بەکارهێنانی جوڵەی کورتتر';
  String get logoutTitle => isEnglish ? 'Sign out' : 'چوونەدەرەوە';
  String get logoutSub =>
      isEnglish ? 'Clear login on this device' : 'سڕینەوەی هەژمار لەسەر ئەم ئامێرە';
  String get logoutButton => isEnglish ? 'Sign out' : 'چوونەدەرەوە';

  String get aboutTitle => isEnglish ? 'Optic TV' : 'Optic TV';
  String get aboutSub => isEnglish ? 'Version 1.0.0 · IPTV' : 'وەشانی ١.٠.٠ · IPTV';

  String get langEnglish => 'English';
  String get langKurdishSorani => 'کوردی (سۆرانی)';

  String get cancel => isEnglish ? 'Cancel' : 'هەڵوەشاندنەوە';
  String get password => isEnglish ? 'Password' : 'وشەی نهێنی';
  String get enter => isEnglish ? 'Enter' : 'چوونەژوورەوە';

  String get fullscreenTooltip => isEnglish ? 'Fullscreen' : 'پڕ بە شاشە';

  String get navHome => isEnglish ? 'Home' : 'سەرەکی';
  String get navMovies => isEnglish ? 'Movies' : 'فیلمەکان';
  String get navSport => isEnglish ? 'Sport' : 'وەرزش';
  String get navProfile => isEnglish ? 'About' : 'دەربارە';
  String get navFavorites => isEnglish ? 'Favorites' : 'دڵخوازەکانم';
  String get navRecent => isEnglish ? 'Recent' : 'بینراوەکانی دوایی';
  String get searchHint => isEnglish ? 'Search channels…' : 'گەڕان بەدوای کەناڵ...';
  String get categoriesTitle => isEnglish ? 'Categories' : 'هاوپۆلەکان';
  String get channelListTitle => isEnglish ? 'Channel list' : 'لیستی کەناڵەکان';
  String get noChannelsInSection =>
      isEnglish ? 'No channels in this section' : 'هیچ کەناڵێک لەم بەشەدا نییە';
  String get noFavorites => isEnglish ? 'No favorites yet' : 'هیچ دڵخوازێک نییە';
  String get noFavoritesHint =>
      isEnglish ? 'Long-press a channel on the home grid or tap the star in the player.' : 'ئەستێرەی سەر پلەیەرەکە دابگرە بۆ زیادکردنی کەناڵ.';
  String get noRecent => isEnglish ? 'Nothing played yet' : 'هیچ شتێک نەبینراوە';
  String get noRecentHint =>
      isEnglish ? 'Channels you open appear here for quick return.' : 'کەناڵەکان لێرەدا دەردەکەون بۆ بینینەوەی خێرا.';

  String get sectionLibrary => isEnglish ? 'Library' : 'کتێبخانە';
  String get clearFavoritesTitle => isEnglish ? 'Clear favorites' : 'سڕینەوەی دڵخوازەکان';
  String get clearFavoritesSub =>
      isEnglish ? 'Remove all starred channels on this device' : 'سڕینەوەی هەموو کەناڵە دڵخوازەکان';
  String get clearRecentTitle => isEnglish ? 'Clear watch history' : 'سڕینەوەی مێژووی بینین';
  String get clearRecentSub =>
      isEnglish ? 'Forget recently opened channels on this device' : 'سڕینەوەی هەموو کەناڵە بینراوەکان';
  String get clearLibraryConfirmBody =>
      isEnglish ? 'This cannot be undone.' : 'ئەم پڕۆسەیە ناگەڕێتەوە دواوە.';
  String get clearButton => isEnglish ? 'Clear' : 'سڕینەوە';

  String get favoriteChannel => isEnglish ? 'Add to favorites' : 'زیادکردن بۆ دڵخوازەکان';
  String get unfavoriteChannel => isEnglish ? 'Remove from favorites' : 'سڕینەوە لە دڵخوازەکان';

  String fitLabel(BoxFit fit) {
    if (isEnglish) return AppSettingsData.labelForFit(fit);
    return switch (fit) {
      BoxFit.contain => 'تەواو (بە بێ بڕین)',
      BoxFit.cover => 'داپۆشین (بڕینی دەورووبەر)',
      BoxFit.fill => 'پڕکردنەوەی شاشە',
      BoxFit.fitWidth => 'گونجاندن لەگەڵ پانی',
      BoxFit.fitHeight => 'گونجاندن لەگەڵ بەرزی',
      BoxFit.scaleDown => 'پچوکردنەوە',
      BoxFit.none => 'قەبارەی ئەسڵی',
    };
  }
}
