import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pingpic/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/image_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.fullName);
    _bioController = TextEditingController(text: auth.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await ImageService.pickFromGallery();
      if (result == null) return;
      if (!mounted) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final auth = context.read<AuthProvider>();
      final downloadUrl = await auth.uploadAvatar(result.bytes);
      final l10n = AppLocalizations.of(context)!;

      if (downloadUrl != null) {
        final success = await auth.updateProfile(
          fullName: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          avatarUrl: downloadUrl,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsAvatarUpdated),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsAvatarUpdateFailed),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsAvatarUploadFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsProfileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsProfileUpdateFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        title: Text(
          l10n.settingsLogoutConfirmTitle,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.settingsLogoutConfirmDesc,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textLight,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.settingsCancel,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : AppColors.textLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: Text(
              l10n.settingsLogout,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final avatarUrl = auth.avatarUrl;
    final fullName = auth.fullName ?? '';
    final username = auth.username ?? '';

    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subtextColor = isDark ? Colors.white70 : AppColors.textLight;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── SECTION 1 & 2: LANGUAGE & APPEARANCE ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(l10n.settingsLanguage, textColor),
                          const SizedBox(height: 8),
                          _buildLanguageSelector(themeProvider),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(l10n.settingsAppearance, textColor),
                          const SizedBox(height: 8),
                          _buildAppearanceSelector(themeProvider),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),



                // ── SECTION 4: ACCOUNT (PROFILE EDIT) ──
                _buildSectionHeader(l10n.settingsAccountInfo, textColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: AppTheme.getShadow(context),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Avatar Upload Widget
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.6),
                                    width: 3.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.grey[200],
                                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null || avatarUrl.isEmpty
                                      ? Text(
                                          fullName.isNotEmpty ? fullName[0] : '?',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              if (_isUploadingAvatar)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _pickAndUploadAvatar,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '@$username',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: l10n.settingsFullNameLabel,
                            labelStyle: TextStyle(color: subtextColor),
                            hintText: l10n.settingsFullNameHint,
                            hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Bio
                        TextFormField(
                          controller: _bioController,
                          style: TextStyle(color: textColor),
                          maxLines: 2,
                          maxLength: 150,
                          decoration: InputDecoration(
                            labelText: l10n.settingsBioLabel,
                            labelStyle: TextStyle(color: subtextColor),
                            hintText: l10n.settingsBioHint,
                            hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                            prefixIcon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── SECTION 5: LOGOUT & PREFERENCES BUTTONS ──
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: isDark ? 6 : 2,
                    shadowColor: isDark ? AppColors.primary.withOpacity(0.4) : Colors.black26,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.settingsSaveChanges,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmation(l10n),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  label: Text(
                    l10n.settingsLogout,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── APP VERSION ──
                Center(
                  child: Text(
                    l10n.settingsAppVersion,
                    style: TextStyle(
                      color: subtextColor.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: color.withOpacity(0.8),
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildLanguageSelector(ThemeProvider themeProvider) {
    final currentLang = themeProvider.locale.languageCode;

    return Row(
      children: [
        Expanded(
          child: _buildSelectorCard(
            label: 'English',
            isSelected: currentLang == 'en',
            onTap: () => themeProvider.changeLocale('en'),
            icon: Icons.language_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectorCard(
            label: 'Tiếng Việt',
            isSelected: currentLang == 'vi',
            onTap: () => themeProvider.changeLocale('vi'),
            icon: Icons.translate_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSelector(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    return Row(
      children: [
        Expanded(
          child: _buildSelectorCard(
            label: 'Dark Mode',
            isSelected: isDark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
            icon: Icons.dark_mode_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectorCard(
            label: 'Light Mode',
            isSelected: !isDark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
            icon: Icons.light_mode_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected && isDark
              ? AppTheme.neonGlowShadow(AppColors.primary)
              : AppTheme.softShadow(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textLight),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textDark),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
