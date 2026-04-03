import 'package:adscloneia/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Navigation rail estilo dashboard SaaS (web).
class SaaSSidebar extends StatelessWidget {
  const SaaSSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static const _destinations = <({IconData icon, IconData iconSelected, String label})>[
    (icon: Icons.home_outlined, iconSelected: Icons.home_rounded, label: 'Início'),
    (icon: Icons.add_photo_alternate_outlined, iconSelected: Icons.add_photo_alternate_rounded, label: 'Criar'),
    (icon: Icons.grid_view_outlined, iconSelected: Icons.grid_view_rounded, label: 'Galeria'),
    (icon: Icons.settings_outlined, iconSelected: Icons.settings_rounded, label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;

    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: p.sidebar,
        border: Border(
          right: BorderSide(color: p.sidebarBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [p.accent, p.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: p.accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'adscloneia',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: p.text,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Creative Studio',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: p.muted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'MENU',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _destinations.length; i++)
                _NavTile(
                  selected: selectedIndex == i,
                  icon: selectedIndex == i
                      ? _destinations[i].iconSelected
                      : _destinations[i].icon,
                  label: _destinations[i].label,
                  onTap: () => onDestinationSelected(i),
                ),
              const Spacer(),
              Divider(height: 1, color: p.sidebarBorder),
              const SizedBox(height: 12),
              Text(
                'APARÊNCIA',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 10),
              _ThemeSegmented(
                mode: themeMode,
                onChanged: onThemeModeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? p.navSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: p.accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? p.accent : p.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      color: selected ? p.text : p.muted,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSegmented extends StatelessWidget {
  const _ThemeSegmented({
    required this.mode,
    required this.onChanged,
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeChip(
              icon: Icons.light_mode_outlined,
              label: 'Claro',
              selected: mode == ThemeMode.light,
              onTap: () => onChanged(ThemeMode.light),
            ),
          ),
          Expanded(
            child: _ThemeChip(
              icon: Icons.dark_mode_outlined,
              label: 'Escuro',
              selected: mode == ThemeMode.dark,
              onTap: () => onChanged(ThemeMode.dark),
            ),
          ),
          Expanded(
            child: _ThemeChip(
              icon: Icons.brightness_auto_rounded,
              label: 'Auto',
              selected: mode == ThemeMode.system,
              onTap: () => onChanged(ThemeMode.system),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: selected ? p.accent.withValues(alpha: 0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? p.accent : p.muted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? p.accent : p.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
