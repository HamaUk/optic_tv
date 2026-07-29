import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ota_update/ota_update.dart';

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
  OtaEvent? _currentEvent;
  bool _isDownloading = false;

  Future<void> _launchUpdateUrl() async {
    // Mark this URL as handled so we never show this popup again for this URL
    await markUpdateUrlHandled(widget.updateData.apkUrl);
    
    setState(() {
      _isDownloading = true;
    });

    try {
      OtaUpdate()
          .execute(
            widget.updateData.apkUrl,
            destinationFilename: 'optic_tv_update.apk',
            androidProviderAuthority: 'com.kobani4k.app.fileprovider',
          )
          .listen((OtaEvent event) {
        if (!mounted) return;
        setState(() => _currentEvent = event);
      });
    } catch (e) {
      debugPrint('Failed to make OTA update. Details: $e');
      // Fallback to browser
      final url = Uri.parse(widget.updateData.apkUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents closing the dialog with the back button
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
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.15), blurRadius: 40),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.rocket_launch_rounded, color: Theme.of(context).primaryColor, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "UPDATE AVAILABLE",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Optic TV is getting better",
                    style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "New update available! Let's update it to enjoy the latest features and improved stability.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.5, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isDownloading) ...[
                    _buildDownloadProgress(),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _launchUpdateUrl,
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text("LET'S UPDATE IT", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final status = _currentEvent?.status ?? OtaStatus.DOWNLOADING;
    final value = _currentEvent?.value ?? "0";
    
    String label = "Downloading...";
    if (status == OtaStatus.DOWNLOADING) label = "Downloading Update... $value%";
    if (status == OtaStatus.INSTALLING) label = "Installing... Please wait.";
    if (status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) label = "Storage Permission Required";
    if (status == OtaStatus.INTERNAL_ERROR) label = "Update Failed. Please try again later.";
    
    final double progress = double.tryParse(value) != null ? double.parse(value) / 100.0 : 0.0;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (status == OtaStatus.DOWNLOADING)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              minHeight: 8,
            ),
          )
        else if (status != OtaStatus.INSTALLING)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Close"),
          )
      ],
    );
  }
}
