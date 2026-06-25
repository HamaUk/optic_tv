import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

/// Persisted user preferences (read by [SettingsScreen] and [PlayerScreen]).
class AppSettingsData {
  final bool keepScreenOnWhilePlaying;
  final BoxFit videoFit;
  final bool autoHidePlayerControls;
  final bool showOnScreenClock;
  final bool reduceMotion;
  final AppGradientPreset gradientPreset;
  final double subtitleFontSize;
  final int subtitleColor; // ARGB
  final int subtitleBgColor; // ARGB
  final bool dataSaverMode;
  final bool hardwareAcceleration;

  const AppSettingsData({
    this.keepScreenOnWhilePlaying = true,
    this.videoFit = BoxFit.fill,
    this.autoHidePlayerControls = true,
    this.showOnScreenClock = false,
    this.reduceMotion = true, // Changed to true per request
    this.gradientPreset = AppGradientPreset.emberGlow,
    this.subtitleFontSize = 20.0,
    this.subtitleColor = 0xFFFFFFFF, // White
    this.subtitleBgColor = 0x73000000, // 45% Black
    this.dataSaverMode = false,
    this.hardwareAcceleration = true,
  });

  static Future<AppSettingsData> load() async {
    final p = await SharedPreferences.getInstance();

    return AppSettingsData(
      keepScreenOnWhilePlaying: p.getBool(_kKeepScreenOn) ?? true,
      videoFit: _decodeFit(p.getString(_kVideoFit) ?? 'fill'),
      autoHidePlayerControls: p.getBool(_kAutoHideControls) ?? true,
      showOnScreenClock: p.getBool(_kShowClock) ?? false,
      reduceMotion: p.getBool(_kReduceMotion) ?? true, // Changed fallback to true
      gradientPreset: _decodeGradientPreset(p.getString(_kGradientPreset)),
      subtitleFontSize: p.getDouble(_kSubtitleFontSize) ?? 20.0,
      subtitleColor: p.getInt(_kSubtitleColor) ?? 0xFFFFFFFF,
      subtitleBgColor: p.getInt(_kSubtitleBgColor) ?? 0x73000000,
      dataSaverMode: p.getBool(_kDataSaverMode) ?? false,
      hardwareAcceleration: p.getBool(_kHardwareAcceleration) ?? true,
    );
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kKeepScreenOn, keepScreenOnWhilePlaying);
    await p.setString(_kVideoFit, _encodeFit(videoFit));
    await p.setBool(_kAutoHideControls, autoHidePlayerControls);
    await p.setBool(_kShowClock, showOnScreenClock);
    await p.setBool(_kReduceMotion, reduceMotion);
    await p.setString(_kGradientPreset, gradientPreset.name);
    await p.setDouble(_kSubtitleFontSize, subtitleFontSize);
    await p.setInt(_kSubtitleColor, subtitleColor);
    await p.setInt(_kSubtitleBgColor, subtitleBgColor);
    await p.setBool(_kDataSaverMode, dataSaverMode);
    await p.setBool(_kHardwareAcceleration, hardwareAcceleration);
  }

  AppSettingsData copyWith({
    bool? keepScreenOnWhilePlaying,
    BoxFit? videoFit,
    bool? autoHidePlayerControls,
    bool? showOnScreenClock,
    bool? reduceMotion,
    AppGradientPreset? gradientPreset,
    double? subtitleFontSize,
    int? subtitleColor,
    int? subtitleBgColor,
    bool? dataSaverMode,
    bool? hardwareAcceleration,
  }) {
    return AppSettingsData(
      keepScreenOnWhilePlaying: keepScreenOnWhilePlaying ?? this.keepScreenOnWhilePlaying,
      videoFit: videoFit ?? this.videoFit,
      autoHidePlayerControls: autoHidePlayerControls ?? this.autoHidePlayerControls,
      showOnScreenClock: showOnScreenClock ?? this.showOnScreenClock,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      gradientPreset: gradientPreset ?? this.gradientPreset,
      subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitleBgColor: subtitleBgColor ?? this.subtitleBgColor,
      dataSaverMode: dataSaverMode ?? this.dataSaverMode,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
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
      _ => BoxFit.fill,
    };
  }

  static AppGradientPreset _decodeGradientPreset(String? raw) {
    if (raw == null) return AppGradientPreset.emberGlow;
    return AppGradientPreset.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AppGradientPreset.emberGlow,
    );
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
const _kReduceMotion = 'settings_reduce_motion';
const _kGradientPreset = 'settings_gradient_preset';
const _kSubtitleFontSize = 'settings_subtitle_font_size';
const _kSubtitleColor = 'settings_subtitle_color';
const _kSubtitleBgColor = 'settings_subtitle_bg_color';
const _kDataSaverMode = 'settings_data_saver_mode';
const _kHardwareAcceleration = 'settings_hardware_acceleration';
