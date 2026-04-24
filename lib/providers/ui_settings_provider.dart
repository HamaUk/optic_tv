import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// A [NotifierProvider] so that calling [invalidate] (or [state = …])
/// triggers a *synchronous* rebuild of all widgets that watch this provider,
/// instead of going through the async [FutureProvider] loading cycle which
/// drops the value back to the default while re-fetching.
class AppUiSettingsNotifier extends AsyncNotifier<AppSettingsData> {
  @override
  Future<AppSettingsData> build() => AppSettingsData.load();

  Future<void> apply(AppSettingsData next) async {
    await next.persist();
    state = AsyncData(next);
  }
}

final appUiSettingsProvider =
    AsyncNotifierProvider<AppUiSettingsNotifier, AppSettingsData>(
  AppUiSettingsNotifier.new,
);
