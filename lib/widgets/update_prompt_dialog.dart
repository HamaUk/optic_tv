import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme.dart';
import '../l10n/app_strings.dart';
import '../services/update_service.dart';

class UpdatePromptDialog extends StatefulWidget {
  final AppUpdateData updateData;
  final AppStrings strings;

  const UpdatePromptDialog({super.key, required this.updateData, required this.strings});

  static Future<void> show(BuildContext context, AppUpdateData data, AppStrings strings) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdatePromptDialog(updateData: data, strings: strings),
    );
  }

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  static const _channel = MethodChannel('com.optic.iptv/device');
  bool _isDownloading = false;
  bool _isFinished = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _apkPath;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = widget.strings.updatePreparing;
    });

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('Cannot access storage');

      final apkFile = File('${dir.path}/update_${widget.updateData.versionCode}.apk');
      _apkPath = apkFile.path;

      final dio = Dio();
      await dio.download(
        widget.updateData.apkUrl,
        apkFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              final mbReceived = (received / 1048576).toStringAsFixed(1);
              final mbTotal = (total / 1048576).toStringAsFixed(1);
              _statusText = widget.strings.updateDownloading(mbReceived, mbTotal);
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _isFinished = true;
        _statusText = widget.strings.updateDownloadComplete;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusText = widget.strings.updateDownloadFailed;
      });
    }
  }

  Future<void> _install() async {
    if (_apkPath == null) return;
    try {
      await _channel.invokeMethod('installApk', {'apkPath': _apkPath});
    } catch (e) {
      debugPrint('Install failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryGold.withOpacity(0.15), blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppTheme.primaryGold, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.strings.updateAvailable,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.strings.updateVersion(widget.updateData.versionName),
                  style: const TextStyle(color: AppTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.strings.updateReleaseNotesEmpty(widget.updateData.releaseNotes),
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isDownloading) ...[
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    color: AppTheme.primaryGold,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 12),
                  Text(_statusText, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ] else if (_isFinished) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _install,
                      child: Text(widget.strings.updateInstall, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _startDownload,
                      child: Text(widget.strings.updateDownload, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
