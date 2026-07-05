import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Future<void> _openTelegram() async {
    final url = Uri.parse('https://t.me/KOBANI_APP');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final d = widget.updateData;

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
                    child: Column(
                      children: [
                        Text(
                          "A new update is available! Please go to our Telegram channel to install the new update.",
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.updateReleaseNotesEmpty(d.releaseNotes),
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Telegram Link Button
                  SizedBox(
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
                      onPressed: _openTelegram,
                      icon: const Icon(Icons.send_rounded, size: 28),
                      label: const Text(
                        "https://t.me/KOBANI_APP",
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
