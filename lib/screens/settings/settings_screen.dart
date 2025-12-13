import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scores = context.watch<ScoresProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, 'Preferences'),
          const SizedBox(height: 12),
          _buildSettingCard(
            context,
            isDark,
            children: [
              _buildSwitchTile(
                context,
                'Dark Mode',
                'Enable dark theme',
                Icons.dark_mode_rounded,
                settings.isDarkMode,
                (value) => settings.setDarkMode(value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                'Sound',
                'Enable game sounds',
                Icons.volume_up_rounded,
                settings.isSoundEnabled,
                (value) => settings.setSound(value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                'Vibration',
                'Enable haptic feedback',
                Icons.vibration_rounded,
                settings.isVibrationEnabled,
                (value) => settings.setVibration(value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Data'),
          const SizedBox(height: 12),
          _buildSettingCard(
            context,
            isDark,
            children: [
              _buildActionTile(
                context,
                'Reset High Scores',
                'Clear all saved scores',
                Icons.delete_outline_rounded,
                AppColors.error,
                () => _showResetConfirmation(context, scores),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'About'),
          const SizedBox(height: 12),
          _buildSettingCard(
            context,
            isDark,
            children: [
              _buildInfoTile(
                context,
                'App Version',
                '1.0.0',
                Icons.info_outline_rounded,
              ),
              const Divider(height: 1),
              _buildActionTile(
                context,
                'About OffGames',
                'Learn more about us',
                Icons.help_outline_rounded,
                AppColors.primary,
                () => Navigator.pushNamed(context, '/about'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, ScoresProvider scores) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset High Scores?'),
        content: const Text('This will permanently delete all your high scores. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              scores.resetAllScores();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All high scores have been reset'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
