import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user preferences (read by [SettingsScreen] and [PlayerScreen]).
class AppSettingsData {
  final bool keepScreenOnWhilePlaying;
  final BoxFit videoFit;
  final bool autoHidePlayerControls;
  final bool showOnScreenClock;
  final bool tvFriendlyLayout;
  final bool reduceMotion;

  const AppSettingsData({
    this.keepScreenOnWhilePlaying = true,
    this.videoFit = BoxFit.contain,
    this.autoHidePlayerControls = true,
    this.showOnScreenClock = false,
    this.tvFriendlyLayout = false,
    this.reduceMotion = false,
  });

  static Future<AppSettingsData> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettingsData(
      keepScreenOnWhilePlaying: p.getBool(_kKeepScreenOn) ?? true,
      videoFit: _decodeFit(p.getString(_kVideoFit) ?? 'contain'),
      autoHidePlayerControls: p.getBool(_kAutoHideControls) ?? true,
      showOnScreenClock: p.getBool(_kShowClock) ?? false,
      tvFriendlyLayout: p.getBool(_kTvLayout) ?? false,
      reduceMotion: p.getBool(_kReduceMotion) ?? false,
    );
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kKeepScreenOn, keepScreenOnWhilePlaying);
    await p.setString(_kVideoFit, _encodeFit(videoFit));
    await p.setBool(_kAutoHideControls, autoHidePlayerControls);
    await p.setBool(_kShowClock, showOnScreenClock);
    await p.setBool(_kTvLayout, tvFriendlyLayout);
    await p.setBool(_kReduceMotion, reduceMotion);
  }

  AppSettingsData copyWith({
    bool? keepScreenOnWhilePlaying,
    BoxFit? videoFit,
    bool? autoHidePlayerControls,
    bool? showOnScreenClock,
    bool? tvFriendlyLayout,
    bool? reduceMotion,
  }) {
    return AppSettingsData(
      keepScreenOnWhilePlaying: keepScreenOnWhilePlaying ?? this.keepScreenOnWhilePlaying,
      videoFit: videoFit ?? this.videoFit,
      autoHidePlayerControls: autoHidePlayerControls ?? this.autoHidePlayerControls,
      showOnScreenClock: showOnScreenClock ?? this.showOnScreenClock,
      tvFriendlyLayout: tvFriendlyLayout ?? this.tvFriendlyLayout,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  static String _encodeFit(BoxFit fit) {
    return switch (fit) {
      BoxFit.contain => 'contain',
      BoxFit.cover => 'cover',
      BoxFit.fill => 'fill',
      BoxFit.fitWidth => 'fitWidth',
      BoxFit.fitHeight => 'fitHeight',
      BoxFit.scaleDown => 'scaleDown',
      BoxFit.none => 'none',
    };
  }

  static BoxFit _decodeFit(String key) {
    return switch (key) {
      'cover' => BoxFit.cover,
      'fill' => BoxFit.fill,
      'fitWidth' => BoxFit.fitWidth,
      'fitHeight' => BoxFit.fitHeight,
      'scaleDown' => BoxFit.scaleDown,
      'none' => BoxFit.none,
      _ => BoxFit.contain,
    };
  }

  static String labelForFit(BoxFit fit) {
    return switch (fit) {
      BoxFit.contain => 'Contain (letterbox)',
      BoxFit.cover => 'Cover (crop)',
      BoxFit.fill => 'Stretch',
      BoxFit.fitWidth => 'Fit width',
      BoxFit.fitHeight => 'Fit height',
      BoxFit.scaleDown => 'Scale down',
      BoxFit.none => 'None (native size)',
    };
  }
}

const _kKeepScreenOn = 'settings_keep_screen_on';
const _kVideoFit = 'settings_video_fit';
const _kAutoHideControls = 'settings_auto_hide_controls';
const _kShowClock = 'settings_show_clock';
const _kTvLayout = 'settings_tv_layout';
const _kReduceMotion = 'settings_reduce_motion';
