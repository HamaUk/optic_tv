import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// UI strings driven by [locale] from [appLocaleProvider], not [Localizations.localeOf]
/// (MaterialApp stays on English for delegate stability).
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';
  bool get isKurmanji => locale.languageCode == 'kmr';
  bool get isSorani => locale.languageCode == 'ckb' || (!isEnglish && !isKurmanji);

  String get loginTitle {
    if (isKurmanji) return 'Bi xêr hatî';
    if (isSorani) return 'بەخێربێیت';
    return 'Welcome';
  }

  String get loginSubtitle {
    if (isKurmanji) return 'Ji kerema xwe koda xwe binivîse da ku berdewam bikî';
    if (isSorani) return 'تکایە کۆدی چوونەژوورەوە بنووسە بۆ بەردەوامبوون';
    return 'Enter your access code to continue';
  }

  String get loginHint => '☆☆☆☆☆☆';

  String get loginButton {
    if (isKurmanji) return 'Berdewam bike';
    if (isSorani) return 'بەردەوامبە';
    return 'Continue';
  }

  String get loginErrorEmpty {
    if (isKurmanji) return 'Kodê binivîse';
    if (isSorani) return 'کۆدەکە بنووسە';
    return 'Enter a code';
  }

  String get loginErrorInvalid {
    if (isKurmanji) return 'Kod nehat nasîn';
    if (isSorani) return 'کۆدەکە هەڵەیە';
    return 'Code not recognized';
  }

  String get loginErrorNetwork {
    if (isKurmanji) return 'Têkiliya înternetê kontrol bike û dîsa biceribîne';
    if (isSorani) return 'پەیوەندی ئینتەرنێت بپشکنە و دووبارە هەوڵبدەوە';
    return 'Check connection and try again';
  }

  String get appBrand => 'KOBANI 4K';

  String get appTagline {
    if (isKurmanji) return 'Cîhanek ji kêf û wext derbaskirinê';
    if (isSorani) return 'جیهانێک لە کاتبەسەربردن';
    return 'Premium entertainment';
  }

  String get noChannels {
    if (isKurmanji) return 'Hêj qenal nînin';
    if (isSorani) return 'هیچ کەناڵێک بەردەست نییە';
    return 'No channels yet';
  }

  String get noChannelsHint {
    if (isKurmanji) return 'Gava lîsteya te tê hevdeng kirin ew ê xuya bibin.';
    if (isSorani) return 'کەناڵەکان دەردەکەون کاتێک لیستەکەت هاوکات دەکرێت.';
    return 'They appear when your library syncs.';
  }

  String get nowPlaying {
    if (isKurmanji) return 'Pêşniyarkirî';
    if (isSorani) return 'جێی سەرنج';
    return 'Featured';
  }

  String get featuredNewHint {
    if (isKurmanji) return 'Qenalek nû li lîsteya te hat zêdekirin. Dest bide "Temaşe bike".';
    if (isSorani) return 'کەناڵێکی نوێ بۆ لیستەکەت زیادکراوە، دەست لە «ببینە» بدە بۆ سەیرکردن.';
    return 'A new channel is available in your lineup. Tap Watch to start playing.';
  }

  String get watchNow {
    if (isKurmanji) return 'Temaşe bike';
    if (isSorani) return 'ببینە';
    return 'Watch';
  }

  String get channelLoadError {
    if (isKurmanji) return 'Qenal nehatin xwendin';
    if (isSorani) return 'نەتوانرا کەناڵەکان بخوێنرێتەوە';
    return 'Could not load channels';
  }

  String get settingsTooltip {
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'ڕێکخستنەکان';
    return 'Settings';
  }

  String get settingsTitle {
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'ڕێکخستنەکان';
    return 'Settings';
  }

  String get sectionPlayback {
    if (isKurmanji) return 'Lêdan';
    if (isSorani) return 'پەخشکردن';
    return 'Playback';
  }

  String get sectionVideo {
    if (isKurmanji) return 'Mezinahiya Vîdyoyê';
    if (isSorani) return 'قەبارەی ڤیدیۆ';
    return 'Video fit';
  }

  String get sectionInterface {
    if (isKurmanji) return 'Rûkar';
    if (isSorani) return 'ڕووکار';
    return 'Interface';
  }

  String get sectionGradientTheme {
    if (isKurmanji) return 'Reng û Paşxane';
    if (isSorani) return 'شێوازی ڕەنگ و پاشبنە';
    return 'Theme & backdrop';
  }

  String get gradientThemeCaption {
    if (isKurmanji) return 'Rengên ji bo dashboard û vê rûpelê';
    if (isSorani) return 'شێوازی ڕەنگیزە بۆ داشبۆرد و ئەم شاشەیە';
    return 'Gradient look for dashboard and this screen';
  }

  String get gradientClassic {
    if (isKurmanji) return 'Nîvê Şevê';
    if (isSorani) return 'نیوەشەو';
    return 'Midnight';
  }

  String get gradientOcean {
    if (isKurmanji) return 'Kûrahiya Okyanûsê';
    if (isSorani) return 'قووڵایی ئۆقیانوس';
    return 'Ocean abyss';
  }

  String get gradientGold {
    if (isKurmanji) return 'Zêrîn';
    if (isSorani) return 'ئاسۆیی زێڕین';
    return 'Gold sunset';
  }

  String get gradientViolet {
    if (isKurmanji) return 'Mijê Mor';
    if (isSorani) return 'تەمومژی مۆر';
    return 'Violet haze';
  }

  String get gradientEmber {
    if (isKurmanji) return 'Gêla Pêtê (Bingehan)';
    if (isSorani) return 'گەشیی پۆلێتی (بنەڕەتی)';
    return 'Ember glow (default)';
  }

  String get sectionLanguage {
    if (isKurmanji) return 'Ziman';
    if (isSorani) return 'زمانەکان';
    return 'Language';
  }

  String get sectionAccount {
    if (isKurmanji) return 'Hesab';
    if (isSorani) return 'هەژمار';
    return 'Account';
  }

  String get sectionAbout {
    if (isKurmanji) return 'Derbar';
    if (isSorani) return 'دەربارە';
    return 'About';
  }

  String get keepScreenOnTitle {
    if (isKurmanji) return 'Dîmender ronî bihêle';
    if (isSorani) return 'داگیرساندنی شاشە';
    return 'Keep screen on';
  }

  String get keepScreenOnSub {
    if (isKurmanji) return 'Dema vîdyo tê lêdan';
    if (isSorani) return 'ڕێگری لە کوژانەوەی شاشە لەکاتی پەخشکردندا';
    return 'While video is playing';
  }

  String get autoHideTitle {
    if (isKurmanji) return 'Bikojkan veşêre';
    if (isSorani) return 'شاردنەوەی دوگمەکان';
    return 'Hide controls';
  }

  String get autoHideSub {
    if (isKurmanji) return 'Bi dest lêdanê dubare nîşan bide';
    if (isSorani) return 'شاردنەوەی شریتی پلەیەر، دەست لێ بدە بۆ پیشاندانەوە';
    return 'Fade player bars; tap to show';
  }

  String get clockTitle {
    if (isKurmanji) return 'Demjimêr di lîstikvanê de';
    if (isSorani) return 'کاتژمێر لە پلەیەر';
    return 'Clock in player';
  }

  String get clockSub {
    if (isKurmanji) return 'Dema lîstikvan nîşan bide';
    if (isSorani) return 'پیشاندانی کات لە شریتی سەرەوە';
    return 'Time in top bar';
  }

  String get videoFitCaption {
    if (isKurmanji) return 'Çawa vîdyo li ser ekranê rûne';
    if (isSorani) return 'چۆنیەتی گونجاندنی ڤیدیۆ لەسەر شاشە';
    return 'How video fills the screen';
  }

  String get reduceMotionTitle {
    if (isKurmanji) return 'Tevgeran kêm bike';
    if (isSorani) return 'کەمکردنەوەی جوڵە';
    return 'Reduce motion';
  }

  String get reduceMotionSub {
    if (isKurmanji) return 'Anîmasyonên kurtir';
    if (isSorani) return 'بەکارهێنانی جوڵەی کورتتر';
    return 'Shorter animations';
  }

  String get logoutTitle {
    if (isKurmanji) return 'Derkeve';
    if (isSorani) return 'چوونەدەرەوە';
    return 'Sign out';
  }

  String get logoutSub {
    if (isKurmanji) return 'Hesabê xwe ji vî cîhazî rakin';
    if (isSorani) return 'سڕینەوەی هەژمار لەسەر ئەم ئامێرە';
    return 'Clear login on this device';
  }

  String get logoutButton {
    if (isKurmanji) return 'Derkeve';
    if (isSorani) return 'چوونەدەرەوە';
    return 'Sign out';
  }

  String get aboutTitle => 'KOBANI 4K';

  String get aboutSub {
    if (isKurmanji) return 'Guherto 1.2.0 · IPTV';
    if (isSorani) return 'وەشانی ١.٢.٠ · IPTV';
    return 'Version 1.2.0 · IPTV';
  }

  String get langEnglish => 'English';
  String get langKurdishSorani => 'کوردی (سۆرانی)';
  String get langKurdishKurmanji => 'Kurdî (Kurmancî)';

  String get cancel {
    if (isKurmanji) return 'Betal bike';
    if (isSorani) return 'هەڵوەشاندنەوە';
    return 'Cancel';
  }

  String get password {
    if (isKurmanji) return 'Şîfre';
    if (isSorani) return 'وشەی نهێنی';
    return 'Password';
  }

  String get enter {
    if (isKurmanji) return 'Têkeve';
    if (isSorani) return 'چوونەژوورەوە';
    return 'Enter';
  }

  String get fullscreenTooltip {
    if (isKurmanji) return 'Ekrana tije';
    if (isSorani) return 'پڕ بە شاشە';
    return 'Fullscreen';
  }

  String get navHome {
    if (isKurmanji) return 'Mal';
    if (isSorani) return 'سەرەکی';
    return 'Home';
  }

  String get navMovies {
    if (isKurmanji) return 'Fîlm';
    if (isSorani) return 'فیلمەکان';
    return 'Movies';
  }

  String get navSport {
    if (isKurmanji) return 'Spor';
    if (isSorani) return 'وەرزش';
    return 'Sport';
  }

  String get navWorldCup {
    if (isKurmanji) return 'Kûpaya Cîhanê 26';
    if (isSorani) return 'مۆندیالی ٢٠٢٦';
    return 'World Cup 26';
  }

  String get navProfile {
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'ڕێکخستنەکان';
    return 'Settings';
  }

  String get navFavorites {
    if (isKurmanji) return 'Bijare';
    if (isSorani) return 'دڵخوازەکانم';
    return 'Favorites';
  }

  String get navRecent {
    if (isKurmanji) return 'Dîtî';
    if (isSorani) return 'بینراوەکانی دوایی';
    return 'Recent';
  }

  String get searchHint {
    if (isKurmanji) return 'Lêgerîn li qenalan...';
    if (isSorani) return 'گەڕان بەدوای کەناڵ...';
    return 'Search channels…';
  }

  String get categoriesTitle {
    if (isKurmanji) return 'Kategorî';
    if (isSorani) return 'هاوپۆلەکان';
    return 'Categories';
  }

  String get channelListTitle {
    if (isKurmanji) return 'Lîsteya Qenalan';
    if (isSorani) return 'لیستی کەناڵەکان';
    return 'Channel list';
  }

  String get noChannelsInSection {
    if (isKurmanji) return 'Qenal li vê beşê nînin';
    if (isSorani) return 'هیچ کەناڵێک لەم بەشەدا نییە';
    return 'No channels in this section';
  }

  String get noFavorites {
    if (isKurmanji) return 'Hêj bijare nînin';
    if (isSorani) return 'هیچ دڵخوازێک نییە';
    return 'No favorites yet';
  }

  String get noFavoritesHint {
    if (isKurmanji) return 'Ji bo zêdekirinê, pêl stêrkê bike.';
    if (isSorani) return 'ئەستێرەی سەر پلەیەرەکە دابگرە بۆ زیادکردنی کەناڵ.';
    return 'Long-press a channel on the home grid or tap the star in the player.';
  }

  String get noRecent {
    if (isKurmanji) return 'Hêj tiştek nehatiye lîstin';
    if (isSorani) return 'هیچ شتێک نەبینراوە';
    return 'Nothing played yet';
  }

  String get noRecentHint {
    if (isKurmanji) return 'Qenalên te li vir xuya dibin.';
    if (isSorani) return 'کەناڵەکان لێرەدا دەردەکەون بۆ بینینەوەی خێرا.';
    return 'Channels you open appear here for quick return.';
  }

  String get sectionLibrary {
    if (isKurmanji) return 'Pirtûkxane';
    if (isSorani) return 'کتێبخانە';
    return 'Library';
  }

  String get clearFavoritesTitle {
    if (isKurmanji) return 'Bijareyan Paqij bike';
    if (isSorani) return 'سڕینەوەی دڵخوازەکان';
    return 'Clear favorites';
  }

  String get clearFavoritesSub {
    if (isKurmanji) return 'Hemû qenalên bijare jê bibe';
    if (isSorani) return 'سڕینەوەی هەموو کەناڵە دڵخوازەکان';
    return 'Remove all starred channels on this device';
  }

  String get clearRecentTitle {
    if (isKurmanji) return 'Dîrokê Paqij bike';
    if (isSorani) return 'سڕینەوەی مێژووی بینین';
    return 'Clear watch history';
  }

  String get clearRecentSub {
    if (isKurmanji) return 'Hemû qenalên dîtî jê bibe';
    if (isSorani) return 'سڕینەوەی هەموو کەناڵە بینراوەکان';
    return 'Forget recently opened channels on this device';
  }

  String get clearLibraryConfirmBody {
    if (isKurmanji) return 'Ev nayê betalkirin.';
    if (isSorani) return 'ئەم پڕۆسەیە ناگەڕێتەوە دواوە.';
    return 'This cannot be undone.';
  }

  String get clearButton {
    if (isKurmanji) return 'Paqij bike';
    if (isSorani) return 'سڕینەوە';
    return 'Clear';
  }

  String get favoriteChannel {
    if (isKurmanji) return 'Zêdeyî bijareyan bike';
    if (isSorani) return 'زیادکردن بۆ دڵخوازەکان';
    return 'Add to favorites';
  }

  String get unfavoriteChannel {
    if (isKurmanji) return 'Ji bijareyan derxîne';
    if (isSorani) return 'سڕینەوە لە دڵخوازەکان';
    return 'Remove from favorites';
  }

  String fitLabel(BoxFit fit) {
    if (isKurmanji) {
      return switch (fit) {
        BoxFit.contain => 'Tijî (Bê birîn)',
        BoxFit.cover => 'Rûpoş (Derdor birîn)',
        BoxFit.fill => 'Tije bike',
        BoxFit.fitWidth => 'Bi firehiyê re hevaheng bike',
        BoxFit.fitHeight => 'Bi bilindiyê re hevaheng bike',
        BoxFit.scaleDown => 'Biçûk bike',
        BoxFit.none => 'Mezinahiya rastîn',
      };
    }
    if (isSorani) {
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
    return AppSettingsData.labelForFit(fit);
  }
}
