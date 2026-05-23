import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pingpic/l10n/app_localizations.dart';
import 'package:pingpic/core/utils/firebase_error_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _doLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final usernameOrEmail = _usernameCtrl.text.trim();
    final password = _pwdCtrl.text;

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      setState(() {
        _error = l10n.loginFillAllFields;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final errorMsg = await authProvider.login(usernameOrEmail, password);

    if (errorMsg == null) {
      if (!mounted) return;
      context.go('/home');
    } else {
      setState(() {
        _isLoading = false;
        _error = FirebaseErrorHelper.getLocalizedError(context, errorMsg);
      });
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailCtrl = TextEditingController();
    String? dialogError;
    bool dialogLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
              ),
              title: Text(
                l10n.loginForgotPassword,
                style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.loginForgotPasswordDesc,
                    style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.loginForgotPassword,
                      labelStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.mail_outline, color: isDark ? AppColors.textMuted : AppColors.textLight),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    l10n.settingsCancel,
                    style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textLight),
                  ),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty) {
                            setDialogState(() {
                              dialogError = l10n.loginEnterEmail;
                            });
                            return;
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(email)) {
                            setDialogState(() {
                              dialogError = l10n.loginInvalidEmail;
                            });
                            return;
                          }

                          setDialogState(() {
                            dialogLoading = true;
                            dialogError = null;
                          });

                          final resetError = await context
                              .read<AuthProvider>()
                              .sendPasswordReset(email);

                          if (resetError == null) {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            if (scaffoldMessengerKey.currentState != null) {
                              scaffoldMessengerKey.currentState!.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          l10n.errResetSuccess,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            setDialogState(() {
                              dialogLoading = false;
                              dialogError = FirebaseErrorHelper.getLocalizedError(context, resetError);
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: dialogLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(l10n.loginSend),
                ),
              ],
            );
          },
        );
      },
    );
    emailCtrl.dispose();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subtextColor = isDark ? AppColors.textMuted : AppColors.textLight;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    final noAccountText = l10n.loginNoAccount;
    final parts = noAccountText.split('?');
    final question = parts[0] + '?';
    final action = parts.length > 1 ? parts[1].trim() : 'Sign Up';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: AppTheme.getShadow(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.loginTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
                    style: TextStyle(color: subtextColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Username or Email field
                  TextField(
                    controller: _usernameCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: l10n.loginUsernameOrEmail,
                      labelStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.person_outline, color: subtextColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _pwdCtrl,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: l10n.loginPassword,
                      labelStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: subtextColor),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.loginForgotPasswordQ,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _doLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            l10n.loginButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        question,
                        style: TextStyle(color: subtextColor, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(
                          action,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
}
