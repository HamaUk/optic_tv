import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

final appUiSettingsProvider = FutureProvider<AppSettingsData>((ref) => AppSettingsData.load());
