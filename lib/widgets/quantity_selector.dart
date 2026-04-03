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
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(n),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: selected ? p.heroGradient : null,
                    color: selected ? null : p.surface,
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : p.muted.withValues(alpha: 0.35),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: p.accent.withValues(alpha: 0.35),
                              blurRadius: 12,
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
            );
          }).toList(),
        ),
      ],
    );
  }
}
