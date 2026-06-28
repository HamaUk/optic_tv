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

  String serverName(int number) {
    if (isKurmanji) return 'PÊŞKÊŞKER $number';
    if (isSorani) return 'سێرڤەری $number';
    return 'SERVER $number';
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
  String get sectionStorage {
    if (isKurmanji) return 'Bîrge û Kaş';
    if (isSorani) return 'بیرگە و کاش';
    return 'Storage & Cache';
  }

  String get storagePosters {
    if (isKurmanji) return 'Posterên Fîlm û Rêzefîlman';
    if (isSorani) return 'پۆستەری فیلم و زنجیرەکان';
    return 'Movie & Series Posters';
  }

  String get storageEpg {
    if (isKurmanji) return 'Daneyên Rêberê TV EPG';
    if (isSorani) return 'داتای ڕێبەری تەلەفزیۆنی EPG';
    return 'EPG TV Guide Data';
  }

  String get storageLogs {
    if (isKurmanji) return 'Daneyên Demkî û Log';
    if (isSorani) return 'داتای کاتی و لۆگەکان';
    return 'Temporary Logs & Data';
  }

  String get calculating {
    if (isKurmanji) return 'Tê hesibandin...';
    if (isSorani) return 'لە هەژمارکردندایە...';
    return 'Calculating...';
  }

  String get sectionSubtitles {
    if (isKurmanji) return 'Vebijarkên Binnivîsê (VOD)';
    if (isSorani) return 'هەڵبژاردەکانی ژێرنووس (VOD)';
    return 'Subtitle Preferences (VOD)';
  }

  String get subtitleCaption {
    if (isKurmanji) return 'Xuyabûna binnivîsan di fîlm û rêzefîlman de sererast bike';
    if (isSorani) return 'شێوازی دەرکەوتنی ژێرنووس لە فیلم و زنجیرەکاندا ڕێکبخە';
    return 'Customize how subtitles look in movies and series';
  }

  String get subtitleFontSize {
    if (isKurmanji) return 'Mezinahiya Fontê';
    if (isSorani) return 'قەبارەی فۆنت';
    return 'Font Size';
  }

  String get subtitleColor {
    if (isKurmanji) return 'Rengê Nivîsê';
    if (isSorani) return 'ڕەنگی دەق';
    return 'Text Color';
  }

  String get subtitleBgOpacity {
    if (isKurmanji) return 'Tîrêjiya Paşxanê';
    if (isSorani) return 'ڕوونی پاشبنە';
    return 'Background Opacity';
  }

  String get subtitleBgOff {
    if (isKurmanji) return 'Girtî';
    if (isSorani) return 'کوژاوە';
    return 'Off';
  }

  String get subtitleBgSemi {
    return '45%';
  }

  String get subtitleBgSolid {
    if (isKurmanji) return 'Tîr';
    if (isSorani) return 'تۆخ';
    return 'Solid';
  }

  String get subtitleSample {
    if (isKurmanji) return 'Mînaka Nivîsa Binnivîsê';
    if (isSorani) return 'نموونەی دەقی ژێرنووس';
    return 'Sample Subtitle Text';
  }

  String get sectionPlaybackNetwork {
    if (isKurmanji) return 'Lêdan û Înternet';
    if (isSorani) return 'پەخشکردن و ئینتەرنێت';
    return 'Playback & Network';
  }

  String get hardwareAccel {
    if (isKurmanji) return 'Lezkirina Hardware';
    if (isSorani) return 'خێراکردنی ڕەقەکاڵا';
    return 'Hardware Acceleration';
  }

  String get hardwareAccelSub {
    if (isKurmanji) return 'Dekodkirina hardware bi kar bîne (ji bo çareserkirina sekinînê di cîhazên kevn de bigire)';
    if (isSorani) return 'بەکارهێنانی دیـکۆدینگی ڕەقەکاڵا (بیکوژێنەوە بۆ چارەسەری وەستان لە ئامێرە کۆنەکاندا)';
    return 'Use hardware decoding (turn off to fix stuttering on older devices)';
  }

  String get dataSaver {
    if (isKurmanji) return 'Moda Parastina Daneyê';
    if (isSorani) return 'مۆدی پاشەکەوتکردنی داتا';
    return 'Data Saver Mode';
  }

  String get dataSaverSub {
    if (isKurmanji) return 'Bi awayekî otomatîk daxwaza weşanên qalîteya nizm li ser torên mobîl dike';
    if (isSorani) return 'بەشێوەیەکی ئۆتۆماتیکی داوای کوالێتی نزمتر دەکات لەسەر تۆڕەکانی مۆبایل';
    return 'Automatically request lower quality streams on mobile networks';
  }

  String get sectionDiagnostics {
    if (isKurmanji) return 'Kontrola Cîhaz û Torê';
    if (isSorani) return 'پشکنینی ئامێر و ئینتەرنێت';
    return 'Device & Network Diagnostics';
  }

  String get displayOutput {
    if (isKurmanji) return 'Derketina Dîmenderê';
    if (isSorani) return 'دەرچەی شاشە';
    return 'Display Output';
  }

  String get display4k {
    if (isKurmanji) return 'Piştgiriya 4K Ultra HD dike';
    if (isSorani) return 'پشتگیری 4K Ultra HD دەکات';
    return '4K Ultra HD Capable';
  }

  String get display1080p {
    return '1080p Full HD';
  }

  String get display720p {
    return '720p HD Ready';
  }

  String get speedTest {
    if (isKurmanji) return 'Testa Leza Înternetê';
    if (isSorani) return 'پشکنینی خێرایی ئینتەرنێت';
    return 'Internet Speed Test';
  }

  String get speedTestSub {
    if (isKurmanji) return 'Leza girêdana xwe ji bo weşana 4K/HD biceribîne';
    if (isSorani) return 'خێرایی ئینتەرنێتەکەت بپشکنە بۆ پەخشی 4K/HD';
    return 'Test your connection speed for 4K/HD streaming';
  }

  String speedTestResult(String speed) {
    if (isKurmanji) return 'Encama dawî: $speed Mbps';
    if (isSorani) return 'کۆتا ئەنجام: $speed مێگابایت';
    return 'Last result: $speed Mbps';
  }

  String get runTest {
    if (isKurmanji) return 'TEST BIKIN';
    if (isSorani) return 'پشکنین بکە';
    return 'RUN TEST';
  }

  String get sectionSupport {
    if (isKurmanji) return 'Piştgirî û Nûvekirin';
    if (isSorani) return 'پشتگیری و نوێکردنەوەکان';
    return 'Support & Updates';
  }

  String get checkUpdates {
    if (isKurmanji) return 'Kontrola Nûvekirinê';
    if (isSorani) return 'پشکنین بۆ نوێکردنەوە';
    return 'Check for Updates';
  }

  String get checkUpdatesSub {
    if (isKurmanji) return 'Piştrast be ku taybetmendiyên herî nû li cem te ne';
    if (isSorani) return 'دڵنیابە لەوەی نوێترین تایبەتمەندییەکانت هەیە';
    return 'Ensure you have the latest features';
  }

  String get joinTelegram {
    if (isKurmanji) return 'Tevlî Telegrama me bibe';
    if (isSorani) return 'بەشداربە لە تێلیگرامەکەمان';
    return 'Join our Telegram';
  }

  String get joinTelegramSub {
    if (isKurmanji) return 'Piştgirî û nûçeyên herî nû bistîne';
    if (isSorani) return 'پشتگیری و نوێترین هەواڵەکان وەربگرە';
    return 'Get support and latest news';
  }

  String get whatsNew {
    if (isKurmanji) return 'Çi Nû ye?';
    if (isSorani) return 'چی نوێیە؟';
    return 'What\'s New?';
  }

  String get whatsNewKurdish {
    if (isKurmanji) return 'Wergerê Kurdî';
    if (isSorani) return 'وەرگێڕی کوردی';
    return 'Kurdish Translator';
  }

  String get whatsNewKurdishSub {
    if (isKurmanji) return 'Piştgiriya tam a Kurdiya Kurmancî hat zêdekirin';
    if (isSorani) return 'پشتگیری تەواوی کوردی کرمانجی زیادکرا';
    return 'Added full Kurdish Kurmanji support';
  }

  String get whatsNewDataSaver {
    if (isKurmanji) return 'Parastina Daneyê';
    if (isSorani) return 'پاشەکەوتکردنی داتا';
    return 'Data Saver';
  }

  String get whatsNewDataSaverSub {
    if (isKurmanji) return 'Parastina înternetê li ser torên mobîl';
    if (isSorani) return 'پاشەکەوتکردنی ئینتەرنێت لەسەر تۆڕەکانی مۆبایل';
    return 'Save bandwidth on mobile networks';
  }

  String get whatsNewStorage {
    if (isKurmanji) return 'Rêveberê Bîrgeyê';
    if (isSorani) return 'بەڕێوەبەری بیرگە';
    return 'Storage Manager';
  }

  String get whatsNewStorageSub {
    if (isKurmanji) return 'Paqijkirina kaş û posteran bi hêsanî';
    if (isSorani) return 'سڕینەوەی کاش و پۆستەرەکان بە ئاسانی';
    return 'Clear cache and posters easily';
  }

  // ─── World Cup ────────────────────────────────────────────────

  String get wcTitle {
    if (isKurmanji) return 'Kûpaya Cîhanê FIFA 2026';
    if (isSorani) return 'مۆندیالی ٢٠٢٦';
    return 'FIFA World Cup 2026';
  }

  String get wcTabLive {
    if (isKurmanji) return 'Zindî';
    if (isSorani) return 'ڕاستەوخۆ';
    return 'Live';
  }

  String get wcTabMatches {
    if (isKurmanji) return 'Maç';
    if (isSorani) return 'یارییەکان';
    return 'Matches';
  }

  String get wcTabHighlights {
    if (isKurmanji) return 'Kurte';
    if (isSorani) return 'کورتەکان';
    return 'Highlights';
  }

  String get wcNoHighlights {
    if (isKurmanji) return 'Kurteyên maçan nehatin dîtin';
    if (isSorani) return 'هیچ کورتەیەکی یاری نەدۆزرایەوە';
    return 'No match highlights found';
  }

  String get wcAllVideos {
    if (isKurmanji) return 'Hemî';
    if (isSorani) return 'هەمووی';
    return 'All Videos';
  }

  String get wcGoalsOnly {
    if (isKurmanji) return 'Tenê Gol';
    if (isSorani) return 'تەنها گۆڵەکان';
    return 'Goals Only';
  }

  String get wcHighlightsOnly {
    if (isKurmanji) return 'Tenê Kurte';
    if (isSorani) return 'تەنها کورتەکان';
    return 'Highlights Only';
  }


  String get wcTabGroups {
    if (isKurmanji) return 'Kom';
    if (isSorani) return 'گروپەکان';
    return 'Groups';
  }

  String get wcTabNews {
    if (isKurmanji) return 'Nûçe';
    if (isSorani) return 'هەواڵەکان';
    return 'News';
  }

  String get wcTabScorers {
    if (isKurmanji) return 'Amar';
    if (isSorani) return 'ئامارەکان';
    return 'Stats';
  }

  String get wcTabTeams {
    if (isKurmanji) return 'Tîm';
    if (isSorani) return 'تیمەکان';
    return 'Teams';
  }

  String get wcTabVenues {
    if (isKurmanji) return 'Yarîgeh';
    if (isSorani) return 'یاریگاکان';
    return 'Venues';
  }

  String get wcYesterday {
    if (isKurmanji) return 'Duhî';
    if (isSorani) return 'دوێنێ';
    return 'Yesterday';
  }

  String get wcToday {
    if (isKurmanji) return 'Îro';
    if (isSorani) return 'ئەمڕۆ';
    return 'Today';
  }

  String get wcTomorrow {
    if (isKurmanji) return 'Sibê';
    if (isSorani) return 'سبەی';
    return 'Tomorrow';
  }

  String get wcAfterTomorrow {
    if (isKurmanji) return 'Duyê sibê';
    if (isSorani) return 'دواتر';
    return 'Next';
  }

  String get wcNoMatches {
    if (isKurmanji) return 'Maç tune ye di vê rojê de';
    if (isSorani) return 'هیچ یارییەک نییە لەم بەروارەدا';
    return 'No matches on this date';
  }

  String get wcNoMatchesFound {
    if (isKurmanji) return 'Maç nehat dîtin';
    if (isSorani) return 'هیچ یاری نەدۆزرایەوە';
    return 'No matches found';
  }

  String get wcGroupStandings {
    if (isKurmanji) return 'Rêzika Komê';
    if (isSorani) return 'خشتەی گروپ';
    return 'Group Standings';
  }

  String get wcNoGroups {
    if (isKurmanji) return 'Kom nehat dîtin';
    if (isSorani) return 'هیچ گروپێک نەدۆزرایەوە';
    return 'No groups found';
  }

  String get wcNoNews {
    if (isKurmanji) return 'Nûçe tune ye';
    if (isSorani) return 'هەواڵ بەردەست نییە';
    return 'No news available';
  }

  String get wcNoScorers {
    if (isKurmanji) return 'Agahî tune ye';
    if (isSorani) return 'هیچ زانیارییەک بەردەست نییە';
    return 'No data available';
  }

  String get wcLive {
    if (isKurmanji) return 'ZINDÎ';
    if (isSorani) return 'ڕاستەوخۆ';
    return 'LIVE';
  }

  String get wcUpcoming {
    if (isKurmanji) return 'Bê';
    if (isSorani) return 'داهاتوو';
    return 'Upcoming';
  }

  String get wcFinished {
    if (isKurmanji) return 'KU';
    if (isSorani) return 'کۆتایی';
    return 'FT';
  }

  String get wcGoals {
    if (isKurmanji) return 'Gol';
    if (isSorani) return 'گۆڵ';
    return 'Goals';
  }

  String get wcTeam {
    if (isKurmanji) return 'Tîm';
    if (isSorani) return 'تیم';
    return 'Team';
  }

  String get wcNewsLabel {
    if (isKurmanji) return 'NÛÇE';
    if (isSorani) return 'هەواڵ';
    return 'NEWS';
  }

  String get wcRecently {
    if (isKurmanji) return 'Vêga';
    if (isSorani) return 'دواواتر';
    return 'Recently';
  }

  String wcTimeAgo(int minutes) {
    if (minutes < 60) {
      if (isKurmanji) return '${minutes}d berê';
      if (isSorani) return 'پێش ${minutes} خولەک';
      return '${minutes}m ago';
    }
    final hours = minutes ~/ 60;
    if (hours < 24) {
      if (isKurmanji) return '${hours}s berê';
      if (isSorani) return 'پێش ${hours} کاتژمێر';
      return '${hours}h ago';
    }
    final days = hours ~/ 24;
    if (isKurmanji) return '${days}r berê';
    if (isSorani) return 'پێش ${days} ڕۆژ';
    return '${days}d ago';
  }

  String get wcViewers {
    if (isKurmanji) return 'temaşevan';
    if (isSorani) return 'بینەر';
    return 'viewers';
  }

  String get wcNoTeams {
    if (isKurmanji) return 'Tîm nehatin dîtin';
    if (isSorani) return 'هیچ تیمێک نەدۆزرایەوە';
    return 'No teams found';
  }

  String get wcTournamentStats {
    if (isKurmanji) return 'Statîstîkên Tûrnûvayê';
    if (isSorani) return 'ئامارەکانی پاڵەوانێتی';
    return 'Tournament Stats';
  }

  String get wcStatsNotAvailable {
    if (isKurmanji) return 'Statîstîk hê ne berdest in';
    if (isSorani) return 'ئامارەکان هێشتا بەردەست نین';
    return 'Stats not available yet';
  }

  String get wcCapacity {
    if (isKurmanji) return 'Kapasîte';
    if (isSorani) return 'توانای لەخۆگرتن';
    return 'Capacity';
  }

  String get wcLiveWinProbability {
    if (isKurmanji) return 'Îhtîmala Serkeftinê ya Zindî';
    if (isSorani) return 'ئەگەری بردنەوەی ڕاستەوخۆ';
    return 'Live Win Probability';
  }

  String get wcDraw {
    if (isKurmanji) return 'Beramber';
    if (isSorani) return 'یەکسانبوون';
    return 'Draw';
  }

  String get wcSummary {
    if (isKurmanji) return 'Kurte';
    if (isSorani) return 'کورتە';
    return 'Summary';
  }

  String get wcRosters {
    if (isKurmanji) return 'Kadro';
    if (isSorani) return 'پێکهاتە';
    return 'Rosters';
  }

  String get wcTimeline {
    if (isKurmanji) return 'Rêzbûyer';
    if (isSorani) return 'کاتی ڕووداوەکان';
    return 'Timeline';
  }

  String get wcSubstitutes {
    if (isKurmanji) return 'Yedek';
    if (isSorani) return 'یەدەگەکان';
    return 'Substitutes';
  }

  String get wcManager {
    if (isKurmanji) return 'Rêvebir';
    if (isSorani) return 'ڕاهێنەر';
    return 'Manager';
  }

  String get wcSquadRoster {
    if (isKurmanji) return 'Kadroyê Tîmê';
    if (isSorani) return 'پێکهاتەی تیم';
    return 'Squad Roster';
  }

  String get wcGoalkeepers {
    if (isKurmanji) return 'Goleparêz';
    if (isSorani) return 'گۆڵپارێزەکان';
    return 'Goalkeepers';
  }

  String get wcDefenders {
    if (isKurmanji) return 'Parastvan';
    if (isSorani) return 'بەرگریکارەکان';
    return 'Defenders';
  }

  String get wcMidfielders {
    if (isKurmanji) return 'Navend';
    if (isSorani) return 'یاریزانانی ناوەڕاست';
    return 'Midfielders';
  }

  String get wcForwards {
    if (isKurmanji) return 'Êrîşber';
    if (isSorani) return 'هێرشبەرەکان';
    return 'Forwards';
  }

  String get wcNoRosterData {
    if (isKurmanji) return 'Daneyên kadro tune';
    if (isSorani) return 'هیچ داتایەکی پێکهاتە نییە';
    return 'No roster data available';
  }
  String get updateAvailable {
    if (isKurmanji) return 'NÛVEKIRIN HEYE';
    if (isSorani) return 'نوێکردنەوە بەردەستە';
    return 'UPDATE AVAILABLE';
  }

  String updateVersion(String version) {
    if (isKurmanji) return 'Guherto $version';
    if (isSorani) return 'وەشانی $version';
    return 'Version $version';
  }

  String updateReleaseNotesEmpty(String original) {
    if (original.isNotEmpty) return original;
    if (isKurmanji) return 'Sererastkirina çewtiyan û baştirkirina performansê.';
    if (isSorani) return 'چارەسەرکردنی کێشەکان و باشترکردنی خێرایی.';
    return 'Bug fixes and performance improvements.';
  }

  String get updateDownload {
    if (isKurmanji) return 'NÛVEKIRINÊ DAXE';
    if (isSorani) return 'دابەزاندنی نوێکردنەوە';
    return 'DOWNLOAD UPDATE';
  }

  String get updateInstall {
    if (isKurmanji) return 'NÛVEKIRINÊ LÊ BIKE';
    if (isSorani) return 'دامەزراندنی نوێکردنەوە';
    return 'INSTALL UPDATE';
  }

  String get updatePreparing {
    if (isKurmanji) return 'Tê amadekirin...';
    if (isSorani) return 'ئامادەکردن...';
    return 'Preparing...';
  }

  String updateDownloading(String received, String total) {
    if (isKurmanji) return 'Tê daxistin... $received / $total MB';
    if (isSorani) return 'لە دابەزاندندایە... $received / $total مێگابایت';
    return 'Downloading... $received / $total MB';
  }

  String get updateDownloadComplete {
    if (isKurmanji) return 'Daxistin Temam Bû!';
    if (isSorani) return 'دابەزاندن تەواو بوو!';
    return 'Download Complete!';
  }

  String get updateDownloadFailed {
    if (isKurmanji) return 'Daxistin têk çû. Ji bo dubarekirinê pêl bike.';
    if (isSorani) return 'دابەزاندن سەرکەوتوو نەبوو. دەست لێ بدە بۆ دووبارەکردنەوە.';
    return 'Download failed. Tap to retry.';
  }
}
