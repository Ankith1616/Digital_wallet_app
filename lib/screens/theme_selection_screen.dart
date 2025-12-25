import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_manager.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Theme Settings",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeManager().themeMode,
        builder: (context, currentMode, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildThemeOption(
                context,
                "Light Mode",
                Icons.wb_sunny_outlined,
                ThemeMode.light,
                currentMode == ThemeMode.light,
              ),
              const SizedBox(height: 15),
              _buildThemeOption(
                context,
                "Dark Mode",
                Icons.dark_mode_outlined,
                ThemeMode.dark,
                currentMode == ThemeMode.dark,
              ),
              const SizedBox(height: 15),
              _buildThemeOption(
                context,
                "System Default",
                Icons.settings_system_daydream_outlined,
                ThemeMode.system,
                currentMode == ThemeMode.system,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ThemeManager().setTheme(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D44) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected
              ? Border.all(color: const Color(0xFF6C63FF), width: 2)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }
}
