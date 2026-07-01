import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../core/theme.dart';
import '../l10n/app_strings.dart';
import '../services/update_service.dart';

enum DownloadState { idle, downloading, ready, error }

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
  DownloadState _state = DownloadState.idle;
  double _progress = 0.0;
  String? _savePath;
  String _errorMessage = '';
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = DownloadState.downloading;
      _progress = 0.0;
      _errorMessage = '';
    });

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Cannot access storage directory");
      
      _savePath = '${dir.path}/update_v${widget.updateData.versionName}.apk';
      _cancelToken = CancelToken();

      final dio = Dio();
      await dio.download(
        widget.updateData.apkUrl,
        _savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _state = DownloadState.ready;
      });
      
      _installApk();
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) return;
      setState(() {
        _state = DownloadState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _installApk() async {
    if (_savePath != null) {
      await OpenFilex.open(_savePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final d = widget.updateData;

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
                    s.updateAvailable,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.updateVersion(d.versionName),
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
                      s.updateReleaseNotesEmpty(d.releaseNotes),
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Interactive State Area
                  if (_state == DownloadState.idle)
                    _buildButton('DOWNLOAD UPDATE', Icons.download_rounded, _startDownload)
                  else if (_state == DownloadState.downloading)
                    _buildProgress()
                  else if (_state == DownloadState.ready)
                    _buildButton('INSTALL NOW', Icons.offline_share_rounded, _installApk)
                  else if (_state == DownloadState.error)
                    Column(
                      children: [
                        Text(
                          'Download Failed\n$_errorMessage',
                          style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        _buildButton('RETRY DOWNLOAD', Icons.refresh_rounded, _startDownload),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: AppTheme.primaryGold.withOpacity(0.4),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Downloading update...',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              '${(_progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: AppTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
        ),
      ],
    );
  }
}

