import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// Status colors: completed, generating, failed, pending.
abstract final class StatusBadgeColors {
  static const completed = Color(0xFF00E676);
  static const generating = Color(0xFF6C5CE7);
  static const failed = Color(0xFFFF4757);
  static const pending = Color(0xFFFFD93D);
}

enum _StatusKind { completed, generating, failed, pending }

_StatusKind _kindFor(String raw) {
  final s = raw.toLowerCase().trim();
  if (s == 'complete' || s == 'completed') return _StatusKind.completed;
  if (s == 'failed' || s == 'error') return _StatusKind.failed;
  if (s == 'pending') return _StatusKind.pending;
  if (s == 'processing' ||
      s == 'generating' ||
      s == 'analyzing' ||
      s == 'analyzed') {
    return _StatusKind.generating;
  }
  return _StatusKind.pending;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final kind = _kindFor(status);
    final label = _label(kind);
    final color = _color(kind);
    final bg = color.withValues(alpha: 0.18);

    Widget text = Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    );

    if (kind == _StatusKind.generating) {
      text = Shimmer.fromColors(
        baseColor: color.withValues(alpha: 0.5),
        highlightColor: color,
        period: const Duration(milliseconds: 1200),
        child: text,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: text,
    );
  }

  static String _label(_StatusKind k) {
    switch (k) {
      case _StatusKind.completed:
        return 'Concluído';
      case _StatusKind.generating:
        return 'Gerando';
      case _StatusKind.failed:
        return 'Falhou';
      case _StatusKind.pending:
        return 'Pendente';
    }
  }

  static Color _color(_StatusKind k) {
    switch (k) {
      case _StatusKind.completed:
        return StatusBadgeColors.completed;
      case _StatusKind.generating:
        return StatusBadgeColors.generating;
      case _StatusKind.failed:
        return StatusBadgeColors.failed;
      case _StatusKind.pending:
        return StatusBadgeColors.pending;
    }
  }
}
