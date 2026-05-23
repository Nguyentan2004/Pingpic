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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _doRegister() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameCtrl.text.trim();
    final fullName = _fullNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text;
    final confirmPassword = _confirmPwdCtrl.text;

    if (username.isEmpty || fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _error = l10n.registerFillAllFields;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _error = l10n.registerUsernameLength;
      });
      return;
    }

    if (username.contains(' ') || username.contains('@')) {
      setState(() {
        _error = l10n.registerUsernameInvalid;
      });
      return;
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      setState(() {
        _error = l10n.registerUsernameUnderscore;
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _error = l10n.registerEmailInvalid;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = l10n.registerPasswordLength;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = l10n.registerPasswordMismatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final errorMsg = await authProvider.register(
      username: username,
      email: email,
      fullName: fullName,
      password: password,
    );

    if (errorMsg == null) {
      if (!mounted) return;
      
      // Hiển thị thông báo thành công
      if (scaffoldMessengerKey.currentState != null) {
        scaffoldMessengerKey.currentState!.showSnackBar(
           SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.registerSuccess,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Chuyển về màn hình Login
      context.go('/login');
    } else {
      setState(() {
        _isLoading = false;
        _error = FirebaseErrorHelper.getLocalizedError(context, errorMsg);
      });
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
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

    final hasAccountText = l10n.registerHasAccount;
    final parts = hasAccountText.split('?');
    final question = parts[0] + '?';
    final action = parts.length > 1 ? parts[1].trim() : 'Sign In';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
                      Icons.person_add_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.registerTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.registerSubtitle,
                    style: TextStyle(color: subtextColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Username field
                  TextField(
                    controller: _usernameCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: l10n.registerUsername,
                      labelStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.alternate_email, color: subtextColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // FullName field
                  TextField(
                    controller: _fullNameCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: l10n.registerFullName,
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
                  
                  // Email field
                  TextField(
                    controller: _emailCtrl,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.registerEmail,
                      labelStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.mail_outline, color: subtextColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _pwdCtrl,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: l10n.registerPassword,
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
                  const SizedBox(height: 16),
                  
                  // Confirm Password field
                  TextField(
                    controller: _confirmPwdCtrl,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: l10n.localeName == 'vi' ? 'Xác nhận mật khẩu' : 'Confirm Password',
                      labelStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock_clock_outlined, color: subtextColor),
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
                  
                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _doRegister,
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
                            l10n.registerButton,
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
                        onPressed: () => context.go('/login'),
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
