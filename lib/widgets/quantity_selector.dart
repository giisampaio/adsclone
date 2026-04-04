import 'package:adscloneia/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Preset counts: 1, 2, 3, 4, 5, 6, 8, 10, 15, 20.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const options = [1, 2, 3, 4, 5, 6, 8, 10, 15, 20];

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantidade de variações',
          style: GoogleFonts.dmSans(
            color: p.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((n) {
            final selected = n == value;
            return Tooltip(
              message: 'Número de variações a gerar',
              child: _QuantityChip(
                n: n,
                selected: selected,
                palette: p,
                onTap: () => onChanged(n),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuantityChip extends StatefulWidget {
  const _QuantityChip({
    required this.n,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final int n;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  State<_QuantityChip> createState() => _QuantityChipState();
}

class _QuantityChipState extends State<_QuantityChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final n = widget.n;
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          hoverColor: p.accent.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: selected ? p.heroGradient : null,
              color: selected
                  ? null
                  : _hover
                      ? Color.alphaBlend(
                          Colors.white.withValues(alpha: 0.06),
                          p.surface,
                        )
                      : p.surface,
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : p.muted.withValues(alpha: _hover ? 0.5 : 0.35),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: p.accent.withValues(alpha: 0.35),
                        blurRadius: _hover ? 16 : 12,
                        offset: Offset(0, _hover ? 6 : 4),
                      ),
                    ]
                  : _hover
                      ? [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
            ),
            child: Text(
              '$n',
              style: p.mono(
                fontSize: 16,
                weight: FontWeight.w700,
                color: selected ? p.onAccent : p.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
