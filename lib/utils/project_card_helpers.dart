/// Texto curto para cards de projeto (primeira direção ou fallback).
String generationCreativeBrief(Map<String, dynamic>? analysis) {
  if (analysis == null || analysis.isEmpty) {
    return 'Variações de cores';
  }
  final dirs = analysis['directions'];
  if (dirs is List && dirs.isNotEmpty) {
    final first = dirs.first;
    if (first is Map) {
      final text = (first['direction'] ?? first['title'] ?? '')
          .toString()
          .trim();
      if (text.isNotEmpty) {
        if (text.length > 52) return '${text.substring(0, 49)}…';
        return text;
      }
    }
  }
  return 'Variações de cores';
}

/// Data relativa em português (ex.: "há 2 horas").
String formatRelativeTimePt(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  var diff = now.difference(local);
  if (diff.isNegative) diff = Duration.zero;

  if (diff.inSeconds < 45) return 'agora';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? 'há 1 minuto' : 'há $m minutos';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? 'há 1 hora' : 'há $h horas';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? 'há 1 dia' : 'há $d dias';
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    return w == 1 ? 'há 1 semana' : 'há $w semanas';
  }
  if (diff.inDays < 365) {
    final mo = (diff.inDays / 30).floor().clamp(1, 11);
    return mo == 1 ? 'há 1 mês' : 'há $mo meses';
  }
  final y = (diff.inDays / 365).floor();
  return y == 1 ? 'há 1 ano' : 'há $y anos';
}
