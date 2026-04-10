import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _codeFocus.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppStrings s) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loginErrorEmpty)),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await ref.read(sessionActionsProvider).loginWithCode(code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loginErrorInvalid)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(Localizations.localeOf(context));
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      resizeToAvoidBottomInset: false, // Prevents keyboard from shrinking the view and causing overflow errors
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F14), Color(0xFF151B24), Color(0xFF0B0F14)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers everything vertically
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 42,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title & Subtitle
              Text(
                s.loginTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.loginSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              
              // Custom Input Box
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      Container(
                        height: 56, // STRICT PHYSICAL BOUNDARY
                        clipBehavior: Clip.hardEdge, // PREVENTS OVERFLOWING IF IT CRASHES
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2430), // Solid dark color
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: const InputDecorationTheme(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                ),
                                child: TextField(
                                  focusNode: _codeFocus,
                                  controller: _codeController,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                  cursorColor: AppTheme.primaryGold,
                                  onSubmitted: (_) => _submit(s),
                                  decoration: InputDecoration(
                                    hintText: s.loginHint,
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                                // ALWAYS VISIBLE SUBMIT BUTTON
                                IconButton(
                                  onPressed: _busy ? null : () => _submit(s),
                                  icon: _busy
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
                                        )
                                      : const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGold, size: 28),
                                ), // closes IconButton
                              ],
                            ), // closes Row
                        ), // closes Container
                        const SizedBox(height: 24),
                        
                        // Full Login Button (Redundant but keeps UI consistent)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _busy ? null : () => _submit(s),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: AppTheme.primaryGold.withOpacity(0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                                  )
                                : Text(
                                    s.loginButton,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
