import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/pocketbase_database_mock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/notification_service.dart';

import '../../services/playlist_service.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/channel_logo_image.dart';
import '../../services/tmdb_service.dart';
import '../../services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'tabs/admin_overview_tab.dart';
part 'tabs/admin_channels_tab.dart';
part 'tabs/admin_publish_tab.dart';
part 'tabs/admin_import_tab.dart';
part 'tabs/admin_access_tab.dart';
part 'tabs/admin_announcement_tab.dart';
part 'tabs/admin_movies_tab.dart';
part 'tabs/admin_update_tab.dart';

enum _PublishShelf { liveTv, movies, custom }
enum _LoginDuration { day, week, month, year, never }

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {

  void setAdminState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  static const _playlistPath = 'sync/global/managedPlaylist';
  static const _groupsPath = 'sync/global/channelGroups';
  static const _loginCodesPath = 'sync/global/loginCodes';
  static const _announcementPath = 'sync/global/announcement';
  static const _notifBroadcastPath = 'sync/global/notifications/broadcast';
  static const _notifHistoryPath = 'sync/global/notifications/history';
  static const _backupFileVersion = 1;

  final _channelNameController = TextEditingController();
  final _channelUrlController = TextEditingController();
  final _channelGroupController = TextEditingController();
  final _channelLogoController = TextEditingController();
  final _channelBackdropController = TextEditingController();
  final _channelSubtitleUrlController = TextEditingController();
  final _channelUserAgentController = TextEditingController(text: 'SmartIPTV');
  final _channelUrl2Controller = TextEditingController();
  final _channelUrl2NameController = TextEditingController();
  final _channelUrl3Controller = TextEditingController();
  final _channelUrl3NameController = TextEditingController();
  final _channelRefererController = TextEditingController();
  final _channelDrmSchemeController = TextEditingController();
  final _channelDrmLicenseController = TextEditingController();
  final _newGroupController = TextEditingController();
  final _newLoginCodeController = TextEditingController();
  final _channelSearchController = TextEditingController();
  bool _isFeaturedAdmin = false;
  String _channelType = 'live';
  final _announcementController = TextEditingController();
  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();
  final _notifImageController = TextEditingController();

  // Update Manager State
  final _updateApkUrlController = TextEditingController();
  bool _updateIsActive = false;

  // Admin Auth Shield State
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAuthenticating = false;
  bool _isAuthenticated = false;
  String? _authError;

  // Import tab controllers
  final _importUrlController = TextEditingController();
  final _xtreamServerController = TextEditingController();
  final _xtreamUserController = TextEditingController();
  final _xtreamPassController = TextEditingController();

  late TabController _tabController;
  String _channelSearchQuery = '';
  String? _groupFilter;
  _PublishShelf _publishShelf = _PublishShelf.liveTv;
  bool _backupBusy = false;
  final Set<String> _selectedKeys = {};

  // Import state
  bool _importBusy = false;
  List<Map<String, String>>? _importPreview;
  String _importStatus = '';

  // Bulk movie import state
  bool _importMoviesBusy = false;
  double _importMoviesProgress = 0;
  int _importMoviesTotal = 0;
  int _importMoviesDone = 0;
  String _importMoviesStatus = '';
  String _importMoviesCurrentTitle = '';

  // Health checker state

  _LoginDuration _selectedLoginDuration = _LoginDuration.month;

  DatabaseReference get _playlistRef => PocketBaseDatabase.instance.ref(_playlistPath);
  DatabaseReference get _groupsRef => PocketBaseDatabase.instance.ref(_groupsPath);
  DatabaseReference get _loginCodesRef => PocketBaseDatabase.instance.ref(_loginCodesPath);
  DatabaseReference get _announcementRef => PocketBaseDatabase.instance.ref(_announcementPath);
  DatabaseReference get _notifBroadcastRef => PocketBaseDatabase.instance.ref(_notifBroadcastPath);
  DatabaseReference get _notifHistoryRef => PocketBaseDatabase.instance.ref(_notifHistoryPath);

  @override
  void initState() {
    super.initState();
    _isAuthenticated = AuthService.isAdmin;
    _tabController = TabController(length: 8, vsync: this);
    _channelGroupController.text = 'Live TV';
    _channelSearchController.addListener(() {
      setState(() => _channelSearchQuery = _channelSearchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _channelNameController.dispose();
    _channelUrlController.dispose();
    _channelGroupController.dispose();
    _channelLogoController.dispose();
    _channelBackdropController.dispose();
    _channelSubtitleUrlController.dispose();
    _channelUserAgentController.dispose();
    _channelUrl2Controller.dispose();
    _channelUrl2NameController.dispose();
    _channelUrl3Controller.dispose();
    _channelUrl3NameController.dispose();
    _channelRefererController.dispose();
    _channelDrmSchemeController.dispose();
    _channelDrmLicenseController.dispose();
    _newGroupController.dispose();
    _newLoginCodeController.dispose();
    _channelSearchController.dispose();
    _importUrlController.dispose();
    _xtreamServerController.dispose();
    _xtreamUserController.dispose();
    _xtreamPassController.dispose();
    _announcementController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    _notifImageController.dispose();
    _updateApkUrlController.dispose();
    super.dispose();
  }

  /// Admin portal is always English copy, LTR layout, and default Latin typography (no Rabar).
  Widget _adminEnglishLtr(Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: AppTheme.darkTheme.copyWith(
          // Override the global white fillColor for inputs inside admin portal
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.7), width: 1.5),
            ),
          ),
        ),
        child: Stack(
          children: [
            child,
            if (!_isAuthenticated) _buildLoginShield(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginShield() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _glassContainer(
                  borderRadius: BorderRadius.circular(32),
                  blur: 30,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Icon(Icons.shield_rounded, color: Theme.of(context).primaryColor, size: 72),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ADMIN PORTAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'RESTRICTED INFRASTRUCTURE ACCESS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.7), 
                            fontSize: 11, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildGlassTextField(
                          controller: _emailController,
                          label: 'Admin Email',
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                        ),
                        if (_authError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _authError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        _buildAdminButton(
                          onPressed: _isAuthenticating ? null : _performAuth,
                          label: 'AUTHORIZE ACCESS',
                          isLoading: _isAuthenticating,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white10)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Expanded(child: Divider(color: Colors.white10)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildGoogleButton(),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'CANCEL & EXIT', 
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.6), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAdminButton({required VoidCallback? onPressed, required String label, bool isLoading = false}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
            : Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: _isAuthenticating ? null : _performGoogleAuth,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          const Text('SIGN IN WITH GOOGLE', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _glassContainer({required Widget child, required BorderRadius borderRadius, double blur = 12}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _performAuth() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _authError = 'Enter both email and password');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      await AuthService.signIn(email, pass);
      setState(() {
        _isAuthenticating = false;
        _isAuthenticated = true;
      });
      _snack('Authenticated as Owner');
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authError = 'Shield Check Failed: $e';
      });
    }
  }

  Future<void> _performGoogleAuth() async {
    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) {
        // User cancelled
        setState(() => _isAuthenticating = false);
        return;
      }
      setState(() {
        _isAuthenticating = false;
        _isAuthenticated = true;
      });
      _snack('Authenticated as Owner (Google)');
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authError = 'Shield Check Failed (Google): $e';
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFF7F1D1D) : AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Map<String, dynamic> _channelPayload({
    required String name,
    required String url,
    required String group,
    required String logo,
    String? backdrop,
    String? subtitleUrl,
    String? type,
    bool? featured,
    int? order,
    String? userAgent,
    String? url2,
    String? url2Name,
    String? url3,
    String? url3Name,
    String? referer,
    String? drmScheme,
    String? drmLicense,
  }) {
    final map = <String, dynamic>{
      'name': name,
      'url': url,
      'group': group.isEmpty ? 'General' : group,
    };
    if (logo.isNotEmpty) map['logo'] = logo;
    if (backdrop != null && backdrop.isNotEmpty) map['backdrop'] = backdrop;
    if (subtitleUrl != null && subtitleUrl.isNotEmpty) map['subtitleUrl'] = subtitleUrl;
    if (type != null) map['type'] = type;
    if (featured == true) map['featured'] = true;
    if (order != null) map['order'] = order;
    if (userAgent != null && userAgent.isNotEmpty) map['userAgent'] = userAgent;
    if (url2 != null && url2.isNotEmpty) map['url2'] = url2;
    if (url2Name != null && url2Name.isNotEmpty) map['url2Name'] = url2Name;
    if (url3 != null && url3.isNotEmpty) map['url3'] = url3;
    if (url3Name != null && url3Name.isNotEmpty) map['url3Name'] = url3Name;
    if (referer != null && referer.isNotEmpty) map['referer'] = referer;
    if (drmScheme != null && drmScheme.isNotEmpty) map['drmScheme'] = drmScheme;
    if (drmLicense != null && drmLicense.isNotEmpty) map['drmLicense'] = drmLicense;
    return map;
  }

  List<MapEntry<dynamic, dynamic>> _parsePlaylist(dynamic raw) {
    if (raw == null) return [];
    if (raw is Map) return raw.entries.toList();
    if (raw is List) {
      final items = <MapEntry<dynamic, dynamic>>[];
      for (var i = 0; i < raw.length; i++) {
        final v = raw[i];
        if (v is Map) items.add(MapEntry('$i', v));
      }
      return items;
    }
    return [];
  }

  void _sortChannelEntries(List<MapEntry<dynamic, dynamic>> items) {
    items.sort((a, b) {
      final av = a.value;
      final bv = b.value;
      if (av is Map && bv is Map) {
        final ao = av['order'] as int? ?? 999999;
        final bo = bv['order'] as int? ?? 999999;
        if (ao != bo) return ao.compareTo(bo);
      }
      final an = (av is Map) ? '${av['name']}' : '';
      final bn = (bv is Map) ? '${bv['name']}' : '';
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });
  }

  String _resolvedPublishGroup() {
    switch (_publishShelf) {
      case _PublishShelf.liveTv:
        return 'Live TV';
      case _PublishShelf.movies:
        return 'Movies';
      case _PublishShelf.custom:
        return _channelGroupController.text.trim();
    }
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    _snack('Stream URL copied');
  }

  bool _isCodeExpired(dynamic expiresAt) {
    if (expiresAt == null) return false;
    try {
      final dt = DateTime.parse('$expiresAt');
      return DateTime.now().toUtc().isAfter(dt);
    } catch (_) {
      return false;
    }
  }

  Widget _durationChip(String label, _LoginDuration duration) {
    final selected = _selectedLoginDuration == duration;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (val) {
          if (val) setState(() => _selectedLoginDuration = duration);
        },
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.35),
      ),
    );
  }

  String _formatExpiry(dynamic expiresAt) {
    if (expiresAt == null) return 'Never expires';
    try {
      final dt = DateTime.parse('$expiresAt').toLocal();
      final now = DateTime.now();
      final diff = dt.difference(now);
      if (diff.isNegative) return 'EXPIRED';

      final y = dt.year;
      final m = dt.month;
      final d = dt.day;
      return 'Expires: $y-$m-$d';
    } catch (_) {
      return 'Invalid date';
    }
  }

  List<Map<String, String>> _parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <Map<String, String>>[];
    String? name, group, logo;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('#EXTINF:')) {
        final nameMatch = RegExp(r"""(?:tvg-name|name)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^,\s\t]+))""", caseSensitive: false).firstMatch(line);
        final logoMatch = RegExp(r"""(?:tvg-logo|logo|icon)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^,\s\t]+))""", caseSensitive: false).firstMatch(line);
        final groupMatch = RegExp(r"""(?:group-title|group|category)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^,\s\t]+))""", caseSensitive: false).firstMatch(line);

        name = nameMatch?.group(1) ?? nameMatch?.group(2) ?? nameMatch?.group(3);
        logo = logoMatch?.group(1) ?? logoMatch?.group(2) ?? logoMatch?.group(3);
        group = groupMatch?.group(1) ?? groupMatch?.group(2) ?? groupMatch?.group(3);

        // Fallback: channel name after the last comma.
        if (name == null || name.isEmpty) {
          final commaIndex = line.lastIndexOf(',');
          if (commaIndex >= 0) {
            name = line.substring(commaIndex + 1).trim();
          }
        }
      } else if (line.isNotEmpty && !line.startsWith('#') && name != null) {
        channels.add({
          'name': name,
          'url': line,
          'group': group ?? 'General',
          if (logo != null && logo.isNotEmpty) 'logo': logo,
        });
        name = null;
        group = null;
        logo = null;
      }
    }
    return channels;
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {int maxLines = 1, FocusNode? focusNode}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      focusNode: focusNode,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.8), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.7), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _sheetField(TextEditingController c, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.85), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.7), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return _glassContainer(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      blur: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded, color: Theme.of(context).primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'CONTROL CENTER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
              tabs: const [
                Tab(text: 'OVERVIEW'),
                Tab(text: 'CHANNELS'),
                Tab(text: 'MOVIES'),
                Tab(text: 'PUBLISH'),
                Tab(text: 'IMPORT'),
                Tab(text: 'ACCESS'),
                Tab(text: 'BROADCAST'),
                Tab(text: 'UPDATE'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _adminEnglishLtr(
      Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAdminHeader(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_overview'),
                      child: _KeepAliveTab(child: _buildOverviewTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_channels'),
                      child: _KeepAliveTab(child: _buildChannelsTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_movies'),
                      child: _KeepAliveTab(child: _buildMoviesTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_publish'),
                      child: _KeepAliveTab(child: _buildPublishTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_import'),
                      child: _KeepAliveTab(child: _buildImportTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_access'),
                      child: _KeepAliveTab(child: _buildAccessTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_announcement'),
                      child: _KeepAliveTab(child: _buildAnnouncementTab()),
                    ),
                    KeyedSubtree(
                      key: const PageStorageKey<String>('admin_update'),
                      child: _KeepAliveTab(child: _buildUpdateTab()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceElevated,
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ],
      ),
    );
  }

  Widget _monoPath(String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SelectableText(
        path,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: AppTheme.accentTeal.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return _glassContainer(
      borderRadius: BorderRadius.circular(22),
      blur: 15,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _adminChannelListTile(MapEntry<dynamic, dynamic> entry, {int? position}) {
    final key = '${entry.key}';
    final val = entry.value as Map;
    final logo = val['logo'] ?? val['icon_url'];
    final name = '${val['name'] ?? 'Untitled'}';
    final grp = '${val['group'] ?? val['category'] ?? 'General'}';
    final url = '${val['url'] ?? ''}';
    final isSelected = _selectedKeys.contains(key);

    return Material(
      color: isSelected ? AppTheme.accentTeal.withValues(alpha: 0.12) : AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showEditChannelDialog(key, val),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedKeys.add(key);
                    } else {
                      _selectedKeys.remove(key);
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              if (position != null) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    '#$position',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.accentTeal : Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: logo != null && '$logo'.isNotEmpty
                    ? ChannelLogoImage(
                        logo: '$logo',
                        channelName: name,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        fallback: _channelPlaceholder(),
                      )
                    : _channelPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isSelected ? AppTheme.accentTeal : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        grp,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentTeal.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _tileActions(key, name, val, url),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileActions(String key, String name, Map val, String url) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_groupFilter != null && _channelSearchQuery.isEmpty)
          Icon(Icons.drag_handle_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Copy URL',
          icon: Icon(Icons.copy_rounded, color: Theme.of(context).primaryColor.withValues(alpha: 0.85), size: 20),
          onPressed: url.isEmpty ? null : () => _copyUrl(url),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Duplicate',
          icon: const Icon(Icons.control_point_duplicate_rounded, size: 20),
          onPressed: () => _prefillAddFromChannel(val),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          onPressed: () => _deleteChannel(key, name),
        ),
      ],
    );
  }

  Widget _channelPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.white.withValues(alpha: 0.06),
      child: Icon(Icons.tv_rounded, color: Colors.white.withValues(alpha: 0.25)),
    );
  }

  DatabaseReference get _updateRef => PocketBaseDatabase.instance.ref('sync/global/updateManager');

}

/// Keeps admin [TabBarView] pages alive when switching tabs (avoids grey flicker / rebuild races).
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
