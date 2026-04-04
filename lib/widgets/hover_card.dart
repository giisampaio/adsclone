import 'package:adscloneia/theme/app_palette.dart';
import 'package:flutter/material.dart';

const _hoverDuration = Duration(milliseconds: 260);
const _hoverCurve = Curves.easeOutCubic;

/// Card com hover: escala leve, sombra e borda accent ([MouseRegion] + [AnimatedContainer]).
class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: _hover ? 1.01 : 1.0,
        duration: _hoverDuration,
        curve: _hoverCurve,
        child: AnimatedContainer(
          duration: _hoverDuration,
          curve: _hoverCurve,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _hover
                  ? p.accent.withValues(alpha: 0.42)
                  : p.border.withValues(alpha: 0.85),
              width: 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.onTap != null
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius:
                        BorderRadius.circular(widget.borderRadius - 1),
                    hoverColor: p.accent.withValues(alpha: 0.06),
                    child: widget.child,
                  ),
                )
              : widget.child,
        ),
      ),
    );
  }
}
