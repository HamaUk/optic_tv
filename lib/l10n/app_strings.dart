import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// UI strings — English only (stable Material localizations + system fonts).
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  String get loginTitle => 'Welcome back';
  String get loginSubtitle => 'Enter your access code to continue';
  String get loginHint => '☆☆☆☆☆☆';
  String get loginButton => 'Continue';
  String get loginErrorEmpty => 'Enter a code';
  String get loginErrorInvalid => 'Code not recognized';
  String get loginErrorNetwork => 'Check connection and try again';

  String get appBrand => 'OPTIC TV';
  String get appTagline => 'Premium entertainment';
  String get noChannels => 'No channels yet';
  String get noChannelsHint => 'They appear when your library syncs.';
  String get nowPlaying => 'Featured';
  String get watchNow => 'Watch';
  String get channelLoadError => 'Could not load channels';
  String get settingsTooltip => 'Settings';

  String get settingsTitle => 'Settings';
  String get sectionPlayback => 'Playback';
  String get sectionVideo => 'Video fit';
  String get sectionInterface => 'Interface';
  String get sectionAccount => 'Account';
  String get sectionAbout => 'About';

  String get keepScreenOnTitle => 'Keep screen on';
  String get keepScreenOnSub => 'While video is playing';
  String get autoHideTitle => 'Hide controls';
  String get autoHideSub => 'Fade player bars; tap to show';
  String get clockTitle => 'Clock in player';
  String get clockSub => 'Time in top bar';
  String get videoFitCaption => 'How video fills the screen';
  String get tvLayoutTitle => 'TV-friendly spacing';
  String get tvLayoutSub => 'Larger rows for remote / D-pad';
  String get reduceMotionTitle => 'Reduce motion';
  String get reduceMotionSub => 'Shorter animations';
  String get logoutTitle => 'Sign out';
  String get logoutSub => 'Clear login on this device';
  String get logoutButton => 'Sign out';

  String get aboutTitle => 'Optic TV';
  String get aboutSub => 'Version 1.0.0 · IPTV';

  String fitLabel(BoxFit fit) => AppSettingsData.labelForFit(fit);

  String get fullscreenTooltip => 'Fullscreen';

  String get navHome => 'Home';
  String get navMovies => 'Movies';
  String get navSport => 'Sport';
  String get searchHint => 'Search channels…';
  String get categoriesTitle => 'Categories';
  String get channelListTitle => 'Channel list';
  String get noChannelsInSection => 'No channels in this section';
}
