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
    if (isKurmanji) return 'Bi xÃªr hatÃ®';
    if (isSorani) return 'Ø¨Û•Ø®ÛŽØ±Ø¨ÛŽÛŒØª';
    return 'Welcome';
  }

  String get loginSubtitle {
    if (isKurmanji) return 'Ji kerema xwe koda xwe binivÃ®se da ku berdewam bikÃ®';
    if (isSorani) return 'ØªÚ©Ø§ÛŒÛ• Ú©Û†Ø¯ÛŒ Ú†ÙˆÙˆÙ†Û•Ú˜ÙˆÙˆØ±Û•ÙˆÛ• Ø¨Ù†ÙˆÙˆØ³Û• Ø¨Û† Ø¨Û•Ø±Ø¯Û•ÙˆØ§Ù…Ø¨ÙˆÙˆÙ†';
    return 'Enter your access code to continue';
  }

  String get loginHint => 'â˜†â˜†â˜†â˜†â˜†â˜†';

  String get loginButton {
    if (isKurmanji) return 'Berdewam bike';
    if (isSorani) return 'Ø¨Û•Ø±Ø¯Û•ÙˆØ§Ù…Ø¨Û•';
    return 'Continue';
  }

  String get loginErrorEmpty {
    if (isKurmanji) return 'KodÃª binivÃ®se';
    if (isSorani) return 'Ú©Û†Ø¯Û•Ú©Û• Ø¨Ù†ÙˆÙˆØ³Û•';
    return 'Enter a code';
  }

  String get loginErrorInvalid {
    if (isKurmanji) return 'Kod nehat nasÃ®n';
    if (isSorani) return 'Ú©Û†Ø¯Û•Ú©Û• Ù‡Û•ÚµÛ•ÛŒÛ•';
    return 'Code not recognized';
  }

  String get loginErrorNetwork {
    if (isKurmanji) return 'TÃªkiliya Ã®nternetÃª kontrol bike Ã» dÃ®sa biceribÃ®ne';
    if (isSorani) return 'Ù¾Û•ÛŒÙˆÛ•Ù†Ø¯ÛŒ Ø¦ÛŒÙ†ØªÛ•Ø±Ù†ÛŽØª Ø¨Ù¾Ø´Ú©Ù†Û• Ùˆ Ø¯ÙˆÙˆØ¨Ø§Ø±Û• Ù‡Û•ÙˆÚµØ¨Ø¯Û•ÙˆÛ•';
    return 'Check connection and try again';
  }

  String get appBrand => 'KOBANI 4K';

  String get appTagline {
    if (isKurmanji) return 'CÃ®hanek ji kÃªf Ã» wext derbaskirinÃª';
    if (isSorani) return 'Ø¬ÛŒÙ‡Ø§Ù†ÛŽÚ© Ù„Û• Ú©Ø§ØªØ¨Û•Ø³Û•Ø±Ø¨Ø±Ø¯Ù†';
    return 'Premium entertainment';
  }

  String get noChannels {
    if (isKurmanji) return 'HÃªj qenal nÃ®nin';
    if (isSorani) return 'Ù‡ÛŒÚ† Ú©Û•Ù†Ø§ÚµÛŽÚ© Ø¨Û•Ø±Ø¯Û•Ø³Øª Ù†ÛŒÛŒÛ•';
    return 'No channels yet';
  }

  String get noChannelsHint {
    if (isKurmanji) return 'Gava lÃ®steya te tÃª hevdeng kirin ew Ãª xuya bibin.';
    if (isSorani) return 'Ú©Û•Ù†Ø§ÚµÛ•Ú©Ø§Ù† Ø¯Û•Ø±Ø¯Û•Ú©Û•ÙˆÙ† Ú©Ø§ØªÛŽÚ© Ù„ÛŒØ³ØªÛ•Ú©Û•Øª Ù‡Ø§ÙˆÚ©Ø§Øª Ø¯Û•Ú©Ø±ÛŽØª.';
    return 'They appear when your library syncs.';
  }

  String get nowPlaying {
    if (isKurmanji) return 'PÃªÅŸniyarkirÃ®';
    if (isSorani) return 'Ø¬ÛŽÛŒ Ø³Û•Ø±Ù†Ø¬';
    return 'Featured';
  }

  String get featuredNewHint {
    if (isKurmanji) return 'Qenalek nÃ» li lÃ®steya te hat zÃªdekirin. Dest bide "TemaÅŸe bike".';
    if (isSorani) return 'Ú©Û•Ù†Ø§ÚµÛŽÚ©ÛŒ Ù†ÙˆÛŽ Ø¨Û† Ù„ÛŒØ³ØªÛ•Ú©Û•Øª Ø²ÛŒØ§Ø¯Ú©Ø±Ø§ÙˆÛ•ØŒ Ø¯Û•Ø³Øª Ù„Û• Â«Ø¨Ø¨ÛŒÙ†Û•Â» Ø¨Ø¯Û• Ø¨Û† Ø³Û•ÛŒØ±Ú©Ø±Ø¯Ù†.';
    return 'A new channel is available in your lineup. Tap Watch to start playing.';
  }

  String get watchNow {
    if (isKurmanji) return 'TemaÅŸe bike';
    if (isSorani) return 'Ø¨Ø¨ÛŒÙ†Û•';
    return 'Watch';
  }

  String get channelLoadError {
    if (isKurmanji) return 'Qenal nehatin xwendin';
    if (isSorani) return 'Ù†Û•ØªÙˆØ§Ù†Ø±Ø§ Ú©Û•Ù†Ø§ÚµÛ•Ú©Ø§Ù† Ø¨Ø®ÙˆÛŽÙ†Ø±ÛŽØªÛ•ÙˆÛ•';
    return 'Could not load channels';
  }

  String get settingsTooltip {
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'Ú•ÛŽÚ©Ø®Ø³ØªÙ†Û•Ú©Ø§Ù†';
    return 'Settings';
  }

  String get settingsTitle {
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'Ú•ÛŽÚ©Ø®Ø³ØªÙ†Û•Ú©Ø§Ù†';
    return 'Settings';
  }

  String get sectionPlayback {
    if (isKurmanji) return 'LÃªdan';
    if (isSorani) return 'Ù¾Û•Ø®Ø´Ú©Ø±Ø¯Ù†';
    return 'Playback';
  }

  String get sectionVideo {
    if (isKurmanji) return 'Mezinahiya VÃ®dyoyÃª';
    if (isSorani) return 'Ù‚Û•Ø¨Ø§Ø±Û•ÛŒ Ú¤ÛŒØ¯ÛŒÛ†';
    return 'Video fit';
  }

  String get sectionInterface {
    if (isKurmanji) return 'RÃ»kar';
    if (isSorani) return 'Ú•ÙˆÙˆÚ©Ø§Ø±';
    return 'Interface';
  }

  String get sectionGradientTheme {
    if (isKurmanji) return 'Reng Ã» PaÅŸxane';
    if (isSorani) return 'Ø´ÛŽÙˆØ§Ø²ÛŒ Ú•Û•Ù†Ú¯ Ùˆ Ù¾Ø§Ø´Ø¨Ù†Û•';
    return 'Theme & backdrop';
  }

  String get gradientThemeCaption {
    if (isKurmanji) return 'RengÃªn ji bo dashboard Ã» vÃª rÃ»pelÃª';
    if (isSorani) return 'Ø´ÛŽÙˆØ§Ø²ÛŒ Ú•Û•Ù†Ú¯ÛŒØ²Û• Ø¨Û† Ø¯Ø§Ø´Ø¨Û†Ø±Ø¯ Ùˆ Ø¦Û•Ù… Ø´Ø§Ø´Û•ÛŒÛ•';
    return 'Gradient look for dashboard and this screen';
  }

  String get gradientClassic {
    if (isKurmanji) return 'NÃ®vÃª ÅževÃª';
    if (isSorani) return 'Ù†ÛŒÙˆÛ•Ø´Û•Ùˆ';
    return 'Midnight';
  }

  String get gradientOcean {
    if (isKurmanji) return 'KÃ»rahiya OkyanÃ»sÃª';
    if (isSorani) return 'Ù‚ÙˆÙˆÚµØ§ÛŒÛŒ Ø¦Û†Ù‚ÛŒØ§Ù†ÙˆØ³';
    return 'Ocean abyss';
  }

  String get gradientGold {
    if (isKurmanji) return 'ZÃªrÃ®n';
    if (isSorani) return 'Ø¦Ø§Ø³Û†ÛŒÛŒ Ø²ÛŽÚ•ÛŒÙ†';
    return 'Gold sunset';
  }

  String get gradientViolet {
    if (isKurmanji) return 'MijÃª Mor';
    if (isSorani) return 'ØªÛ•Ù…ÙˆÙ…Ú˜ÛŒ Ù…Û†Ø±';
    return 'Violet haze';
  }

  String get gradientEmber {
    if (isKurmanji) return 'GÃªla PÃªtÃª (Bingehan)';
    if (isSorani) return 'Ú¯Û•Ø´ÛŒÛŒ Ù¾Û†Ù„ÛŽØªÛŒ (Ø¨Ù†Û•Ú•Û•ØªÛŒ)';
    return 'Ember glow (default)';
  }

  String get sectionLanguage {
    if (isKurmanji) return 'Ziman';
    if (isSorani) return 'Ø²Ù…Ø§Ù†Û•Ú©Ø§Ù†';
    return 'Language';
  }

  String get sectionAccount {
    if (isKurmanji) return 'Hesab';
    if (isSorani) return 'Ù‡Û•Ú˜Ù…Ø§Ø±';
    return 'Account';
  }

  String get sectionAbout {
    if (isKurmanji) return 'Derbar';
    if (isSorani) return 'Ø¯Û•Ø±Ø¨Ø§Ø±Û•';
    return 'About';
  }

  String get keepScreenOnTitle {
    if (isKurmanji) return 'DÃ®mender ronÃ® bihÃªle';
    if (isSorani) return 'Ø¯Ø§Ú¯ÛŒØ±Ø³Ø§Ù†Ø¯Ù†ÛŒ Ø´Ø§Ø´Û•';
    return 'Keep screen on';
  }

  String get keepScreenOnSub {
    if (isKurmanji) return 'Dema vÃ®dyo tÃª lÃªdan';
    if (isSorani) return 'Ú•ÛŽÚ¯Ø±ÛŒ Ù„Û• Ú©ÙˆÚ˜Ø§Ù†Û•ÙˆÛ•ÛŒ Ø´Ø§Ø´Û• Ù„Û•Ú©Ø§ØªÛŒ Ù¾Û•Ø®Ø´Ú©Ø±Ø¯Ù†Ø¯Ø§';
    return 'While video is playing';
  }

  String get autoHideTitle {
    if (isKurmanji) return 'Bikojkan veÅŸÃªre';
    if (isSorani) return 'Ø´Ø§Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø¯ÙˆÚ¯Ù…Û•Ú©Ø§Ù†';
    return 'Hide controls';
  }

  String get autoHideSub {
    if (isKurmanji) return 'Bi dest lÃªdanÃª dubare nÃ®ÅŸan bide';
    if (isSorani) return 'Ø´Ø§Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø´Ø±ÛŒØªÛŒ Ù¾Ù„Û•ÛŒÛ•Ø±ØŒ Ø¯Û•Ø³Øª Ù„ÛŽ Ø¨Ø¯Û• Ø¨Û† Ù¾ÛŒØ´Ø§Ù†Ø¯Ø§Ù†Û•ÙˆÛ•';
    return 'Fade player bars; tap to show';
  }

  String get clockTitle {
    if (isKurmanji) return 'DemjimÃªr di lÃ®stikvanÃª de';
    if (isSorani) return 'Ú©Ø§ØªÚ˜Ù…ÛŽØ± Ù„Û• Ù¾Ù„Û•ÛŒÛ•Ø±';
    return 'Clock in player';
  }

  String get clockSub {
    if (isKurmanji) return 'Dema lÃ®stikvan nÃ®ÅŸan bide';
    if (isSorani) return 'Ù¾ÛŒØ´Ø§Ù†Ø¯Ø§Ù†ÛŒ Ú©Ø§Øª Ù„Û• Ø´Ø±ÛŒØªÛŒ Ø³Û•Ø±Û•ÙˆÛ•';
    return 'Time in top bar';
  }

  String get videoFitCaption {
    if (isKurmanji) return 'Ã‡awa vÃ®dyo li ser ekranÃª rÃ»ne';
    if (isSorani) return 'Ú†Û†Ù†ÛŒÛ•ØªÛŒ Ú¯ÙˆÙ†Ø¬Ø§Ù†Ø¯Ù†ÛŒ Ú¤ÛŒØ¯ÛŒÛ† Ù„Û•Ø³Û•Ø± Ø´Ø§Ø´Û•';
    return 'How video fills the screen';
  }

  String get reduceMotionTitle {
    if (isKurmanji) return 'Tevgeran kÃªm bike';
    if (isSorani) return 'Ú©Û•Ù…Ú©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø¬ÙˆÚµÛ•';
    return 'Reduce motion';
  }

  String get reduceMotionSub {
    if (isKurmanji) return 'AnÃ®masyonÃªn kurtir';
    if (isSorani) return 'Ø¨Û•Ú©Ø§Ø±Ù‡ÛŽÙ†Ø§Ù†ÛŒ Ø¬ÙˆÚµÛ•ÛŒ Ú©ÙˆØ±ØªØªØ±';
    return 'Shorter animations';
  }

  String get logoutTitle {
    if (isKurmanji) return 'Derkeve';
    if (isSorani) return 'Ú†ÙˆÙˆÙ†Û•Ø¯Û•Ø±Û•ÙˆÛ•';
    return 'Sign out';
  }

  String get logoutSub {
    if (isKurmanji) return 'HesabÃª xwe ji vÃ® cÃ®hazÃ® rakin';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ù‡Û•Ú˜Ù…Ø§Ø± Ù„Û•Ø³Û•Ø± Ø¦Û•Ù… Ø¦Ø§Ù…ÛŽØ±Û•';
    return 'Clear login on this device';
  }

  String get logoutButton {
    if (isKurmanji) return 'Derkeve';
    if (isSorani) return 'Ú†ÙˆÙˆÙ†Û•Ø¯Û•Ø±Û•ÙˆÛ•';
    return 'Sign out';
  }

  String get aboutTitle => 'KOBANI 4K';

  String get aboutSub {
    if (isKurmanji) return 'Guherto 1.2.0 Â· IPTV';
    if (isSorani) return 'ÙˆÛ•Ø´Ø§Ù†ÛŒ Ù¡.Ù¢.Ù  Â· IPTV';
    return 'Version 1.2.0 Â· IPTV';
  }

  String get langEnglish => 'English';
  String get langKurdishSorani => 'Ú©ÙˆØ±Ø¯ÛŒ (Ø³Û†Ø±Ø§Ù†ÛŒ)';
  String get langKurdishKurmanji => 'KurdÃ® (KurmancÃ®)';

  String get cancel {
    if (isKurmanji) return 'Betal bike';
    if (isSorani) return 'Ù‡Û•ÚµÙˆÛ•Ø´Ø§Ù†Ø¯Ù†Û•ÙˆÛ•';
    return 'Cancel';
  }

  String get password {
    if (isKurmanji) return 'ÅžÃ®fre';
    if (isSorani) return 'ÙˆØ´Û•ÛŒ Ù†Ù‡ÛŽÙ†ÛŒ';
    return 'Password';
  }

  String get enter {
    if (isKurmanji) return 'TÃªkeve';
    if (isSorani) return 'Ú†ÙˆÙˆÙ†Û•Ú˜ÙˆÙˆØ±Û•ÙˆÛ•';
    return 'Enter';
  }

  String get fullscreenTooltip {
    if (isKurmanji) return 'Ekrana tije';
    if (isSorani) return 'Ù¾Ú• Ø¨Û• Ø´Ø§Ø´Û•';
    return 'Fullscreen';
  }

  String get navHome {
    if (isKurmanji) return 'Mal';
    if (isSorani) return 'Ø³Û•Ø±Û•Ú©ÛŒ';
    return 'Home';
  }

  String get navMovies {
    if (isKurmanji) return 'FÃ®lm';
    if (isSorani) return 'ÙÛŒÙ„Ù…Û•Ú©Ø§Ù†';
    return 'Movies';
  }

  String get navSport {
    if (isKurmanji) return 'Spor';
    if (isSorani) return 'ÙˆÛ•Ø±Ø²Ø´';
    return 'Sport';
  }

  String get navWorldCup {
    if (isKurmanji) return 'KÃ»paya CÃ®hanÃª 26';
    if (isSorani) return 'Ù…Û†Ù†Ø¯ÛŒØ§Ù„ÛŒ Ù¢Ù Ù¢Ù¦';
    return 'World Cup 26';
  }

  String get navProfile {
    if (isKurmanji) return 'Sazkirin';
    if (isSorani) return 'Ú•ÛŽÚ©Ø®Ø³ØªÙ†Û•Ú©Ø§Ù†';
    return 'Settings';
  }

  String get navFavorites {
    if (isKurmanji) return 'Bijare';
    if (isSorani) return 'Ø¯ÚµØ®ÙˆØ§Ø²Û•Ú©Ø§Ù†Ù…';
    return 'Favorites';
  }

  String get navRecent {
    if (isKurmanji) return 'DÃ®tÃ®';
    if (isSorani) return 'Ø¨ÛŒÙ†Ø±Ø§ÙˆÛ•Ú©Ø§Ù†ÛŒ Ø¯ÙˆØ§ÛŒÛŒ';
    return 'Recent';
  }

  String get searchHint {
    if (isKurmanji) return 'LÃªgerÃ®n li qenalan...';
    if (isSorani) return 'Ú¯Û•Ú•Ø§Ù† Ø¨Û•Ø¯ÙˆØ§ÛŒ Ú©Û•Ù†Ø§Úµ...';
    return 'Search channelsâ€¦';
  }

  String get categoriesTitle {
    if (isKurmanji) return 'KategorÃ®';
    if (isSorani) return 'Ù‡Ø§ÙˆÙ¾Û†Ù„Û•Ú©Ø§Ù†';
    return 'Categories';
  }

  String get channelListTitle {
    if (isKurmanji) return 'LÃ®steya Qenalan';
    if (isSorani) return 'Ù„ÛŒØ³ØªÛŒ Ú©Û•Ù†Ø§ÚµÛ•Ú©Ø§Ù†';
    return 'Channel list';
  }

  String get noChannelsInSection {
    if (isKurmanji) return 'Qenal li vÃª beÅŸÃª nÃ®nin';
    if (isSorani) return 'Ù‡ÛŒÚ† Ú©Û•Ù†Ø§ÚµÛŽÚ© Ù„Û•Ù… Ø¨Û•Ø´Û•Ø¯Ø§ Ù†ÛŒÛŒÛ•';
    return 'No channels in this section';
  }

  String get noFavorites {
    if (isKurmanji) return 'HÃªj bijare nÃ®nin';
    if (isSorani) return 'Ù‡ÛŒÚ† Ø¯ÚµØ®ÙˆØ§Ø²ÛŽÚ© Ù†ÛŒÛŒÛ•';
    return 'No favorites yet';
  }

  String get noFavoritesHint {
    if (isKurmanji) return 'Ji bo zÃªdekirinÃª, pÃªl stÃªrkÃª bike.';
    if (isSorani) return 'Ø¦Û•Ø³ØªÛŽØ±Û•ÛŒ Ø³Û•Ø± Ù¾Ù„Û•ÛŒÛ•Ø±Û•Ú©Û• Ø¯Ø§Ø¨Ú¯Ø±Û• Ø¨Û† Ø²ÛŒØ§Ø¯Ú©Ø±Ø¯Ù†ÛŒ Ú©Û•Ù†Ø§Úµ.';
    return 'Long-press a channel on the home grid or tap the star in the player.';
  }

  String get noRecent {
    if (isKurmanji) return 'HÃªj tiÅŸtek nehatiye lÃ®stin';
    if (isSorani) return 'Ù‡ÛŒÚ† Ø´ØªÛŽÚ© Ù†Û•Ø¨ÛŒÙ†Ø±Ø§ÙˆÛ•';
    return 'Nothing played yet';
  }

  String get noRecentHint {
    if (isKurmanji) return 'QenalÃªn te li vir xuya dibin.';
    if (isSorani) return 'Ú©Û•Ù†Ø§ÚµÛ•Ú©Ø§Ù† Ù„ÛŽØ±Û•Ø¯Ø§ Ø¯Û•Ø±Ø¯Û•Ú©Û•ÙˆÙ† Ø¨Û† Ø¨ÛŒÙ†ÛŒÙ†Û•ÙˆÛ•ÛŒ Ø®ÛŽØ±Ø§.';
    return 'Channels you open appear here for quick return.';
  }

  String get sectionLibrary {
    if (isKurmanji) return 'PirtÃ»kxane';
    if (isSorani) return 'Ú©ØªÛŽØ¨Ø®Ø§Ù†Û•';
    return 'Library';
  }

  String get clearFavoritesTitle {
    if (isKurmanji) return 'Bijareyan Paqij bike';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ø¯ÚµØ®ÙˆØ§Ø²Û•Ú©Ø§Ù†';
    return 'Clear favorites';
  }

  String get clearFavoritesSub {
    if (isKurmanji) return 'HemÃ» qenalÃªn bijare jÃª bibe';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ù‡Û•Ù…ÙˆÙˆ Ú©Û•Ù†Ø§ÚµÛ• Ø¯ÚµØ®ÙˆØ§Ø²Û•Ú©Ø§Ù†';
    return 'Remove all starred channels on this device';
  }

  String get clearRecentTitle {
    if (isKurmanji) return 'DÃ®rokÃª Paqij bike';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ù…ÛŽÚ˜ÙˆÙˆÛŒ Ø¨ÛŒÙ†ÛŒÙ†';
    return 'Clear watch history';
  }

  String get clearRecentSub {
    if (isKurmanji) return 'HemÃ» qenalÃªn dÃ®tÃ® jÃª bibe';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ù‡Û•Ù…ÙˆÙˆ Ú©Û•Ù†Ø§ÚµÛ• Ø¨ÛŒÙ†Ø±Ø§ÙˆÛ•Ú©Ø§Ù†';
    return 'Forget recently opened channels on this device';
  }

  String get clearLibraryConfirmBody {
    if (isKurmanji) return 'Ev nayÃª betalkirin.';
    if (isSorani) return 'Ø¦Û•Ù… Ù¾Ú•Û†Ø³Û•ÛŒÛ• Ù†Ø§Ú¯Û•Ú•ÛŽØªÛ•ÙˆÛ• Ø¯ÙˆØ§ÙˆÛ•.';
    return 'This cannot be undone.';
  }

  String get clearButton {
    if (isKurmanji) return 'Paqij bike';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•';
    return 'Clear';
  }

  String get favoriteChannel {
    if (isKurmanji) return 'ZÃªdeyÃ® bijareyan bike';
    if (isSorani) return 'Ø²ÛŒØ§Ø¯Ú©Ø±Ø¯Ù† Ø¨Û† Ø¯ÚµØ®ÙˆØ§Ø²Û•Ú©Ø§Ù†';
    return 'Add to favorites';
  }

  String get unfavoriteChannel {
    if (isKurmanji) return 'Ji bijareyan derxÃ®ne';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ• Ù„Û• Ø¯ÚµØ®ÙˆØ§Ø²Û•Ú©Ø§Ù†';
    return 'Remove from favorites';
  }

  String fitLabel(BoxFit fit) {
    if (isKurmanji) {
      return switch (fit) {
        BoxFit.contain => 'TijÃ® (BÃª birÃ®n)',
        BoxFit.cover => 'RÃ»poÅŸ (Derdor birÃ®n)',
        BoxFit.fill => 'Tije bike',
        BoxFit.fitWidth => 'Bi firehiyÃª re hevaheng bike',
        BoxFit.fitHeight => 'Bi bilindiyÃª re hevaheng bike',
        BoxFit.scaleDown => 'BiÃ§Ã»k bike',
        BoxFit.none => 'Mezinahiya rastÃ®n',
      };
    }
    if (isSorani) {
      return switch (fit) {
        BoxFit.contain => 'ØªÛ•ÙˆØ§Ùˆ (Ø¨Û• Ø¨ÛŽ Ø¨Ú•ÛŒÙ†)',
        BoxFit.cover => 'Ø¯Ø§Ù¾Û†Ø´ÛŒÙ† (Ø¨Ú•ÛŒÙ†ÛŒ Ø¯Û•ÙˆØ±ÙˆÙˆØ¨Û•Ø±)',
        BoxFit.fill => 'Ù¾Ú•Ú©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø´Ø§Ø´Û•',
        BoxFit.fitWidth => 'Ú¯ÙˆÙ†Ø¬Ø§Ù†Ø¯Ù† Ù„Û•Ú¯Û•Úµ Ù¾Ø§Ù†ÛŒ',
        BoxFit.fitHeight => 'Ú¯ÙˆÙ†Ø¬Ø§Ù†Ø¯Ù† Ù„Û•Ú¯Û•Úµ Ø¨Û•Ø±Ø²ÛŒ',
        BoxFit.scaleDown => 'Ù¾Ú†ÙˆÚ©Ø±Ø¯Ù†Û•ÙˆÛ•',
        BoxFit.none => 'Ù‚Û•Ø¨Ø§Ø±Û•ÛŒ Ø¦Û•Ø³ÚµÛŒ',
      };
    }
    return AppSettingsData.labelForFit(fit);
  }
  String get sectionStorage {
    if (isKurmanji) return 'BÃ®rge Ã» KaÅŸ';
    if (isSorani) return 'Ø¨ÛŒØ±Ú¯Û• Ùˆ Ú©Ø§Ø´';
    return 'Storage & Cache';
  }

  String get storagePosters {
    if (isKurmanji) return 'PosterÃªn FÃ®lm Ã» RÃªzefÃ®lman';
    if (isSorani) return 'Ù¾Û†Ø³ØªÛ•Ø±ÛŒ ÙÛŒÙ„Ù… Ùˆ Ø²Ù†Ø¬ÛŒØ±Û•Ú©Ø§Ù†';
    return 'Movie & Series Posters';
  }

  String get storageEpg {
    if (isKurmanji) return 'DaneyÃªn RÃªberÃª TV EPG';
    if (isSorani) return 'Ø¯Ø§ØªØ§ÛŒ Ú•ÛŽØ¨Û•Ø±ÛŒ ØªÛ•Ù„Û•ÙØ²ÛŒÛ†Ù†ÛŒ EPG';
    return 'EPG TV Guide Data';
  }

  String get storageLogs {
    if (isKurmanji) return 'DaneyÃªn DemkÃ® Ã» Log';
    if (isSorani) return 'Ø¯Ø§ØªØ§ÛŒ Ú©Ø§ØªÛŒ Ùˆ Ù„Û†Ú¯Û•Ú©Ø§Ù†';
    return 'Temporary Logs & Data';
  }

  String get calculating {
    if (isKurmanji) return 'TÃª hesibandin...';
    if (isSorani) return 'Ù„Û• Ù‡Û•Ú˜Ù…Ø§Ø±Ú©Ø±Ø¯Ù†Ø¯Ø§ÛŒÛ•...';
    return 'Calculating...';
  }

  String get sectionSubtitles {
    if (isKurmanji) return 'VebijarkÃªn BinnivÃ®sÃª (VOD)';
    if (isSorani) return 'Ù‡Û•ÚµØ¨Ú˜Ø§Ø±Ø¯Û•Ú©Ø§Ù†ÛŒ Ú˜ÛŽØ±Ù†ÙˆÙˆØ³ (VOD)';
    return 'Subtitle Preferences (VOD)';
  }

  String get subtitleCaption {
    if (isKurmanji) return 'XuyabÃ»na binnivÃ®san di fÃ®lm Ã» rÃªzefÃ®lman de sererast bike';
    if (isSorani) return 'Ø´ÛŽÙˆØ§Ø²ÛŒ Ø¯Û•Ø±Ú©Û•ÙˆØªÙ†ÛŒ Ú˜ÛŽØ±Ù†ÙˆÙˆØ³ Ù„Û• ÙÛŒÙ„Ù… Ùˆ Ø²Ù†Ø¬ÛŒØ±Û•Ú©Ø§Ù†Ø¯Ø§ Ú•ÛŽÚ©Ø¨Ø®Û•';
    return 'Customize how subtitles look in movies and series';
  }

  String get subtitleFontSize {
    if (isKurmanji) return 'Mezinahiya FontÃª';
    if (isSorani) return 'Ù‚Û•Ø¨Ø§Ø±Û•ÛŒ ÙÛ†Ù†Øª';
    return 'Font Size';
  }

  String get subtitleColor {
    if (isKurmanji) return 'RengÃª NivÃ®sÃª';
    if (isSorani) return 'Ú•Û•Ù†Ú¯ÛŒ Ø¯Û•Ù‚';
    return 'Text Color';
  }

  String get subtitleBgOpacity {
    if (isKurmanji) return 'TÃ®rÃªjiya PaÅŸxanÃª';
    if (isSorani) return 'Ú•ÙˆÙˆÙ†ÛŒ Ù¾Ø§Ø´Ø¨Ù†Û•';
    return 'Background Opacity';
  }

  String get subtitleBgOff {
    if (isKurmanji) return 'GirtÃ®';
    if (isSorani) return 'Ú©ÙˆÚ˜Ø§ÙˆÛ•';
    return 'Off';
  }

  String get subtitleBgSemi {
    return '45%';
  }

  String get subtitleBgSolid {
    if (isKurmanji) return 'TÃ®r';
    if (isSorani) return 'ØªÛ†Ø®';
    return 'Solid';
  }

  String get subtitleSample {
    if (isKurmanji) return 'MÃ®naka NivÃ®sa BinnivÃ®sÃª';
    if (isSorani) return 'Ù†Ù…ÙˆÙˆÙ†Û•ÛŒ Ø¯Û•Ù‚ÛŒ Ú˜ÛŽØ±Ù†ÙˆÙˆØ³';
    return 'Sample Subtitle Text';
  }

  String get sectionPlaybackNetwork {
    if (isKurmanji) return 'LÃªdan Ã» ÃŽnternet';
    if (isSorani) return 'Ù¾Û•Ø®Ø´Ú©Ø±Ø¯Ù† Ùˆ Ø¦ÛŒÙ†ØªÛ•Ø±Ù†ÛŽØª';
    return 'Playback & Network';
  }

  String get hardwareAccel {
    if (isKurmanji) return 'Lezkirina Hardware';
    if (isSorani) return 'Ø®ÛŽØ±Ø§Ú©Ø±Ø¯Ù†ÛŒ Ú•Û•Ù‚Û•Ú©Ø§ÚµØ§';
    return 'Hardware Acceleration';
  }

  String get hardwareAccelSub {
    if (isKurmanji) return 'Dekodkirina hardware bi kar bÃ®ne (ji bo Ã§areserkirina sekinÃ®nÃª di cÃ®hazÃªn kevn de bigire)';
    if (isSorani) return 'Ø¨Û•Ú©Ø§Ø±Ù‡ÛŽÙ†Ø§Ù†ÛŒ Ø¯ÛŒÙ€Ú©Û†Ø¯ÛŒÙ†Ú¯ÛŒ Ú•Û•Ù‚Û•Ú©Ø§ÚµØ§ (Ø¨ÛŒÚ©ÙˆÚ˜ÛŽÙ†Û•ÙˆÛ• Ø¨Û† Ú†Ø§Ø±Û•Ø³Û•Ø±ÛŒ ÙˆÛ•Ø³ØªØ§Ù† Ù„Û• Ø¦Ø§Ù…ÛŽØ±Û• Ú©Û†Ù†Û•Ú©Ø§Ù†Ø¯Ø§)';
    return 'Use hardware decoding (turn off to fix stuttering on older devices)';
  }

  String get dataSaver {
    if (isKurmanji) return 'Moda Parastina DaneyÃª';
    if (isSorani) return 'Ù…Û†Ø¯ÛŒ Ù¾Ø§Ø´Û•Ú©Û•ÙˆØªÚ©Ø±Ø¯Ù†ÛŒ Ø¯Ø§ØªØ§';
    return 'Data Saver Mode';
  }

  String get dataSaverSub {
    if (isKurmanji) return 'Bi awayekÃ® otomatÃ®k daxwaza weÅŸanÃªn qalÃ®teya nizm li ser torÃªn mobÃ®l dike';
    if (isSorani) return 'Ø¨Û•Ø´ÛŽÙˆÛ•ÛŒÛ•Ú©ÛŒ Ø¦Û†ØªÛ†Ù…Ø§ØªÛŒÚ©ÛŒ Ø¯Ø§ÙˆØ§ÛŒ Ú©ÙˆØ§Ù„ÛŽØªÛŒ Ù†Ø²Ù…ØªØ± Ø¯Û•Ú©Ø§Øª Ù„Û•Ø³Û•Ø± ØªÛ†Ú•Û•Ú©Ø§Ù†ÛŒ Ù…Û†Ø¨Ø§ÛŒÙ„';
    return 'Automatically request lower quality streams on mobile networks';
  }

  String get sectionDiagnostics {
    if (isKurmanji) return 'Kontrola CÃ®haz Ã» TorÃª';
    if (isSorani) return 'Ù¾Ø´Ú©Ù†ÛŒÙ†ÛŒ Ø¦Ø§Ù…ÛŽØ± Ùˆ Ø¦ÛŒÙ†ØªÛ•Ø±Ù†ÛŽØª';
    return 'Device & Network Diagnostics';
  }

  String get displayOutput {
    if (isKurmanji) return 'Derketina DÃ®menderÃª';
    if (isSorani) return 'Ø¯Û•Ø±Ú†Û•ÛŒ Ø´Ø§Ø´Û•';
    return 'Display Output';
  }

  String get display4k {
    if (isKurmanji) return 'PiÅŸtgiriya 4K Ultra HD dike';
    if (isSorani) return 'Ù¾Ø´ØªÚ¯ÛŒØ±ÛŒ 4K Ultra HD Ø¯Û•Ú©Ø§Øª';
    return '4K Ultra HD Capable';
  }

  String get display1080p {
    return '1080p Full HD';
  }

  String get display720p {
    return '720p HD Ready';
  }

  String get speedTest {
    if (isKurmanji) return 'Testa Leza ÃŽnternetÃª';
    if (isSorani) return 'Ù¾Ø´Ú©Ù†ÛŒÙ†ÛŒ Ø®ÛŽØ±Ø§ÛŒÛŒ Ø¦ÛŒÙ†ØªÛ•Ø±Ù†ÛŽØª';
    return 'Internet Speed Test';
  }

  String get speedTestSub {
    if (isKurmanji) return 'Leza girÃªdana xwe ji bo weÅŸana 4K/HD biceribÃ®ne';
    if (isSorani) return 'Ø®ÛŽØ±Ø§ÛŒÛŒ Ø¦ÛŒÙ†ØªÛ•Ø±Ù†ÛŽØªÛ•Ú©Û•Øª Ø¨Ù¾Ø´Ú©Ù†Û• Ø¨Û† Ù¾Û•Ø®Ø´ÛŒ 4K/HD';
    return 'Test your connection speed for 4K/HD streaming';
  }

  String speedTestResult(String speed) {
    if (isKurmanji) return 'Encama dawÃ®: $speed Mbps';
    if (isSorani) return 'Ú©Û†ØªØ§ Ø¦Û•Ù†Ø¬Ø§Ù…: $speed Ù…ÛŽÚ¯Ø§Ø¨Ø§ÛŒØª';
    return 'Last result: $speed Mbps';
  }

  String get runTest {
    if (isKurmanji) return 'TEST BIKIN';
    if (isSorani) return 'Ù¾Ø´Ú©Ù†ÛŒÙ† Ø¨Ú©Û•';
    return 'RUN TEST';
  }

  String get sectionSupport {
    if (isKurmanji) return 'PiÅŸtgirÃ® Ã» NÃ»vekirin';
    if (isSorani) return 'Ù¾Ø´ØªÚ¯ÛŒØ±ÛŒ Ùˆ Ù†ÙˆÛŽÚ©Ø±Ø¯Ù†Û•ÙˆÛ•Ú©Ø§Ù†';
    return 'Support & Updates';
  }

  String get checkUpdates {
    if (isKurmanji) return 'Kontrola NÃ»vekirinÃª';
    if (isSorani) return 'Ù¾Ø´Ú©Ù†ÛŒÙ† Ø¨Û† Ù†ÙˆÛŽÚ©Ø±Ø¯Ù†Û•ÙˆÛ•';
    return 'Check for Updates';
  }

  String get checkUpdatesSub {
    if (isKurmanji) return 'PiÅŸtrast be ku taybetmendiyÃªn herÃ® nÃ» li cem te ne';
    if (isSorani) return 'Ø¯ÚµÙ†ÛŒØ§Ø¨Û• Ù„Û•ÙˆÛ•ÛŒ Ù†ÙˆÛŽØªØ±ÛŒÙ† ØªØ§ÛŒØ¨Û•ØªÙ…Û•Ù†Ø¯ÛŒÛŒÛ•Ú©Ø§Ù†Øª Ù‡Û•ÛŒÛ•';
    return 'Ensure you have the latest features';
  }

  String get joinTelegram {
    if (isKurmanji) return 'TevlÃ® Telegrama me bibe';
    if (isSorani) return 'Ø¨Û•Ø´Ø¯Ø§Ø±Ø¨Û• Ù„Û• ØªÛŽÙ„ÛŒÚ¯Ø±Ø§Ù…Û•Ú©Û•Ù…Ø§Ù†';
    return 'Join our Telegram';
  }

  String get joinTelegramSub {
    if (isKurmanji) return 'PiÅŸtgirÃ® Ã» nÃ»Ã§eyÃªn herÃ® nÃ» bistÃ®ne';
    if (isSorani) return 'Ù¾Ø´ØªÚ¯ÛŒØ±ÛŒ Ùˆ Ù†ÙˆÛŽØªØ±ÛŒÙ† Ù‡Û•ÙˆØ§ÚµÛ•Ú©Ø§Ù† ÙˆÛ•Ø±Ø¨Ú¯Ø±Û•';
    return 'Get support and latest news';
  }

  String get whatsNew {
    if (isKurmanji) return 'Ã‡i NÃ» ye?';
    if (isSorani) return 'Ú†ÛŒ Ù†ÙˆÛŽÛŒÛ•ØŸ';
    return 'What\'s New?';
  }

  String get whatsNewKurdish {
    if (isKurmanji) return 'WergerÃª KurdÃ®';
    if (isSorani) return 'ÙˆÛ•Ø±Ú¯ÛŽÚ•ÛŒ Ú©ÙˆØ±Ø¯ÛŒ';
    return 'Kurdish Translator';
  }

  String get whatsNewKurdishSub {
    if (isKurmanji) return 'PiÅŸtgiriya tam a Kurdiya KurmancÃ® hat zÃªdekirin';
    if (isSorani) return 'Ù¾Ø´ØªÚ¯ÛŒØ±ÛŒ ØªÛ•ÙˆØ§ÙˆÛŒ Ú©ÙˆØ±Ø¯ÛŒ Ú©Ø±Ù…Ø§Ù†Ø¬ÛŒ Ø²ÛŒØ§Ø¯Ú©Ø±Ø§';
    return 'Added full Kurdish Kurmanji support';
  }

  String get whatsNewDataSaver {
    if (isKurmanji) return 'Parastina DaneyÃª';
    if (isSorani) return 'Ù¾Ø§Ø´Û•Ú©Û•ÙˆØªÚ©Ø±Ø¯Ù†ÛŒ Ø¯Ø§ØªØ§';
    return 'Data Saver';
  }

  String get whatsNewDataSaverSub {
    if (isKurmanji) return 'Parastina Ã®nternetÃª li ser torÃªn mobÃ®l';
    if (isSorani) return 'Ù¾Ø§Ø´Û•Ú©Û•ÙˆØªÚ©Ø±Ø¯Ù†ÛŒ Ø¦ÛŒÙ†ØªÛ•Ø±Ù†ÛŽØª Ù„Û•Ø³Û•Ø± ØªÛ†Ú•Û•Ú©Ø§Ù†ÛŒ Ù…Û†Ø¨Ø§ÛŒÙ„';
    return 'Save bandwidth on mobile networks';
  }

  String get whatsNewStorage {
    if (isKurmanji) return 'RÃªveberÃª BÃ®rgeyÃª';
    if (isSorani) return 'Ø¨Û•Ú•ÛŽÙˆÛ•Ø¨Û•Ø±ÛŒ Ø¨ÛŒØ±Ú¯Û•';
    return 'Storage Manager';
  }

  String get whatsNewStorageSub {
    if (isKurmanji) return 'Paqijkirina kaÅŸ Ã» posteran bi hÃªsanÃ®';
    if (isSorani) return 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ú©Ø§Ø´ Ùˆ Ù¾Û†Ø³ØªÛ•Ø±Û•Ú©Ø§Ù† Ø¨Û• Ø¦Ø§Ø³Ø§Ù†ÛŒ';
    return 'Clear cache and posters easily';
  }

  // â”€â”€â”€ World Cup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String get wcTitle {
    if (isKurmanji) return 'KÃ»paya CÃ®hanÃª FIFA';
    if (isSorani) return 'Ø¬Ø§Ù…Ø¬Ù‡Ø§Ù†ÛŒ FIFA';
    return 'FIFA World Cup';
  }

  String get wcTabLive {
    if (isKurmanji) return 'ZindÃ®';
    if (isSorani) return 'Ú•Ø§Ø³ØªÛ•ÙˆØ®Û†';
    return 'Live';
  }

  String get wcTabMatches {
    if (isKurmanji) return 'MaÃ§';
    if (isSorani) return 'ÛŒØ§Ø±ÛŒÛŒÛ•Ú©Ø§Ù†';
    return 'Matches';
  }

  String get wcTabGroups {
    if (isKurmanji) return 'Kom';
    if (isSorani) return 'Ú¯Ø±ÙˆÙ¾Û•Ú©Ø§Ù†';
    return 'Groups';
  }

  String get wcTabNews {
    if (isKurmanji) return 'NÃ»Ã§e';
    if (isSorani) return 'Ù‡Û•ÙˆØ§Ú•Û•Ú©Ø§Ù†';
    return 'News';
  }

  String get wcTabScorers {
    if (isKurmanji) return 'Amar';
    if (isSorani) return 'Ø¦Ø§Ù…Ø§Ø±Û•Ú©Ø§Ù†';
    return 'Stats';
  }

  String get wcTabTeams {
    if (isKurmanji) return 'TÃ®m';
    if (isSorani) return 'ØªÛŒÙ…Û•Ú©Ø§Ù†';
    return 'Teams';
  }

  String get wcTabVenues {
    if (isKurmanji) return 'YarÃ®geh';
    if (isSorani) return 'ÛŒØ§Ø±ÛŒÚ¯Ø§Ú©Ø§Ù†';
    return 'Venues';
  }

  String get wcYesterday {
    if (isKurmanji) return 'DuhÃ®';
    if (isSorani) return 'Ø¯ÙˆÛŽÙ†ÛŽ';
    return 'Yesterday';
  }

  String get wcToday {
    if (isKurmanji) return 'ÃŽro';
    if (isSorani) return 'Ø¦Û•Ù…Ú•Û†';
    return 'Today';
  }

  String get wcTomorrow {
    if (isKurmanji) return 'SibÃª';
    if (isSorani) return 'Ø³Ø¨Û•ÛŒ';
    return 'Tomorrow';
  }

  String get wcAfterTomorrow {
    if (isKurmanji) return 'DuyÃª sibÃª';
    if (isSorani) return 'Ø¯ÙˆØ§ØªØ±';
    return 'Next';
  }

  String get wcNoMatches {
    if (isKurmanji) return 'MaÃ§ tune ye di vÃª rojÃª de';
    if (isSorani) return 'Ù‡ÛŒÚ† ÛŒØ§Ø±ÛŒÛŒÛ•Ú© Ù†ÛŒÛŒÛ• Ù„Û•Ù… Ø¨Û•Ø±ÙˆØ§Ø±Û•Ø¯Ø§';
    return 'No matches on this date';
  }

  String get wcNoMatchesFound {
    if (isKurmanji) return 'MaÃ§ nehat dÃ®tin';
    if (isSorani) return 'Ù‡ÛŒÚ† ÛŒØ§Ø±ÛŒ Ù†Û•Ø¯Û†Ø²Ø±Ø§ÛŒÛ•ÙˆÛ•';
    return 'No matches found';
  }

  String get wcGroupStandings {
    if (isKurmanji) return 'RÃªzika KomÃª';
    if (isSorani) return 'Ø®Ø´ØªÛ•ÛŒ Ú¯Ø±ÙˆÙ¾';
    return 'Group Standings';
  }

  String get wcNoGroups {
    if (isKurmanji) return 'Kom nehat dÃ®tin';
    if (isSorani) return 'Ù‡ÛŒÚ† Ú¯Ø±ÙˆÙ¾ÛŽÚ© Ù†Û•Ø¯Û†Ø²Ø±Ø§ÛŒÛ•ÙˆÛ•';
    return 'No groups found';
  }

  String get wcNoNews {
    if (isKurmanji) return 'NÃ»Ã§e tune ye';
    if (isSorani) return 'Ù‡Û•ÙˆØ§Ú• Ø¨Û•Ø±Ø¯Û•Ø³Øª Ù†ÛŒÛŒÛ•';
    return 'No news available';
  }

  String get wcNoScorers {
    if (isKurmanji) return 'AgahÃ® tune ye';
    if (isSorani) return 'Ù‡ÛŒÚ† Ø²Ø§Ù†ÛŒØ§Ø±ÛŒÛŒÛ•Ú© Ø¨Û•Ø±Ø¯Û•Ø³Øª Ù†ÛŒÛŒÛ•';
    return 'No data available';
  }

  String get wcLive {
    if (isKurmanji) return 'ZINDÃŽ';
    if (isSorani) return 'Ú•Ø§Ø³ØªÛ•ÙˆØ®Û†';
    return 'LIVE';
  }

  String get wcUpcoming {
    if (isKurmanji) return 'BÃª';
    if (isSorani) return 'Ø¯Ø§Ù‡Ø§ØªÙˆÙˆ';
    return 'Upcoming';
  }

  String get wcFinished {
    if (isKurmanji) return 'KU';
    if (isSorani) return 'Ú©Û†ØªØ§ÛŒÛŒ';
    return 'FT';
  }

  String get wcCapacity {
    if (isKurmanji) return 'KapasÃ®te';
    if (isSorani) return 'ØªÙˆØ§Ù†Ø§ÛŒ Ù„Û•Ø®Û†Ú¯Ø±ØªÙ†';
    return 'Capacity';
  }

  String get wcLiveWinProbability {
    if (isKurmanji) return 'ÃŽhtÃ®mala SerkeftinÃª ya ZindÃ®';
    if (isSorani) return 'Ø¦Û•Ú¯Û•Ø±ÛŒ Ø¨Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ú•Ø§Ø³ØªÛ•ÙˆØ®Û†';
    return 'Live Win Probability';
  }

  String get wcDraw {
    if (isKurmanji) return 'Beramber';
    if (isSorani) return 'ÛŒÛ•Ú©Ø³Ø§Ù†Ø¨ÙˆÙˆÙ†';
    return 'Draw';
  }

  String get wcSummary {
    if (isKurmanji) return 'Kurte';
    if (isSorani) return 'Ú©ÙˆØ±ØªÛ•';
    return 'Summary';
  }

  String get wcRosters {
    if (isKurmanji) return 'Kadro';
    if (isSorani) return 'Ù¾ÛŽÚ©Ù‡Ø§ØªÛ•';
    return 'Rosters';
  }

  String get wcTimeline {
    if (isKurmanji) return 'RÃªzbÃ»yer';
    if (isSorani) return 'Ú©Ø§ØªÛŒ Ú•ÙˆÙˆØ¯Ø§ÙˆÛ•Ú©Ø§Ù†';
    return 'Timeline';
  }

  String get wcSubstitutes {
    if (isKurmanji) return 'Yedek';
    if (isSorani) return 'ÛŒÛ•Ø¯Û•Ú¯Û•Ú©Ø§Ù†';
    return 'Substitutes';
  }

  String get wcManager {
    if (isKurmanji) return 'RÃªvebir';
    if (isSorani) return 'Ú•Ø§Ù‡ÛŽÙ†Û•Ø±';
    return 'Manager';
  }

  String get wcSquadRoster {
    if (isKurmanji) return 'KadroyÃª TÃ®mÃª';
    if (isSorani) return 'Ù¾ÛŽÚ©Ù‡Ø§ØªÛ•ÛŒ ØªÛŒÙ…';
    return 'Squad Roster';
  }

  String get wcGoalkeepers {
    if (isKurmanji) return 'GoleparÃªz';
    if (isSorani) return 'Ú¯Û†ÚµÙ¾Ø§Ø±ÛŽØ²Û•Ú©Ø§Ù†';
    return 'Goalkeepers';
  }

  String get wcDefenders {
    if (isKurmanji) return 'Parastvan';
    if (isSorani) return 'Ø¨Û•Ø±Ú¯Ø±ÛŒÚ©Ø§Ø±Û•Ú©Ø§Ù†';
    return 'Defenders';
  }

  String get wcMidfielders {
    if (isKurmanji) return 'Navend';
    if (isSorani) return 'ÛŒØ§Ø±ÛŒØ²Ø§Ù†Ø§Ù†ÛŒ Ù†Ø§ÙˆÛ•Ú•Ø§Ø³Øª';
    return 'Midfielders';
  }

  String get wcForwards {
    if (isKurmanji) return 'ÃŠrÃ®ÅŸber';
    if (isSorani) return 'Ù‡ÛŽØ±Ø´Ø¨Û•Ø±Û•Ú©Ø§Ù†';
    return 'Forwards';
  }

  String get wcNoRosterData {
    if (isKurmanji) return 'DaneyÃªn kadro tune';
    if (isSorani) return 'Ù‡ÛŒÚ† Ø¯Ø§ØªØ§ÛŒÛ•Ú©ÛŒ Ù¾ÛŽÚ©Ù‡Ø§ØªÛ• Ù†ÛŒÛŒÛ•';
    return 'No roster data available';
  }
}



