import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Theme",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeManager().themeMode,
          builder: (context, mode, _) {
            return Column(
              children: [
                _themeOption(
                  context,
                  "Light Mode",
                  Icons.light_mode,
                  ThemeMode.light,
                  mode,
                  isDark,
                ),
                const SizedBox(height: 12),
                _themeOption(
                  context,
                  "Dark Mode",
                  Icons.dark_mode,
                  ThemeMode.dark,
                  mode,
                  isDark,
                ),
                const SizedBox(height: 12),
                _themeOption(
                  context,
                  "System Default",
                  Icons.settings_suggest,
                  ThemeMode.system,
                  mode,
                  isDark,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode themeMode,
    ThemeMode currentMode,
    bool isDark,
  ) {
    final isSelected = currentMode == themeMode;

    return GestureDetector(
      onTap: () => ThemeManager().setTheme(themeMode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isSelected ? AppColors.primary : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
