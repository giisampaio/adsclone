import 'dart:async';

import 'package:adscloneia/theme/app_palette.dart';
import 'package:adscloneia/theme/sidebar_prefs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Larguras animadas da sidebar (web).
const double kSidebarWidthExpanded = 268;
const double kSidebarWidthCollapsed = 68;

/// Navigation rail estilo dashboard SaaS (web), com colapso e preferência persistida.
class SaaSSidebar extends StatefulWidget {
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
  State<SaaSSidebar> createState() => _SaaSSidebarState();
}

class _SaaSSidebarState extends State<SaaSSidebar> {
  bool _expanded = true;
  bool _prefsScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefsScheduled) return;
    _prefsScheduled = true;
    final w = MediaQuery.sizeOf(context).width;
    unawaited(SidebarPrefs.load().then((v) {
      if (!mounted) return;
      setState(() {
        _expanded = v ?? (w > 1024);
      });
    }));
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    unawaited(SidebarPrefs.save(_expanded));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: _expanded ? kSidebarWidthExpanded : kSidebarWidthCollapsed,
      decoration: BoxDecoration(
        color: p.sidebar,
        border: Border(
          right: BorderSide(color: p.sidebarBorder, width: 1),
        ),
      ),
      child: ClipRect(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (_expanded) ...[
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
                    ] else
                      Expanded(
                        child: Center(
                          child: Container(
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
                        ),
                      ),
                    Tooltip(
                      message: _expanded ? 'Recolher menu' : 'Expandir menu',
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _toggleExpanded,
                          borderRadius: BorderRadius.circular(10),
                          hoverColor: p.accent.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _expanded ? Icons.chevron_left_rounded : Icons.menu_rounded,
                              color: p.muted,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _expanded ? 24 : 16),
                if (_expanded)
                  Text(
                    'MENU',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: p.muted,
                    ),
                  ),
                if (_expanded) const SizedBox(height: 12),
                for (var i = 0; i < SaaSSidebar._destinations.length; i++)
                  _NavTile(
                    expanded: _expanded,
                    selected: widget.selectedIndex == i,
                    icon: widget.selectedIndex == i
                        ? SaaSSidebar._destinations[i].iconSelected
                        : SaaSSidebar._destinations[i].icon,
                    label: SaaSSidebar._destinations[i].label,
                    onTap: () => widget.onDestinationSelected(i),
                  ),
                const Spacer(),
                Divider(height: 1, color: p.sidebarBorder),
                const SizedBox(height: 12),
                if (_expanded)
                  Text(
                    'APARÊNCIA',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: p.muted,
                    ),
                  ),
                if (_expanded) const SizedBox(height: 10),
                if (_expanded)
                  _ThemeSegmented(
                    mode: widget.themeMode,
                    onChanged: widget.onThemeModeChanged,
                  )
                else
                  _ThemeCollapsed(
                    mode: widget.themeMode,
                    onChanged: widget.onThemeModeChanged,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.expanded,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool expanded;
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: widget.selected
            ? p.navSelected
            : _hover
                ? p.accent.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: p.accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: widget.expanded
                ? Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 22,
                        color: widget.selected ? p.accent : p.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: GoogleFonts.dmSans(
                            fontWeight:
                                widget.selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                            color: widget.selected ? p.text : p.muted,
                          ),
                        ),
                      ),
                      if (widget.selected)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accent,
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: widget.selected ? p.accent : p.muted,
                    ),
                  ),
          ),
        ),
      ),
      ),
    );

    if (widget.expanded) return tile;
    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 350),
      child: tile,
    );
  }
}

class _ThemeCollapsed extends StatelessWidget {
  const _ThemeCollapsed({
    required this.mode,
    required this.onChanged,
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Tooltip(
          message: 'Tema claro',
          child: _ThemeIconButton(
            icon: Icons.light_mode_outlined,
            selected: mode == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
        ),
        const SizedBox(height: 6),
        Tooltip(
          message: 'Tema escuro',
          child: _ThemeIconButton(
            icon: Icons.dark_mode_outlined,
            selected: mode == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ),
        const SizedBox(height: 6),
        Tooltip(
          message: 'Seguir sistema',
          child: _ThemeIconButton(
            icon: Icons.brightness_auto_rounded,
            selected: mode == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ),
      ],
    );
  }
}

class _ThemeIconButton extends StatelessWidget {
  const _ThemeIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: selected ? p.accent.withValues(alpha: 0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: p.accent.withValues(alpha: 0.12),
        child: SizedBox(
          width: 44,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: selected ? p.accent : p.muted,
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

class _ThemeChip extends StatefulWidget {
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
  State<_ThemeChip> createState() => _ThemeChipState();
}

class _ThemeChipState extends State<_ThemeChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
      color: widget.selected
          ? p.accent.withValues(alpha: 0.2)
          : _hover
              ? p.accent.withValues(alpha: 0.08)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: p.accent.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.selected ? p.accent : p.muted,
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected ? p.accent : p.muted,
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
